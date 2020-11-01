
//
//  Computation.m
//  FunctionTest
//
//  Created by Gaige B. Paulsen on 4/4/10.
//  Copyright 2010 ClueTrust. All rights reserved.
//

#import "PyComputation.h"
#import "PyUtilities.h"
#import "PyGeometryModule.h"
#import <Python/datetime.h>
#import <CTUtils/CTUtils.h>
//#include <sys/types.h>
#include <sys/sysctl.h>

static NSLock *gPyLock=nil;
int PyComputationImportBlocker(const char *event, PyObject *args, void *userData);
int PyComputationLoggingAuditor(const char *event, PyObject *args, void *userData);

@implementation PyComputation

+(void) initialize
{
	gPyLock=[[NSLock alloc] init];
    // set the cache file location for Python to be inside of our application support folder
    
    NSURL *python_cache_path = [[CTFolderUtils urlToOurCacheDirectory] URLByAppendingPathComponent: @"Python"];
    [[NSFileManager defaultManager] createDirectoryAtURL: python_cache_path withIntermediateDirectories:YES attributes:nil error:nil];
    
    NSAssert(python_cache_path, @"Need a valid cache path");
    NSAssert(python_cache_path.isFileURL, @"Need a valid cache path");
    setenv( "PYTHONPYCACHEPREFIX", python_cache_path.fileSystemRepresentation, true);
}


- (BOOL)startInterpreter:(NSError**)errorPtr
{
	[gPyLock lock];
	
    Py_SetProgramName(L"Computation");
	Py_Initialize();
	if (!Py_IsInitialized()) {
		NSError *error = [NSError errorWithDomain:kComputationDomain code:kComputationError_cantInitialize userInfo:
			[NSDictionary dictionaryWithObjectsAndKeys:
				NSLocalizedString( @"Can't initialize python interpreter", @"Error"), NSLocalizedDescriptionKey,
				NSLocalizedString( @"Can't initialize python interpreter", @"Error"), NSLocalizedFailureReasonErrorKey,
				NSLocalizedString( @"Please contact ClueTrust with this error", @"Error"), NSLocalizedRecoverySuggestionErrorKey,
				nil,nil]];
		if (errorPtr)
			*errorPtr = error;

		[gPyLock unlock];
		return NO;
	}
	
	globals = PyDict_New();
	if (!globals) {
		NSError *error = [NSError errorWithDomain:kComputationDomain code:kComputationError_cantInitialize userInfo:
			[NSDictionary dictionaryWithObjectsAndKeys:
				NSLocalizedString( @"Can't initialize python interpreter: couldn't create global space", @"Error"), NSLocalizedDescriptionKey,
				NSLocalizedString( @"couldn't create global space", @"Error"), NSLocalizedFailureReasonErrorKey,
				NSLocalizedString( @"Please contact ClueTrust with this error", @"Error"), NSLocalizedRecoverySuggestionErrorKey,
				nil,nil]];
		if (errorPtr)
			*errorPtr = error;

		Py_Finalize();
		[gPyLock unlock];
		return NO;
	}
	
	// Install geometry library
	PyObject *geometryModule = [PyGeometryModule loadModule];
	if (!geometryModule) {
		NSError *error = [NSError errorWithDomain:kComputationDomain code:kComputationError_cantInitialize userInfo:
			[NSDictionary dictionaryWithObjectsAndKeys:
				NSLocalizedString( @"Can't initialize python interpreter: geometry failed to load", @"Error"), NSLocalizedDescriptionKey,
				NSLocalizedString( @"load geometry routines", @"Error"), NSLocalizedFailureReasonErrorKey,
				NSLocalizedString( @"Please contact ClueTrust with this error", @"Error"), NSLocalizedRecoverySuggestionErrorKey,
				nil,nil]];
		if (errorPtr)
			*errorPtr = error;

		Py_DECREF( globals); globals = NULL;
		Py_Finalize();
		[gPyLock unlock];
		return NO;
	}
	
	// install it into the location
	PyDict_SetItemString(globals, "geometry", geometryModule);	// install as geometry.x -- NOTE: THIS IS BORROWED,

	// Install built-in functions at builtin level
	PyDict_SetItemString(globals, "__builtins__", PyEval_GetBuiltins( ));// ref was borrowed
	
	// install math libraries at base level, so they can be referred to without math.x

    NSError *lowerError;
    NSArray *requiredLibraries = @[ @"math",@"string",@"re",@"datetime"];
    
    for ( NSString *libName in requiredLibraries) {
        PyObject *module = [self importPythonModule: libName error: &lowerError];
        if (!module) {
            NSError *error = [NSError errorWithDomain: kComputationDomain code:kComputationError_cantInitialize userInfo: @{
                           NSLocalizedDescriptionKey : NSLocalizedString( @"Can't initialize python interpreter: math library failed to load", @"Error"),
                    NSLocalizedFailureReasonErrorKey : lowerError.localizedFailureReason,
               NSLocalizedRecoverySuggestionErrorKey : lowerError.localizedRecoverySuggestion,
                                NSUnderlyingErrorKey : lowerError
                              }];
            if (errorPtr)
                *errorPtr = error;
            
            Py_DECREF( globals); globals = NULL;
            Py_Finalize();
            [gPyLock unlock];
            return NO;
        }
        
        PyDict_Merge(globals, PyModule_GetDict(module), 0);	
        Py_DECREF( module);
    }
    
    // special inits
    PyDateTime_IMPORT;
    
    // block imports from here out
    if (PySys_AddAuditHook(PyComputationImportBlocker, (__bridge void *)(self))) {
        NSError *error = [NSError errorWithDomain:kComputationDomain code:kComputationError_cantInitialize userInfo:
            [NSDictionary dictionaryWithObjectsAndKeys:
                NSLocalizedString( @"Can't install audit hook", @"Error"), NSLocalizedDescriptionKey,
                NSLocalizedString( @"Can't install audit hook", @"Error"), NSLocalizedFailureReasonErrorKey,
                NSLocalizedString( @"Please contact ClueTrust with this error", @"Error"), NSLocalizedRecoverySuggestionErrorKey,
                nil,nil]];
        if (errorPtr)
            *errorPtr = error;

        Py_Finalize();
        [gPyLock unlock];
        return NO;
    }

	return YES;
}

