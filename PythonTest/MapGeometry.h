//
//  MapGeometry.h
//  PythonTest
//
//  Created by Gaige B. Paulsen on 11/1/20. See accompanying LICENSE document.
//  Copyright 2020, ClueTrust.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MapGeometry : NSObject<NSSecureCoding>
- (instancetype)initWithRect:(CGRect)rect;
- (double) baseDistanceWithSegmentLengths:(nullable id)lengths;
- (double) projectedDistanceWithSegmentLengths:(nullable id)lengths;
- (int) pointCount;
- (int) partCount;
- (double)baseArea;
- (double) area;
- (CGRect)baseBoundingBox;
- (CGRect)boundingBox;
- (CGPoint)baseCentroid;
- (CGPoint)centroid;

@property CGRect rect;
@end

NS_ASSUME_NONNULL_END
