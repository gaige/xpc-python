//
//  MapGeometryExternalProtocol.h
//  MapClueCD
//
//  Created by Gaige B. Paulsen on 12/29/19. See accompanying LICENSE document.
//  Copyright 2019, ClueTrust.
//

#ifndef MapGeometryExternalProtocol_h
#define MapGeometryExternalProtocol_h

#define ISNULLPOINT(x,y) (isinf((float)x)||isinf((float)y))

@protocol MapGeometryExternalProtocol <NSObject>
- (void)pointCountOfGeometry:(NSUInteger)geometryIndex withReply:(void (^)(NSNumber *pointCount))reply;
- (void)partCountOfGeometry:(NSUInteger)geometryIndex withReply:(void (^)(NSNumber *partCount))reply;
- (void)distanceOfGeometry:(NSUInteger)geometryIndex asBase:(BOOL)isBase withReply:(void (^)(NSNumber *distance))reply;
- (void)areaOfGeometry:(NSUInteger)geometryIndex asBase:(BOOL)isBase withReply:(void (^)(NSNumber *area))reply;
- (void)centroidOfGeometry:(NSUInteger)geometryIndex asBase:(BOOL)isBase withReply:(void (^)(NSValue *point))reply; //CGPoint
- (void)midpointOfGeometry:(NSUInteger)geometryIndex asBase:(BOOL)isBase withReply:(void (^)(NSValue *point))reply; //CGPoint
- (void)boundingBoxOfGeometry:(NSUInteger)geometryIndex asBase:(BOOL)isBase withReply:(void (^)(NSValue *rect))reply; //CGRect
@end

#endif /* MapGeometryExternalProtocol_h */