- (PyObject*)importPythonModule:(NSString*)moduleName error:(NSError**)errorPtr
{
    const char *cModuleName = [moduleName UTF8String];
    if (!cModuleName) {
        NSError *error = [NSError errorWithDomain: kComputationDomain code:kComputationError_cantInitialize userInfo: @{
                       NSLocalizedDescriptionKey : NSLocalizedString( @"Can't initialize library", @"Error"),
                NSLocalizedFailureReasonErrorKey : NSLocalizedString(@"Library with empty name",@"Error"),
           NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString( @"Please contact ClueTrust with this error", @"Error")
                          }];
        if (errorPtr)
            *errorPtr = error;
        return nil;
    }
    
    PyObject *module = PyImport_ImportModule( cModuleName);
	if (!module) {
        NSError *error = [NSError errorWithDomain: kComputationDomain code:kComputationError_cantInitialize userInfo: @{
                       NSLocalizedDescriptionKey : NSLocalizedString( @"Can't initialize library", @"Error"),
                NSLocalizedFailureReasonErrorKey : [NSString stringWithFormat: NSLocalizedString( @"Library %@ failed to load",@"Error"), moduleName],
           NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString( @"Please contact ClueTrust with this error", @"Error")
                          }];
        if (errorPtr)
            *errorPtr = error;
        return nil;
	}
    return module;
}

