//
//  MapGeometryExternalProxy.m
//  MapClueCD
//
//  Created by Gaige B. Paulsen on 12/29/19. See accompanying LICENSE document.
//  Copyright 2019, ClueTrust.
//

#import "MapGeometryExternalProxy.h"

@implementation MapGeometryExternalProxy

- (instancetype)initWithMapGeometryArray:(NSArray<MapGeometry*>*)geometries
{
    self = [super init];
    if (self) {
        _geometries = geometries;
    }
    return self;
}

+ (instancetype)mapGeometryExternalProxyWithMapGeometryArray:(NSArray<MapGeometry*>*)geometries;
{
    return [[self alloc] initWithMapGeometryArray: geometries];
}

+(instancetype)mapGeometryExternalProxyWithMapGeometry:(MapGeometry *)geometry
{
    return [[self alloc] initWithMapGeometryArray: @[geometry]];
}

- (void)pointCountOfGeometry:(NSUInteger)geometryIndex withReply:(void (^)(NSNumber *))reply
{
    NSNumber *result = nil;
    if (geometryIndex<_geometries.count)
        result = @(_geometries[geometryIndex].pointCount);
    reply(result);
}

- (void)partCountOfGeometry:(NSUInteger)geometryIndex withReply:(void (^)(NSNumber *))reply
{
    NSNumber *result = nil;
    if (geometryIndex<_geometries.count)
        result = @(_geometries[geometryIndex].partCount);
    reply(result);
}

- (void)areaOfGeometry:(NSUInteger)geometryIndex asBase:(BOOL)isBase withReply:(void (^)(NSNumber *))reply
{
    NSNumber *result = nil;
    if (geometryIndex<_geometries.count) {
        if (isBase)
            result = @(_geometries[geometryIndex].baseArea);
        else
            result = @(_geometries[geometryIndex].area);
    }
    reply(result);
}


- (void)boundingBoxOfGeometry:(NSUInteger)geometryIndex asBase:(BOOL)isBase withReply:(void (^)(NSValue *))reply
{
    NSValue *result = nil;
    if (geometryIndex<_geometries.count) {
        if (_geometries[geometryIndex].pointCount>0) {
            if (isBase)
                result = @(_geometries[geometryIndex].baseBoundingBox);
            else
                result = @(_geometries[geometryIndex].boundingBox);
        }
    }
    reply(result);
}


- (void)centroidOfGeometry:(NSUInteger)geometryIndex asBase:(BOOL)isBase withReply:(void (^)(NSValue *))reply
{
    NSValue *result = nil;
    if (geometryIndex<_geometries.count) {
        if (isBase)
            result = @(_geometries[geometryIndex].baseCentroid);
        else
            result = @(_geometries[geometryIndex].centroid);
    }
    reply(result);
}


- (void)distanceOfGeometry:(NSUInteger)geometryIndex asBase:(BOOL)isBase withReply:(void (^)(NSNumber *))reply
{
    NSNumber *result = nil;
    if (geometryIndex<_geometries.count) {
        if (isBase) {
            result = @([_geometries[geometryIndex] baseDistanceWithSegmentLengths: NULL]);
        } else {
            result = @([_geometries[geometryIndex] projectedDistanceWithSegmentLengths: NULL]);
        }
    }
    reply(result);
}

- (void)midpointOfGeometry:(NSUInteger)geometryIndex asBase:(BOOL)isBase withReply:(void (^)(NSValue *))reply
{
    NSValue *result = nil;
    if (geometryIndex<_geometries.count) {
        // midpoint inappropriate for rectangle (only lines)
    }
    reply(result);
}
@end
