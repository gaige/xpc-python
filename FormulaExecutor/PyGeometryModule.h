//
//  PyGeometryModule.h
//  MapClueCD
//
//  Created by Gaige B. Paulsen on 4/6/10.
//  Copyright 2010 ClueTrust. See accompanying LICENSE document.
//

#import <Cocoa/Cocoa.h>
#import "PyComputation.h"
#import <Python/Python.h>

extern NSString *kPyGeometryModuleDomain;

enum {
	kPyGeometryError_noGeometry=1,
	kPyGeometryError_wrongKind=2,
	kPyGeometryError_otherError
};

@interface PyGeometryModule : NSObject {

}
+ (void)setLibraryValue:(id)value forKey:(NSString*)key;
+ (PyObject*)loadModule;
+ (void) unloadModule;
+ (char *)cModuleName;
+ (char *)cDocString;
+ (void)clearLibraryValues;
+ (BOOL)interpretException:(PyObject*)exception object: (PyObject*)exceptionObject intoError:(NSError**)errorPtr;
@end