- (NSError*)errorFromPythonException: (PyObject *)exception
{
	PyObject *pType, *pValue, *pTraceback;
	PyErr_Fetch( &pType, &pValue, &pTraceback);
	
	if (pType) {
		Py_DECREF(pType);
	}
	if (pTraceback) {
		Py_DECREF(pTraceback);
	}

    NSString *pythonReason=@"";
    // load up the python explanation, if one exists, and release
    if (pValue) {
        if (PyUnicode_Check(pValue)) {
            pythonReason = [NSString stringWithCString:PyUnicode_AsUTF8(pValue) encoding: NSUTF8StringEncoding];
        }
        Py_DECREF(pValue);
    }
    
    // set the defaults
	NSError *baseError=nil;
	NSString *reason =  NSLocalizedString(@"Interpreter failure", @"Error");
	NSString *shortReason = reason;
	NSString *suggestion= NSLocalizedString(@"Check formula syntax", @"Error");
	NSUInteger errorCode = kComputationError_interpreterException;
	NSMutableDictionary *errorDictionary = [NSMutableDictionary dictionaryWithObjectsAndKeys:
			reason, NSLocalizedDescriptionKey,
			shortReason, NSLocalizedFailureReasonErrorKey,
			suggestion, NSLocalizedRecoverySuggestionErrorKey,
			nil,nil
	];
	

	if (PyErr_GivenExceptionMatches( exception, PyExc_SyntaxError)) {
		errorCode = kComputationError_syntaxError;
		reason = [NSString stringWithFormat: NSLocalizedString(@"Syntax error: %@", @"Error"), pythonReason];
		shortReason = NSLocalizedString(@"Syntax Error", @"Error");
		suggestion=NSLocalizedString(@"Correct the syntax error.",@"Error");
		
	} else if (PyErr_GivenExceptionMatches( exception, PyExc_ValueError)) {
		errorCode= kComputationError_arithmaticError;
		reason = [NSString stringWithFormat: NSLocalizedString(@"Incorrect Value: %@", @"Error"), pythonReason];
		shortReason = NSLocalizedString(@"Function argument incorrect", @"Error");
		suggestion=NSLocalizedString(@"Check arguments for the function.",@"Error");
		
	} else if (PyErr_GivenExceptionMatches( exception, PyExc_IndexError)) {
		errorCode= kComputationError_arithmaticError;
		reason = [NSString stringWithFormat: NSLocalizedString(@"Incorrect Index: %@", @"Error"), pythonReason];
		shortReason = NSLocalizedString(@"Wrong Index", @"Error");
		suggestion=NSLocalizedString(@"Check arguments for the function.",@"Error");
		
	} else if (PyErr_GivenExceptionMatches( exception, PyExc_ArithmeticError)) {
		errorCode= kComputationError_arithmaticError;
		reason = [NSString stringWithFormat: NSLocalizedString(@"Arithmatic error: %@", @"Error"), pythonReason];
		shortReason = NSLocalizedString(@"Arithmatic Error", @"Error");
		suggestion=NSLocalizedString(@"Values may be too large or small.  No action need be taken, but the result will be empty",@"Error");
		
	} else if (PyErr_GivenExceptionMatches( exception, PyExc_AttributeError)) {
		// try to figure out what the name was, sure would be easier if it weren't a DAMNED STRING!
		NSScanner *scanner = [NSScanner scannerWithString: pythonReason];
		NSString *symbol = nil;
		if (scanner) {
			// skip first attribute stuff
			// AttributeError: type object 'list' has no attribute 'doc' example
			[scanner scanUpToString: @"'" intoString:nil];
			[scanner scanString: @"'" intoString:nil];
			[scanner scanUpToString: @"'" intoString:nil];
			[scanner scanString: @"'" intoString:nil];
			// now we're ready to get the attribute name
			if ([scanner scanUpToString:@"'" intoString:nil]) {
				if ([scanner scanString:@"'" intoString:nil]) {
					if ([scanner scanUpToString: @"'" intoString: &symbol]) {
						[errorDictionary setObject: symbol forKey: kComputationError_unknownSymbolErrorKey];
						pythonReason = symbol;	// so we pick it up later
					}
				}
			}
		}
		
		errorCode = kComputationError_unknownAttribute;
		reason = [NSString stringWithFormat: NSLocalizedString(@"Referenced attribute not found: %@", @"Error"), pythonReason];
		shortReason = NSLocalizedString(@"No Such Attribute Error", @"Error");
		suggestion=NSLocalizedString(@"Symbol may not exist for this record",@"Error");
	} else if (PyErr_GivenExceptionMatches( exception, PyExc_NameError)) {
		// try to figure out what the name was, sure would be easier if it weren't a DAMNED STRING!
		NSScanner *scanner = [NSScanner scannerWithString: pythonReason];
		NSString *symbol = nil;
		if (scanner) {
			if ([scanner scanUpToString:@"'" intoString:nil]) {
				if ([scanner scanString:@"'" intoString:nil]) {
					if ([scanner scanUpToString: @"'" intoString: &symbol]) {
						[errorDictionary setObject: symbol forKey: kComputationError_unknownSymbolErrorKey];
						pythonReason = symbol;	// so we pick it up later
					}
				}
			}
		}
		
		errorCode = kComputationError_unknownSymbol;
		reason = [NSString stringWithFormat: NSLocalizedString(@"Symbol not found error: %@", @"Error"), pythonReason];
		shortReason = NSLocalizedString(@"No Such Symbol Error", @"Error");
		suggestion=NSLocalizedString(@"Symbol may not exist for this record",@"Error");
	} else if ([PyGeometryModule interpretException:exception object:pValue intoError: &baseError]) {
		// coerce the information from the geometry error into our error
		[errorDictionary setObject: baseError forKey: NSUnderlyingErrorKey];
		// NOTE: we didn't have to do this, but we're going to just send the original error back
		// we could actually process this further and add useful information to it
		return baseError;
	} else {
		// we don't know in particular
		// defaults work, except we'll add the message if it's there
		reason = [NSString stringWithFormat: NSLocalizedString( @"Interpreter failure: %@", @"Error"), pythonReason];
	}
	// after we've looked at it
	[errorDictionary setObject: reason forKey: NSLocalizedDescriptionKey];
	[errorDictionary setObject: shortReason forKey: NSLocalizedFailureReasonErrorKey];
	[errorDictionary setObject: suggestion forKey: NSLocalizedRecoverySuggestionErrorKey];
	
	NSError *error = [NSError errorWithDomain:kComputationDomain code:errorCode userInfo: errorDictionary];

	return error;
}

