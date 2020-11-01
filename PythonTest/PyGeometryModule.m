//
//  PyGeometryModule.m
//  MapClueCD
//
//  Created by Gaige B. Paulsen on 4/6/10.
//  Copyright 2010 ClueTrust. All rights reserved.
//

#import "PyGeometryModule.h"
#import "MapGeometryExternalProtocol.h"

static NSMutableDictionary *libraryValues=NULL;
static PyObject *GeometryError=NULL;
static BOOL isLoaded=NO;

#define kPyGeometryModuleName  "geometry"
#define kPyGeometryModuleDescription "Geometry Routines for Cartographica"

#pragma mark Python Declarations
PyObject *geometry_point_getAttr(PyObject *myself, PyObject *name);
int geometry_point_setAttr(PyObject *myself, PyObject *name, PyObject *newValue);
PyObject *geometry_rect_getAttr(PyObject *myself, PyObject *pyName);
int geometry_rect_setAttr(PyObject *myself, PyObject *name, PyObject *newValue);


PyObject *geometry_length( PyObject *self, PyObject *args);
PyObject *geometry_centroid( PyObject *self, PyObject *args);
PyObject *geometry_midpoint( PyObject *self, PyObject *args);
PyObject *geometry_area( PyObject *self, PyObject *args);
PyObject *geometry_bbox( PyObject *self, PyObject *args);
PyObject *geometry_pointcount( PyObject *self, PyObject *args);
PyObject *geometry_partcount( PyObject *self, PyObject *args);

static PyMethodDef geometryMethods[] = {
	{ "length", geometry_length, METH_VARARGS, "returns the length of the geometry"},
	{ "centroid", geometry_centroid, METH_VARARGS, "returns centroid as a point object"},
	{ "area", geometry_area, METH_VARARGS, "returns area of the geometry"},
	{ "midpoint", geometry_midpoint, METH_VARARGS, "returns midpoint as a point object"},
	{ "bbox", geometry_bbox, METH_VARARGS, "returns bounding box as a rect object"},
	{ "pointcount", geometry_pointcount, METH_VARARGS, "returns the point count as an integer"},
	{ "partcount", geometry_partcount, METH_VARARGS, "returns the part count as an integer"},
	{NULL, NULL, 0, NULL}
};

typedef struct {
	PyObject_HEAD
	double x,y,height,width;
} PyGeometryRectObject;

static PyTypeObject PyGeometryRectObjectType = {
	PyVarObject_HEAD_INIT(NULL, 0)
	.tp_name = "geometry.rect",
	.tp_basicsize = sizeof(PyGeometryRectObject),
	.tp_getattro = geometry_rect_getAttr,
	.tp_setattro = geometry_rect_setAttr,
	.tp_flags = Py_TPFLAGS_DEFAULT,
	.tp_doc = "Geometric rectangle type.",
};


typedef struct {
	PyObject_HEAD
	double x,y,z,m;
	NSUInteger identifier;
} PyGeometryPointObject;

static PyTypeObject PyGeometryPointObjectType = {
	PyVarObject_HEAD_INIT(NULL, 0)
	.tp_name = "geometry.point",
	.tp_basicsize = sizeof(PyGeometryPointObject),
	.tp_getattro = geometry_point_getAttr,
	.tp_setattro = geometry_point_setAttr,
	.tp_flags = Py_TPFLAGS_DEFAULT,
	.tp_doc = "Geometric point type.",
};



@implementation PyGeometryModule
+ (void)setLibraryValue:(id)value forKey:(NSString*)key
{
	if (libraryValues)
		[libraryValues setObject: value forKey: key];
	else {
		libraryValues = [NSMutableDictionary dictionaryWithObject: value forKey: key];
	}

}

+ (void)clearLibraryValues
{
	[libraryValues removeAllObjects];
}

