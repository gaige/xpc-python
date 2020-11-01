//
//  MapGeometryExternalProxy.h
//  MapClueCD
//
//  Created by Gaige B. Paulsen on 12/29/19.See accompanying LICENSE document.
//  Copyright 2019, ClueTrust.
//

#import <Foundation/Foundation.h>
#import "MapGeometryExternalProtocol.h"
#import "MapGeometry.h"

NS_ASSUME_NONNULL_BEGIN

@interface MapGeometryExternalProxy : NSObject<MapGeometryExternalProtocol>
@property(strong) NSArray<MapGeometry*> *geometries;

+ (instancetype)mapGeometryExternalProxyWithMapGeometry:(MapGeometry*)geometry;
+ (instancetype)mapGeometryExternalProxyWithMapGeometryArray:(NSArray<MapGeometry*>*)geometries;
- (instancetype)initWithMapGeometryArray:(NSArray<MapGeometry*>*)geometries;
@end

NS_ASSUME_NONNULL_END
