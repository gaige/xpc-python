//
//  Computation.h
//  FunctionTest
//
//  Created by Gaige B. Paulsen on 4/4/10.
//  Copyright 2010 ClueTrust. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Python/Python.h>

extern NSString *kComputationDomain;
extern NSString *kComputationError_unknownSymbolErrorKey;

enum {
	kComputationError_cantInitialize=1,
	kComputationError_emptyResult=2,
	kComputationError_syntaxError=3,
	kComputationError_noFormula=4,
	kComputationError_unknownSymbol=5,
	kComputationError_arithmaticError=6,
	kComputationError_interpreterException=7,
	kComputationError_unknownType=8,
	kComputationError_unknownAttribute=9
};



@interface PyComputation : NSObject {
	NSString *formula;
	PyObject* globals;
	PyObject *code;
}

- (id) calculateForInfo:(NSDictionary*)symbolTable withError:(NSError**)errorPtr;
- (NSArray*)gatherPythonFunctions:(PyObject*)dict withPrefix:(NSString*)prefix;
- (PyObject*)compileCode:(NSError**)errorPtr;
- (BOOL)startInterpreter:(NSError**)errorPtr;
- (void)stopInterpreter;
- (void)setLibraryValue:(id)value forKey:(NSString*)key;
- (NSError*)errorFromPythonException: (PyObject *)exception;
- (PyObject*)importPythonModule:(NSString*)moduleName error:(NSError**)errorPtr;

@property(strong) NSString *formula;
@end