#if PY_MAJOR_VERSION >= 3
    static struct PyModuleDef moduledef = {
        PyModuleDef_HEAD_INIT,
        kPyGeometryModuleName,     /* m_name */
        kPyGeometryModuleDescription,  /* m_doc */
        -1,                  /* m_size */
        geometryMethods,    /* m_methods */
        NULL,                /* m_reload */
        NULL,                /* m_traverse */
        NULL,                /* m_clear */
        NULL,                /* m_free */
    };
#endif

    
+ (PyObject*)loadModule
{
    PyObject *module = PyModule_Create(&moduledef);
	if (!module)
		return NULL;
	
	GeometryError = PyErr_NewException( "geometry.error",  NULL, NULL);
	Py_INCREF( GeometryError);
	PyModule_AddObject( module, "error", GeometryError);
	
	// now add our point type
	PyGeometryPointObjectType.tp_new = PyType_GenericNew;
	if (PyType_Ready(&PyGeometryPointObjectType) < 0)
		return NULL;

	Py_INCREF(&PyGeometryPointObjectType);
	PyModule_AddObject(module, "point", (PyObject *)&PyGeometryPointObjectType);

	// now add our rect type
	PyGeometryRectObjectType.tp_new = PyType_GenericNew;
	if (PyType_Ready(&PyGeometryRectObjectType) < 0)
		return NULL;

	Py_INCREF(&PyGeometryRectObjectType);
	PyModule_AddObject(module, "rect", (PyObject *)&PyGeometryRectObjectType);
	
	isLoaded = YES;
	return module;
}

+ (void) unloadModule
{
	isLoaded = NO;

	if (GeometryError) {
		Py_DECREF( GeometryError);
		GeometryError = NULL;
	}
//	Py_DECREF(&PyGeometryPointObjectType);	-- NOTE: doing this in unload causes one of the finalizes to fail
	libraryValues = nil;
}


+ (char *)cModuleName
{
    return kPyGeometryModuleName;
}

+ (char *)cDocString
{
    return kPyGeometryModuleDescription;
}


+ (BOOL)interpretException:(PyObject*)exception object: (PyObject*)exceptionObject intoError:(NSError**)errorPtr
{
	NSAssert( errorPtr, @"need an error pointer");
	if (!errorPtr)
		return NO;	// since we can't give feedback, we didn't interpret it
	if (!PyErr_GivenExceptionMatches( exception, GeometryError))
		return NO;
	
	NSInteger code = kPyGeometryError_noGeometry;
	if (PyNumber_Check( exceptionObject))
		code = PyLong_AsLong( exceptionObject);
		
	NSMutableDictionary *info = [NSMutableDictionary  dictionary];
	
	switch (code) {
		case kPyGeometryError_wrongKind:
			[info setObject: NSLocalizedString( @"Wrong geometry for this function", @"Error")
				forKey: NSLocalizedFailureReasonErrorKey];
			[info setObject: NSLocalizedString( @"Wrong geometry kind", @"Error")
				forKey: NSLocalizedDescriptionKey];
			[info setObject: NSLocalizedString( @"This function doesn't work on this type of geometry", @"Error")
				forKey: NSLocalizedRecoverySuggestionErrorKey];
			break;
		case kPyGeometryError_otherError:
			[info setObject: NSLocalizedString( @"Invalid return from function", @"Error")
				forKey: NSLocalizedFailureReasonErrorKey];
			[info setObject: NSLocalizedString( @"Infinite point returned", @"Error")
				forKey: NSLocalizedDescriptionKey];
			[info setObject: NSLocalizedString( @"Something caused an error in the underlying function", @"Error")
				forKey: NSLocalizedRecoverySuggestionErrorKey];
			break;
			
		case kPyGeometryError_noGeometry:
		default:
			[info setObject: NSLocalizedString( @"No geometry to work on", @"Error")
				forKey: NSLocalizedFailureReasonErrorKey];
			[info setObject: NSLocalizedString( @"No Geometry set in module", @"Error")
				forKey: NSLocalizedDescriptionKey];
			[info setObject: NSLocalizedString( @"Make sure this function is called with a valid geometry", @"Error")
			
				forKey: NSLocalizedRecoverySuggestionErrorKey];
			break;
	}
	
	
	*errorPtr = [NSError errorWithDomain: kPyGeometryModuleDomain code: code userInfo: info];
	
	return YES;
}
@end

