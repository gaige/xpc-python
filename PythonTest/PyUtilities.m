//
//  PyUtilities.m
//  MapClueCD
//
//  Created by Gaige B. Paulsen on 4/6/10.
//  Copyright 2010 ClueTrust. All rights reserved.
//

#import "PyUtilities.h"
#import <Python/datetime.h>

@implementation NSString (PyUtilities)

- (PyObject *)pyString
{
	return PyUnicode_FromString( [self cStringUsingEncoding: NSUTF8StringEncoding]);
}

@end


@implementation NSDictionary (PyUtilities)

- (PyObject*)pyDictWithFlags:(PyUtilities_dictFlags) flags
{
    PyDateTime_IMPORT;
    
	__block PyObject *newDict = PyDict_New();
	[self enumerateKeysAndObjectsWithOptions: 0 usingBlock: ^(id key, id obj, BOOL *stop) {
		PyObject *newObject=NULL;
		if ([obj isKindOfClass: [NSValue class]]) {
			// NSNumber and other value types here
			const char *type = [obj objCType];
			
			if (flags & kPyUtilities_dictFlags_discreteNumberTypes) {
				if (!strcmp(type, @encode(int)))
					PyDict_SetItem( newDict, [key pyString], newObject=PyLong_FromLong( [obj longValue]));
				else if (!strcmp(type, @encode(short)))
					PyDict_SetItem( newDict, [key pyString], newObject=PyLong_FromLong( [obj longValue]));
				else if (!strcmp(type, @encode(long)))
					PyDict_SetItem( newDict, [key pyString], newObject=PyLong_FromLong( [obj longValue]));
				else if (!strcmp(type, @encode(float)))
					PyDict_SetItem( newDict, [key pyString], newObject=PyFloat_FromDouble([obj doubleValue]));
				else if (!strcmp(type, @encode(unsigned int)))
					PyDict_SetItem( newDict, [key pyString], newObject=PyLong_FromLong( [obj longValue]));
				else if (!strcmp(type, @encode(double)))
					PyDict_SetItem( newDict, [key pyString], newObject=PyFloat_FromDouble([obj doubleValue]));
			} else {
				if ([obj isKindOfClass: [NSNumber class]])
					PyDict_SetItem( newDict, [key pyString], newObject=PyFloat_FromDouble([obj doubleValue]));
			}
		} else if ([obj isKindOfClass: [NSDate class]]) {
            NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitYear | NSCalendarUnitMonth |  NSCalendarUnitDay fromDate: obj];
            
            PyDict_SetItem( newDict, [key pyString], newObject=PyDate_FromDate( (int)components.year,(int)components.month, (int)components.day));
        } else {
            // everything else falls through to string
			PyDict_SetItem( newDict, [key pyString], newObject= [[obj description] pyString]);
		}
		if (newObject) {
			Py_DECREF(newObject);	// this should have been retained elsewhere
		}
		}];
	
	return newDict;
}

- (PyObject*)pyDict
{
	return [self pyDictWithFlags: 0];
}


@end