- (void)stopInterpreter
{
	if (!Py_IsInitialized())
		return;
		
	if (globals) {
		Py_DECREF( globals);
		globals = NULL;
	}
	if (code) {
		Py_DECREF( code);
		code = NULL;
	}
	
	[PyGeometryModule unloadModule];
	Py_Finalize();
	[gPyLock unlock];
}

- (PyObject*)compileCode:(NSError**)errorPtr
{
	PyObject *newCode;
	if (!Py_IsInitialized()) {
		NSError *error = [NSError errorWithDomain:kComputationDomain code:kComputationError_cantInitialize userInfo:
			[NSDictionary dictionaryWithObjectsAndKeys:
				NSLocalizedString( @"Can't compile code: no running interpeter", @"Error"), NSLocalizedDescriptionKey,
				NSLocalizedString( @"CompileCode called w/o interp", @"Error"), NSLocalizedFailureReasonErrorKey,
				NSLocalizedString( @"Please contact ClueTrust with this error", @"Error"), NSLocalizedRecoverySuggestionErrorKey,
				nil,nil]];
		if (errorPtr)
			*errorPtr = error;
		return NULL;
	}
	
	NSAssert(Py_IsInitialized(), @"Python should be initialized");
//	NSAssert(formula, @"Should have valid formula");

	if (!formula) {
		NSError *error = [NSError errorWithDomain:kComputationDomain code:kComputationError_noFormula userInfo:
			[NSDictionary dictionaryWithObjectsAndKeys:
				NSLocalizedString( @"Can't compile expression: No formula to interpret", @"Error"), NSLocalizedDescriptionKey,
				NSLocalizedString( @"No formula to interpret", @"Error"), NSLocalizedFailureReasonErrorKey,
				NSLocalizedString( @"Please contact ClueTrust with this error", @"Error"), NSLocalizedRecoverySuggestionErrorKey,
				nil,nil]];
		if (errorPtr)
			*errorPtr = error;
		return NULL;
	}
	
	// compile what we're about to evaluate
	newCode =Py_CompileString( [formula cStringUsingEncoding: NSUTF8StringEncoding], "input", Py_eval_input);
	if (!newCode) {
		PyObject *exception = PyErr_Occurred();
		NSError *error = [self errorFromPythonException: exception];
		if (errorPtr)
			*errorPtr = error;

		return NULL;
	}
	
	// NOTE: this is built so that we can pull out this code and make it deal with the eval code being called separately.
	return newCode;
}

