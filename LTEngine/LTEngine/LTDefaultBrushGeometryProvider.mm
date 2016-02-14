// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTDefaultBrushGeometryProvider.h"

#import <LTKit/LTHashExtensions.h>

#import "LTEuclideanSplineControlPoint.h"
#import "LTParameterizedObject.h"
#import "LTRotatedRect.h"

NS_ASSUME_NONNULL_BEGIN

@interface LTDefaultBrushGeometryProvider ()

/// Edge length of any rotated rect provided by this object.
@property (nonatomic) CGFloat edgeLength;

@end

@implementation LTDefaultBrushGeometryProvider

/// Key of x-coordinate property of an \c LTEuclideanSplineControlPoint.
static NSString * const kXCoordinateKey = @instanceKeypath(LTEuclideanSplineControlPoint,
                                                           xCoordinateOfLocation);

/// Key of y-coordinate property of an \c LTEuclideanSplineControlPoint.
static NSString * const kYCoordinateKey = @instanceKeypath(LTEuclideanSplineControlPoint,
                                                           yCoordinateOfLocation);

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithEdgeLength:(CGFloat)edgeLength {
  LTParameterAssert(edgeLength > 0, @"Invalid edge length provided: %g", edgeLength);

  if (self = [super init]) {
    self.edgeLength = edgeLength;
  }
  return self;
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (BOOL)isEqual:(LTDefaultBrushGeometryProvider *)provider {
  if (self == provider) {
    return YES;
  }

  if (![provider isKindOfClass:[LTDefaultBrushGeometryProvider class]]) {
    return NO;
  }

  return self.edgeLength == provider.edgeLength;
}

- (NSUInteger)hash {
  return lt::hash<CGFloat>()(self.edgeLength);
}

#pragma mark -
#pragma mark NSCopying
#pragma mark -

- (instancetype)copyWithZone:(nullable NSZone __unused *)zone {
  return self;
}

#pragma mark -
#pragma mark LTBrushGeometryProviderModel
#pragma mark -

- (id<LTBrushGeometryProvider>)provider {
  return self;
}

#pragma mark -
#pragma mark LTBrushGeometryProvider
#pragma mark -

- (NSArray<LTRotatedRect *> *)rotatedRectsFromParameterizedObject:(id<LTParameterizedObject>)object
                                               atParametricValues:(CGFloats)parametricValues {
  LTParameterAssert([object.parameterizationKeys containsObject:kXCoordinateKey],
                    @"The parameterization keys (%@) of the given parameterized object (%@) do not "
                    "contain the key (%@) required to construct geometry",
                    object.parameterizationKeys, object, kXCoordinateKey);
  LTParameterAssert([object.parameterizationKeys containsObject:kYCoordinateKey],
                    @"The parameterization keys (%@) of the given parameterized object (%@) do not "
                    "contain the key (%@) required to construct geometry",
                    object.parameterizationKeys, object, kYCoordinateKey);
  return [self rectsFromMapping:[object mappingForParametricValues:parametricValues]];
}

- (NSArray<LTRotatedRect *> *)rectsFromMapping:(LTParameterizationKeyToValues *)mapping {
  NSArray<NSNumber *> *xCoordinates = [mapping valueForKey:kXCoordinateKey];
  NSArray<NSNumber *> *yCoordinates = [mapping valueForKey:kYCoordinateKey];

  LTAssert(xCoordinates.count == yCoordinates.count,
           @"Number (%lu) of x-coordinates does not match number (%lu) of y-coordinates",
           (unsigned long)xCoordinates.count, (unsigned long)yCoordinates.count);

  NSMutableArray<LTRotatedRect *> *mutableRects =
      [NSMutableArray arrayWithCapacity:xCoordinates.count];

  for (NSUInteger i = 0; i < xCoordinates.count; ++i) {
    LTRotatedRect *rotatedRect =
        [LTRotatedRect rectWithCenter:CGPointMake([xCoordinates[i] CGFloatValue],
                                                  [yCoordinates[i] CGFloatValue])
                                 size:self.rectSize angle:0];
    [mutableRects addObject:rotatedRect];
  }

  return [mutableRects copy];
}

- (CGSize)rectSize {
  return CGSizeMakeUniform(self.edgeLength);
}

- (LTRotatedRect *)rotatedRectFromControlPoint:(LTEuclideanSplineControlPoint *)point {
  return [LTRotatedRect rectWithCenter:point.location size:self.rectSize angle:0];
}

- (id<LTBrushGeometryProviderModel>)currentModel {
  return self;
}

@end

NS_ASSUME_NONNULL_END