#pragma mark Point code
PyObject *geometry_point_getAttr(PyObject *myself, PyObject *pyName)
{
	PyGeometryPointObject *point = (PyGeometryPointObject*)myself;
	
	if (!myself) {
		PyErr_SetString( PyExc_AttributeError, "no object");
		return NULL;
	}
	
	// TODO check type
	assert(Py_TYPE(point) == &PyGeometryPointObjectType);
	if ((!pyName) || (!PyUnicode_Check( pyName))) {
		PyErr_SetString( PyExc_AttributeError, "invalid type of name");
		return NULL;
	}
	const char *name = PyUnicode_AsUTF8( pyName);
	switch (name[0]) {
		case 'x': return Py_BuildValue("f",point->x);//PyFloat_FromDouble( point->x);
		case 'y': return PyFloat_FromDouble( point->y);
		case 'z': return PyFloat_FromDouble( point->z);
		case 'm': return PyFloat_FromDouble( point->m);
		case 'i': return PyLong_FromLong( point->identifier);
	}

	return PyErr_Format( PyExc_AttributeError, "type object 'geometry.point' has no attribute '%s'", name);
}

int geometry_point_setAttr(PyObject *myself, PyObject *name, PyObject *newValue)
{
	PyErr_SetString( PyExc_TypeError, "setting not yet allowed");
	return -1;
}

#pragma mark Rect code
PyObject *geometry_rect_getAttr(PyObject *myself, PyObject *pyName)
{
	PyGeometryRectObject *pRect = (PyGeometryRectObject*)myself;
	
	if (!myself) {
		PyErr_SetString( PyExc_AttributeError, "no object");
		return NULL;
	}
	
	// TODO check type
	assert(Py_TYPE(pRect) == &PyGeometryRectObjectType);
	if ((!pyName) || (!PyUnicode_Check( pyName))) {
		PyErr_SetString( PyExc_AttributeError, "invalid type of name");
		return NULL;
	}
	const char *name = PyUnicode_AsUTF8(pyName);
	switch (name[0]) {
		case 'x': return Py_BuildValue("f",pRect->x);//PyFloat_FromDouble( point->x);
		case 'y': return PyFloat_FromDouble( pRect->y);
		case 'h': return PyFloat_FromDouble( pRect->height);
		case 'w': return PyFloat_FromDouble( pRect->width);
//		case 'o': return PyFloat_FromDouble( pRect->m);	// origin as point
	}

	return PyErr_Format( PyExc_AttributeError, "type object 'geometry.point' has no attribute '%s'", name);
}

int geometry_rect_setAttr(PyObject *myself, PyObject *name, PyObject *newValue)
{
	PyErr_SetString( PyExc_TypeError, "setting not yet allowed");
	return -1;
}

#pragma mark Python Code

//kMapEntityDraw_Null = kShpFile_Shape_Null,
//kMapEntityDraw_Point= kShpFile_Shape_Point,
//kMapEntityDraw_Line = kShpFile_Shape_PolyLine,
//kMapEntityDraw_Poly = kShpFile_Shape_Polygon,