- (id)valueWithPythonResult:(PyObject*)result error:(NSError *__autoreleasing *)errorPtr
{
    
    if (PyUnicode_Check(result))
        return [NSString stringWithCString: PyUnicode_AsUTF8( result) encoding: NSUTF8StringEncoding];
    else if (PyLong_Check(result))
        return  [NSNumber numberWithLong: PyLong_AsLong(result)];
    else if (PyFloat_Check(result))
        return  [NSNumber numberWithDouble: PyFloat_AsDouble(result)];
    else if (PyDate_Check(result)) {
        // Convert the date to the date field, or string if necessary
        NSDateComponents *components = [[NSDateComponents alloc] init];
        components.day = PyDateTime_GET_DAY( result);
        components.month=PyDateTime_GET_MONTH(result);
        components.year=PyDateTime_GET_YEAR(result);
        return  [[NSCalendar currentCalendar] dateFromComponents: components];
    } else {
        NSString *reason;
        NSString *typeName=@"undetermined";
        
        const char *cTypeName = result->ob_type->tp_name;
        if (cTypeName)
            typeName=[NSString stringWithCString: cTypeName encoding: NSASCIIStringEncoding];
        
        reason = [NSString stringWithFormat:NSLocalizedString( @"Evaluation resulted in %@", @"Error"), typeName];
        NSError *error = [NSError errorWithDomain:kComputationDomain code:kComputationError_unknownType userInfo:
                          [NSDictionary dictionaryWithObjectsAndKeys:
                           reason, NSLocalizedFailureReasonErrorKey,
                           NSLocalizedString( @"Unexpected result type", @"Error"), NSLocalizedDescriptionKey,
                           NSLocalizedString( @"Check your syntax", @"Error"), NSLocalizedRecoverySuggestionErrorKey,
                           typeName, kComputationError_unknownSymbolErrorKey,
                nil,nil]];
        if (errorPtr)
            *errorPtr = error;
        return nil;
    }
}

- (id) calculateForInfo:(NSDictionary*)symbolTable withError:(NSError**)errorPtr
{
	if (!Py_IsInitialized()) {
		NSError *error = [NSError errorWithDomain:kComputationDomain code:kComputationError_cantInitialize userInfo:
			[NSDictionary dictionaryWithObjectsAndKeys:
				NSLocalizedString( @"Can't compile code: no running interpeter", @"Error"), NSLocalizedDescriptionKey,
				NSLocalizedString( @"CompileCode called w/o interp", @"Error"), NSLocalizedFailureReasonErrorKey,
				NSLocalizedString( @"Please contact ClueTrust with this error", @"Error"), NSLocalizedRecoverySuggestionErrorKey,
				nil,nil]];
		if (errorPtr)
			*errorPtr = error;
		return nil;
	}

	PyObject *locals=NULL;

	// compile what we're about to evaluate
	if (!code) {
		NSError *error;
		code = [self compileCode:&error];
		if (!code) {
			if (errorPtr)
				*errorPtr = error;
			NSLog( @"Error compiling: %@", error);
			//CTTelemetry
			return nil;
		}
	}
	
	locals = [symbolTable pyDict];
	if (!locals) {
		locals = PyDict_New();	// create new locals
	}

	PyObject* result = PyEval_EvalCode( code, globals, locals);
	PyObject *exception = PyErr_Occurred();

	Py_DECREF(locals);
	
	if (exception) {
		NSError *error = [self errorFromPythonException: exception];
		if (errorPtr)
			*errorPtr = error;
		return nil;
	}
	
	if (!result) {
		NSError *error = [NSError errorWithDomain:kComputationDomain code:kComputationError_emptyResult userInfo:
			[NSDictionary dictionaryWithObjectsAndKeys:
				NSLocalizedString( @"Can't evaluate expression: Empty Result", @"Error"), NSLocalizedFailureReasonErrorKey,
				NSLocalizedString( @"Empty result", @"Error"), NSLocalizedDescriptionKey,
				NSLocalizedString( @"Check your syntax", @"Error"), NSLocalizedRecoverySuggestionErrorKey,
				nil,nil]];
		if (errorPtr)
			*errorPtr = error;
		return nil;
	}

    return [self valueWithPythonResult:result error:errorPtr];
}

