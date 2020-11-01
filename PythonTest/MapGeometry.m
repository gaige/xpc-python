//
//  MapGeometry.m
//  PythonTest
// Stand-in for real MapGeometry
//
//  Created by Gaige B. Paulsen on 11/1/20. See accompanying LICENSE document.
//  Copyright 2020, ClueTrust.
//

#import "MapGeometry.h"

@implementation MapGeometry
+ (double) distanceFrom:(CGPoint)p1 to:(CGPoint)p2
{
    return sqrt(pow(p2.x-p1.x, 2.0)+pow(p2.y-p1.y, 2.0));
}

- (instancetype)initWithRect:(CGRect)rect
{
    self = [super init];
    if (self) {
        self.rect=rect;
    }
    return self;
}

+(BOOL)supportsSecureCoding
{
    return YES;
}

-(void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeRect: _rect forKey: @"rect"];
}

-(instancetype)initWithCoder:(NSCoder *)coder
{
    NSAssert( [coder allowsKeyedCoding], @"No Keyed coding!");
    self = [super init];
    if (self) {
        self.rect=[coder decodeRectForKey: @"rect"];
    }
    return self;
}

- (CGPoint) p0 { return _rect.origin; }
- (CGPoint) p1 { return CGPointMake(_rect.origin.x+_rect.size.width, _rect.origin.y); }
- (CGPoint) p2 { return CGPointMake(_rect.origin.x+_rect.size.width, _rect.origin.y+_rect.size.height); }
- (CGPoint) p3 { return CGPointMake(_rect.origin.x, _rect.origin.y+_rect.size.height); }

- (double) baseDistanceWithSegmentLengths:(nullable id)lengths
{
    return [MapGeometry distanceFrom: self.p0 to: self.p1]+
        [MapGeometry distanceFrom:self.p1 to:self.p2]+
        [MapGeometry distanceFrom:self.p2 to:self.p3]+
        [MapGeometry distanceFrom:self.p3 to:self.p0];
}

- (double) projectedDistanceWithSegmentLengths:(nullable id)lengths
{
    // placeholder for a more complex operation
    return [self baseDistanceWithSegmentLengths:nil] *2;
}

- (int) pointCount
{
    return 4; // rectangle always has 4
}

- (int) partCount
{
    return 1;   // one part
}

- (double)baseArea
{
    return _rect.size.height*_rect.size.width;
}

- (double) area
{
    return self.baseArea*2.0;
}

- (CGRect)baseBoundingBox
{
    return self.rect;
}

- (CGRect)boundingBox
{
    return self.rect;
}

- (CGPoint)baseCentroid
{
    return CGPointMake(_rect.origin.x+_rect.size.width/2.0, _rect.origin.y+_rect.size.height/2.0);
}

- (CGPoint)centroid
{
    return [self baseCentroid];
}

@end