PyObject *geometry_length( PyObject *self, PyObject *args)
{
	// ignore args, since we don't have any
    int base=0;
    if(!PyArg_ParseTuple(args, "|I:length", &base))
        return NULL;

	id<MapGeometryExternalProtocol> geometry = [libraryValues objectForKey: @"geometry"];
	if (!geometry) {
		PyErr_SetObject( GeometryError, Py_BuildValue( "i", kPyGeometryError_noGeometry));
		return NULL;
	}

    NSUInteger geometryIndex = [[libraryValues objectForKey: @"geometryIndex"] unsignedIntValue];

    // run the geometry function
    __block NSNumber *resultDistance=nil;
    NSCondition *condition = [[NSCondition alloc] init];
    NSDate *timeout = [NSDate dateWithTimeIntervalSinceNow: 1.0];
    [condition lock];
    [geometry distanceOfGeometry: geometryIndex asBase:base withReply:^(NSNumber *distance) {
        [condition lock];
        resultDistance = distance;
        [condition signal];
        [condition unlock];
    }];
    while(!resultDistance) {
        if (![condition waitUntilDate: timeout]) {
            PyErr_SetObject( GeometryError, Py_BuildValue( "i", kPyGeometryError_noGeometry));
            break;
        }
    }
    [condition unlock];
    
    // no value = wrong kind
    if (!resultDistance) {
        PyErr_SetObject( GeometryError, Py_BuildValue( "i", kPyGeometryError_wrongKind));
        return NULL;
    }
	return Py_BuildValue("f", resultDistance.doubleValue);
}

PyObject *geometry_area( PyObject *self, PyObject *args)
{
    int base=0;
	// ignore args, since we don't have any
    if(!PyArg_ParseTuple(args, "|I:area", &base))
        return NULL;

    id<MapGeometryExternalProtocol> geometry = [libraryValues objectForKey: @"geometry"];
	if (!geometry) {
		PyErr_SetObject( GeometryError, Py_BuildValue( "i", kPyGeometryError_noGeometry));
		return NULL;
	}

    NSUInteger geometryIndex = [[libraryValues objectForKey: @"geometryIndex"] unsignedIntValue];

    // run the geometry function
    __block NSNumber *resultArea=nil;
    NSCondition *condition = [[NSCondition alloc] init];
    NSDate *timeout = [NSDate dateWithTimeIntervalSinceNow: 1.0];
    [condition lock];
    [geometry areaOfGeometry: geometryIndex asBase:base withReply:^(NSNumber *area) {
        [condition lock];
        resultArea = area;
        [condition signal];
        [condition unlock];
    }];
    while (!resultArea) {
        if (![condition waitUntilDate: timeout]) {
            PyErr_SetObject( GeometryError, Py_BuildValue( "i", kPyGeometryError_noGeometry));
            break;
        }
    }
    [condition unlock];
    
    // no value = wrong kind
    if (!resultArea) {
        PyErr_SetObject( GeometryError, Py_BuildValue( "i", kPyGeometryError_wrongKind));
        return NULL;
    }

	return Py_BuildValue("f", resultArea.doubleValue);
}


PyObject *geometry_centroid( PyObject *self, PyObject *args)
{
	int base=0;
	
    if(!PyArg_ParseTuple(args, "|I:centroid", &base))
        return NULL;
		
    id<MapGeometryExternalProtocol> geometry = [libraryValues objectForKey: @"geometry"];
	if (!geometry) {
		PyErr_SetObject( GeometryError, Py_BuildValue( "i", kPyGeometryError_noGeometry));
		return NULL;
	}

    NSUInteger geometryIndex = [[libraryValues objectForKey: @"geometryIndex"] unsignedIntValue];

    // run the geometry function
    __block NSValue *resultPoint=nil;
    NSCondition *condition = [[NSCondition alloc] init];
    NSDate *timeout = [NSDate dateWithTimeIntervalSinceNow: 1.0];
    __block BOOL done=NO;
    [condition lock];
    [geometry centroidOfGeometry: geometryIndex asBase:base withReply:^(NSValue *point) {
        [condition lock];
        resultPoint = point;
        done=YES;
        [condition signal];
        [condition unlock];
    }];
    while (!done) {
        if (![condition waitUntilDate: timeout]) {
            PyErr_SetObject( GeometryError, Py_BuildValue( "i", kPyGeometryError_noGeometry));
            break;
        }
    }
    [condition unlock];
    
    // no value = wrong kind
    if (!resultPoint) {
        PyErr_SetObject( GeometryError, Py_BuildValue( "i", kPyGeometryError_wrongKind));
        return NULL;
    }
    
    NSPoint point = resultPoint.pointValue;
    double z=0, m=0;
    
    if (ISNULLPOINT(point.x,point.y)) {
        PyErr_SetObject( GeometryError, Py_BuildValue( "i", kPyGeometryError_otherError));
		return NULL;
	}
	
	PyGeometryPointObject *pPoint = PyObject_New( PyGeometryPointObject, &PyGeometryPointObjectType);
	if (!pPoint) {
		return PyErr_NoMemory();
	}
	
	pPoint->x = point.x;
	pPoint->y = point.y;
	pPoint->z = z;
	pPoint->m = m;
	pPoint->identifier = 0;
	return (PyObject*)pPoint;
}