- (NSArray*)gatherPythonFunctions:(PyObject*)dict withPrefix:(NSString*)prefix
{
	// get all the functions and modules available with this dictionary
	PyObject *key, *value;
	Py_ssize_t pos = 0;

	NSMutableArray *array=[NSMutableArray array];
	
	while (PyDict_Next(dict, &pos, &key, &value)) {
		/* do something interesting with the values... */
		if (PyUnicode_Check( key)) {
			[array addObject: [NSString stringWithFormat: @"%@.%s",prefix, PyUnicode_AsUTF8(key)]];
		} else {
			NSLog(@"Surprising type");
		}
		if (PyModule_Check(value)) {
//			NSLog(@"descending module",[NSString stringWithFormat: @"%@.%s",prefix, PyString_AsString(key)]);
			NSArray *descendents= 
				[self gatherPythonFunctions: PyModule_GetDict( value) withPrefix: 
						[NSString stringWithFormat: @"%@.%s",prefix, PyUnicode_AsUTF8(key)]];
			[array addObjectsFromArray: descendents];
		} else if (PyDict_Check(value)) {
//			NSLog(@"descending dictionary",[NSString stringWithFormat: @"%@.%s",prefix, PyString_AsString(key)]);
			NSArray *descendents= 
				[self gatherPythonFunctions: value withPrefix: 
						[NSString stringWithFormat: @"%@.%s",prefix, PyUnicode_AsUTF8(key)]];
			[array addObjectsFromArray: descendents];
		}
	}	
	return array;
}


- (void)setFormula:(NSString *)newFormula
{
@synchronized(self) {
	if (newFormula == formula)
		return;

	if (code) {
		Py_DECREF(code);
		code=NULL;
	}
	
	formula = newFormula;
}
}

-(NSString *)formula
{
    NSString *priorFormula=nil;
@synchronized(self) {
    priorFormula=formula;
}
    return priorFormula;
}

- (void)setLibraryValue:(id)value forKey:(NSString*)key
{
	[PyGeometryModule setLibraryValue: value forKey: key];
}

- (int) auditEvent:(const char*)event args:(PyObject*)args
{
    if (!PyTuple_Check(args)) {
        NSLog(@"auditEvent:args: has non-PyTyple arg");
        NSLog(@"PyComputation: %s %p", event, args);
        return 0;
    }
    
    NSLog(@"auditEvent: %s", event);
    Py_ssize_t tuple_count = PyTuple_Size(args);
    for (Py_ssize_t i=0; i< tuple_count; i++) {
        PyObject *tuple_object = PyTuple_GetItem(args, i);
        if (!tuple_object)
            break;
        Py_INCREF(tuple_object);
        if (PyUnicode_Check(tuple_object)) {
            NSString *pyString = [NSString stringWithCString:PyUnicode_AsUTF8(tuple_object) encoding: NSUTF8StringEncoding];
            NSLog(@"  %@", pyString);
        } else {
            NSLog(@"  Unknown Arg: %p", tuple_object);
        }
        Py_DECREF(tuple_object);
    }
    return 0;
}

/// Block import events from executing by throwing an exception during the audit phase.
///
/// @param event string name of the event
/// @param args arguments
- (int) blockImportEvent:(const char*)event args:(PyObject*)args
{
    if (strcmp(event,"import"))
        return 0;
    
    Py_ssize_t tuple_count = PyTuple_Size(args);
    if (tuple_count>0) {
        PyObject *tuple_object = PyTuple_GetItem(args, 0);
        if (tuple_object) {
            Py_INCREF(tuple_object);
            if (PyUnicode_Check(tuple_object)) {
                NSString *pyString = [NSString stringWithCString:PyUnicode_AsUTF8(tuple_object) encoding: NSUTF8StringEncoding];
                NSLog(@"Blocking python import of %@", pyString);
            } else {
                NSLog(@"Blocking python import with Unknown Arg: %p", tuple_object);
            }
            Py_DECREF(tuple_object);
        }
    }
    PyErr_SetString( PyExc_Exception, "Import not allowed");
    return -1;
}

@synthesize formula;
@end

int PyComputationLoggingAuditor(const char *event, PyObject *args, void *userData)
{
    PyComputation *computation = (__bridge PyComputation *)userData;
    return [computation auditEvent: event args: args];
}

int PyComputationImportBlocker(const char *event, PyObject *args, void *userData)
{
    PyComputation *computation = (__bridge PyComputation *)userData;
    return [computation blockImportEvent: event args: args];
}
