//
//  PyUtilities.h
//  MapClueCD
//
//  Created by Gaige B. Paulsen on 4/6/10.
//  Copyright 2010 ClueTrust. See accompanying LICENSE document.
//

#import <Cocoa/Cocoa.h>
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wquoted-include-in-framework-header"
#import <Python/Python.h>
#pragma GCC diagnostic pop

typedef enum PyUtilities_dictFlags {
	kPyUtilities_dictFlags_discreteNumberTypes = 0x01
} PyUtilities_dictFlags;

@interface NSString (PyUtilities)
- (PyObject*)pyString;
@end
@interface NSDictionary (PyUtilities)
- (PyObject*)pyDictWithFlags:(PyUtilities_dictFlags) flags;
- (PyObject*)pyDict;
@end