PyObject *geometry_midpoint( PyObject *self, PyObject *args)
{
    int base=0;
    
    if(!PyArg_ParseTuple(args, "|I:midpoint", &base))
        return NULL;
		
    id<MapGeometryExternalProtocol> geometry = [libraryValues objectForKey: @"geometry"];
	if (!geometry) {
		PyErr_SetObject( GeometryError, Py_BuildValue( "i", kPyGeometryError_noGeometry));
		return NULL;
	}
	
    NSUInteger geometryIndex = [[libraryValues objectForKey: @"geometryIndex"] unsignedIntValue];

    // run the geometry function
    __block NSValue *resultPoint=nil;
    __block BOOL done=NO;
    NSDate *timeout = [NSDate dateWithTimeIntervalSinceNow: 1.0];
    NSCondition *condition = [[NSCondition alloc] init];
    [condition lock];
    [geometry midpointOfGeometry: geometryIndex asBase:base withReply:^(NSValue *point) {
        [condition lock];
        resultPoint = point;
        done = YES;
        [condition signal];
        [condition unlock];
    }];
    while (!done) {
        if (![condition waitUntilDate: timeout]) {
            PyErr_SetObject( GeometryError, Py_BuildValue( "i", kPyGeometryError_noGeometry));
            break;
        }
    }
    [condition unlock];
    
    // no value = wrong kind
    if (!resultPoint) {
        PyErr_SetObject( GeometryError, Py_BuildValue( "i", kPyGeometryError_wrongKind));
        return NULL;
    }
    
    NSPoint point = resultPoint.pointValue;

    if (ISNULLPOINT(point.x,point.y)) {
		PyErr_SetObject( GeometryError, Py_BuildValue( "i", kPyGeometryError_otherError));
		return NULL;
	}
	
	PyGeometryPointObject *pPoint = PyObject_New( PyGeometryPointObject, &PyGeometryPointObjectType);
	if (!pPoint) {
		return PyErr_NoMemory();
	}
	
	pPoint->x = point.x;
	pPoint->y = point.y;
	pPoint->z = 0;
	pPoint->m = 0;
	pPoint->identifier = 0;
	return (PyObject*)pPoint;
}

