// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTDefaultBrushGeometryProvider.h"

#import <LTKit/LTHashExtensions.h>

#import "LTParameterizationKeyToValues.h"
#import "LTParameterizedObject.h"
#import "LTRotatedRect.h"
#import "LTSplineControlPoint.h"

NS_ASSUME_NONNULL_BEGIN

@interface LTDefaultBrushGeometryProvider ()

/// Edge length of any rotated rect provided by this object.
@property (nonatomic) CGFloat edgeLength;

@end

@implementation LTDefaultBrushGeometryProvider

/// Key of x-coordinate property of an \c LTSplineControlPoint.
static NSString * const kXCoordinateKey = @instanceKeypath(LTSplineControlPoint,
                                                           xCoordinateOfLocation);

/// Key of y-coordinate property of an \c LTSplineControlPoint.
static NSString * const kYCoordinateKey = @instanceKeypath(LTSplineControlPoint,
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
  return std::hash<CGFloat>()(self.edgeLength);
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
  CGFloats xCoordinates = [mapping valuesForKey:kXCoordinateKey];
  CGFloats yCoordinates = [mapping valuesForKey:kYCoordinateKey];

  LTAssert(xCoordinates.size() == yCoordinates.size(),
           @"Number (%lu) of x-coordinates does not match number (%lu) of y-coordinates",
           (unsigned long)xCoordinates.size(), (unsigned long)yCoordinates.size());

  NSMutableArray<LTRotatedRect *> *mutableRects =
      [NSMutableArray arrayWithCapacity:xCoordinates.size()];

  for (NSUInteger i = 0; i < xCoordinates.size(); ++i) {
    LTRotatedRect *rotatedRect =
        [LTRotatedRect rectWithCenter:CGPointMake(xCoordinates[i], yCoordinates[i])
                                 size:self.rectSize angle:0];
    [mutableRects addObject:rotatedRect];
  }

  return [mutableRects copy];
}

- (CGSize)rectSize {
  return CGSizeMakeUniform(self.edgeLength);
}

- (LTRotatedRect *)rotatedRectFromControlPoint:(LTSplineControlPoint *)point {
  return [LTRotatedRect rectWithCenter:point.location size:self.rectSize angle:0];
}

- (id<LTBrushGeometryProviderModel>)currentModel {
  return self;
}

@end

NS_ASSUME_NONNULL_END