PyObject *geometry_bbox( PyObject *self, PyObject *args)
{
	int base=0;
	
    if(!PyArg_ParseTuple(args, "|I:bbox", &base))
        return NULL;
		
    id<MapGeometryExternalProtocol> geometry = [libraryValues objectForKey: @"geometry"];
	if (!geometry) {
		PyErr_SetObject( GeometryError, Py_BuildValue( "i", kPyGeometryError_noGeometry));
		return NULL;
	}
	
    NSUInteger geometryIndex = [[libraryValues objectForKey: @"geometryIndex"] unsignedIntValue];

    // run the geometry function
    __block NSValue *resultRect=nil;
    __block BOOL done=NO;
    NSCondition *condition = [[NSCondition alloc] init];
    NSDate *timeout = [NSDate dateWithTimeIntervalSinceNow: 1.0];
    [condition lock];
    [geometry boundingBoxOfGeometry: geometryIndex asBase:base withReply:^(NSValue *rect) {
        [condition lock];
        resultRect = rect;
        done=YES;
        [condition signal];
        [condition unlock];
    }];
    while(!done) {
        if (![condition waitUntilDate: timeout]) {
            PyErr_SetObject( GeometryError, Py_BuildValue( "i", kPyGeometryError_noGeometry));
            break;
        }
    }
    [condition unlock];
    
    // no value = wrong kind
    if (!resultRect) {
        PyErr_SetObject( GeometryError, Py_BuildValue( "i", kPyGeometryError_wrongKind));
        return NULL;
    }
    
	PyGeometryRectObject *pRect = PyObject_New( PyGeometryRectObject, &PyGeometryRectObjectType);
	if (!pRect) {
		return PyErr_NoMemory();
	}
    NSRect boundingBox = resultRect.rectValue;
    
	pRect->x = boundingBox.origin.x;
	pRect->y = boundingBox.origin.y;
	pRect->height = boundingBox.size.height;
	pRect->width = boundingBox.size.width;
	return (PyObject*)pRect;
}

PyObject *geometry_pointcount( PyObject *self, PyObject *args)
{
    if(!PyArg_ParseTuple(args, ":pointcount"))
        return NULL;
		
    id<MapGeometryExternalProtocol> geometry = [libraryValues objectForKey: @"geometry"];
	if (!geometry) {
		PyErr_SetObject( GeometryError, Py_BuildValue( "i", kPyGeometryError_noGeometry));
		return NULL;
	}
    NSUInteger geometryIndex = [[libraryValues objectForKey: @"geometryIndex"] unsignedIntValue];

    __block NSNumber *resultCount;
    __block BOOL done=NO;
    NSCondition *condition = [[NSCondition alloc] init];
    NSDate *timeout = [NSDate dateWithTimeIntervalSinceNow: 1.0];
    [condition lock];
    [geometry pointCountOfGeometry: geometryIndex withReply:^(NSNumber *count) {
        [condition lock];
        resultCount = count;
        done = YES;
        [condition signal];
        [condition unlock];
    }];
    while(!done) {
        if (![condition waitUntilDate: timeout]) {
            PyErr_SetObject( GeometryError, Py_BuildValue( "i", kPyGeometryError_noGeometry));
            break;
        }
    }
    [condition unlock];

    return Py_BuildValue("i", resultCount.intValue);
}

PyObject *geometry_partcount( PyObject *self, PyObject *args)
{
    if(!PyArg_ParseTuple(args, ":partcount"))
        return NULL;
    
    id<MapGeometryExternalProtocol> geometry = [libraryValues objectForKey: @"geometry"];
	if (!geometry) {
		PyErr_SetObject( GeometryError, Py_BuildValue( "i", kPyGeometryError_noGeometry));
		return NULL;
	}
	
    NSUInteger geometryIndex = [[libraryValues objectForKey: @"geometryIndex"] unsignedIntValue];

    __block NSNumber *resultCount;
    __block BOOL done = NO;
    NSCondition *condition = [[NSCondition alloc] init];
    NSDate *timeout = [NSDate dateWithTimeIntervalSinceNow: 1.0];
    [condition lock];
    [geometry partCountOfGeometry: geometryIndex withReply:^(NSNumber *count) {
        [condition lock];
        resultCount = count;
        done=YES;
        [condition signal];
        [condition unlock];
    }];
    while(!done) {
        if (![condition waitUntilDate: timeout]) {
            PyErr_SetObject( GeometryError, Py_BuildValue( "i", kPyGeometryError_noGeometry));
            break;
        }
    }
    [condition unlock];
    
	return Py_BuildValue("i", resultCount.intValue);
}
