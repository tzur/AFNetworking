// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "DVNDirectedRectProvider.h"

#import <LTEngine/LTParameterizationKeyToValues.h>
#import <LTEngine/LTParameterizedObject.h>
#import <LTEngine/LTQuad.h>
#import <LTEngine/LTSampleValues.h>
#import <LTEngine/LTSplineControlPoint.h>

#import "DVNGeometryValues.h"

NS_ASSUME_NONNULL_BEGIN

@interface DVNDirectedRectProvider : NSObject <DVNGeometryProvider>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given \c model.
- (instancetype)initWithModel:(DVNDirectedRectProviderModel *)model NS_DESIGNATED_INITIALIZER;

/// Model provided upon initialization.
@property (readonly, nonatomic) DVNDirectedRectProviderModel *model;

/// Base point to be used for computing the rotation of the next quad returned by the \c provider
/// retrievable from this instance.
@property (nonatomic) CGPoint directionComputationBasePoint;

@end

@interface DVNDirectedRectProviderModel ()

/// Returns a new instance equal to this instance, with the exception of the given
/// \c directionComputationBasePoint.
- (instancetype)copyWithDirectionComputationBasePoint:(CGPoint)point;

/// Base point to be used for computing the rotation of the next quad returned by the \c provider
/// retrievable from this instance.
@property (nonatomic) CGPoint directionComputationBasePoint;

@end

@implementation DVNDirectedRectProviderModel

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithSize:(CGSize)size {
  return [self initWithSize:size
             xCoordinateKey:@instanceKeypath(LTSplineControlPoint, xCoordinateOfLocation)
             yCoordinateKey:@instanceKeypath(LTSplineControlPoint, yCoordinateOfLocation)];
}

- (instancetype)initWithSize:(CGSize)size xCoordinateKey:(NSString *)xCoordinateKey
              yCoordinateKey:(NSString *)yCoordinateKey {
  LTParameterAssert(std::min(size) > 0, @"Invalid size: %@", NSStringFromCGSize(size));
  LTParameterAssert(xCoordinateKey.length);
  LTParameterAssert(yCoordinateKey.length);
  LTParameterAssert(![xCoordinateKey isEqualToString:yCoordinateKey], @"Keys (%@) must be distinct",
                    xCoordinateKey);

  if (self = [super init]) {
    _size = size;
    _xCoordinateKey = xCoordinateKey;
    _yCoordinateKey = yCoordinateKey;
    _directionComputationBasePoint = CGPointNull;
  }
  return self;
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

#pragma mark -
#pragma mark NSCopying
#pragma mark -

- (instancetype)copyWithZone:(nullable NSZone __unused *)zone {
  return self;
}

#pragma mark -
#pragma mark Copying
#pragma mark -

- (instancetype)copyWithDirectionComputationBasePoint:(CGPoint)point {
  DVNDirectedRectProviderModel *model = [[[self class] alloc] initWithSize:self.size
                                                            xCoordinateKey:self.xCoordinateKey
                                                            yCoordinateKey:self.yCoordinateKey];
  model.directionComputationBasePoint = point;
  return model;
}

#pragma mark -
#pragma mark DVNGeometryProviderModel
#pragma mark -

- (id<DVNGeometryProvider>)provider {
  return [[DVNDirectedRectProvider alloc] initWithModel:self];
}

@end

@implementation DVNDirectedRectProvider

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithModel:(DVNDirectedRectProviderModel *)model {
  if (self = [super init]) {
    _model = model;
    _directionComputationBasePoint = model.directionComputationBasePoint;
  }
  return self;
}

#pragma mark -
#pragma mark DVNGeometryProvider
#pragma mark -

- (dvn::GeometryValues)valuesFromSamples:(id<LTSampleValues>)samples end:(BOOL)end {
  LTParameterizationKeyToValues *mapping = samples.mappingOfSampledValues;
  CGFloats sampledParametricValues = samples.sampledParametricValues;

  [self validateMapping:mapping];

  CGFloats xCoordinates = [mapping valuesForKey:self.model.xCoordinateKey];
  CGFloats yCoordinates = [mapping valuesForKey:self.model.yCoordinateKey];

  LTAssert(xCoordinates.size() == yCoordinates.size(),
           @"Number (%lu) of x-coordinates does not match number (%lu) of y-coordinates",
           (unsigned long)xCoordinates.size(), (unsigned long)yCoordinates.size());

  std::vector<lt::Quad> quads;
  quads.reserve(xCoordinates.size());

  BOOL directionComputationBasePointWasNull = CGPointIsNull(self.directionComputationBasePoint);

  if (directionComputationBasePointWasNull) {
    self.directionComputationBasePoint = CGPointMake(xCoordinates.front(), yCoordinates.front());
    quads.push_back([self firstQuadForXCoordinates:xCoordinates yCoordinates:yCoordinates end:end]);
  }

  CGSize size = self.model.size;

  for (NSUInteger i = directionComputationBasePointWasNull ? 1 : 0; i < xCoordinates.size(); ++i) {
    CGPoint center = CGPointMake(xCoordinates[i], yCoordinates[i]);
    CGRect rect = CGRectCenteredAt(center, size);
    CGFloat angle = LTVector2(center - self.directionComputationBasePoint).angle(LTVector2(1, 0));
    quads.push_back(lt::Quad(rect).rotatedAroundPoint(-angle, center));
    self.directionComputationBasePoint = center;
  }

  std::vector<NSUInteger> indices;
  indices.reserve(quads.size());

  for (NSUInteger i = 0; i < quads.size(); ++i) {
    indices.push_back(i);
  }

  if (end) {
    self.directionComputationBasePoint = CGPointNull;
  }

  return dvn::GeometryValues(quads, indices, samples);
}

- (lt::Quad)firstQuadForXCoordinates:(const CGFloats &)xCoordinates
                        yCoordinates:(const CGFloats &)yCoordinates end:(BOOL)end {
  if (xCoordinates.size() == 1) {
    if (!end) {
      // If this is the first but not the only sample, create a degenerate quad since the correct
      // rotation angle is not known yet.
      return lt::Quad(CGRectCenteredAt(self.directionComputationBasePoint, CGSizeMakeUniform(0)));
    } else {
      // If this is the first and only sample, no direction can be computed, so provide a quad of
      // the desired size and without rotation.
      return lt::Quad(CGRectCenteredAt(self.directionComputationBasePoint, self.model.size));
    }
  }

  // If more than one sample are provided, use the rotation of the second quad also for the
  // first quad.
  CGRect rect = CGRectCenteredAt(self.directionComputationBasePoint, self.model.size);
  CGFloat angle = LTVector2(CGPointMake(xCoordinates[1], yCoordinates[1]) -
                            self.directionComputationBasePoint).angle(LTVector2(1, 0));
  return lt::Quad(rect).rotatedAroundPoint(-angle, self.directionComputationBasePoint);
}

- (void)validateMapping:(LTParameterizationKeyToValues *)mapping {
  LTParameterAssert([mapping.keys containsObject:self.model.xCoordinateKey],
                    @"The keys (%@) of the given mapping (%@) do not contain the key (%@) required "
                    "to construct geometry", mapping.keys, mapping, self.model.xCoordinateKey);
  LTParameterAssert([mapping.keys containsObject:self.model.yCoordinateKey],
                    @"The keys (%@) of the given mapping (%@) do not contain the key (%@) required "
                    "to construct geometry", mapping.keys, mapping, self.model.yCoordinateKey);
}

- (id<DVNGeometryProviderModel>)currentModel {
  return [self.model copyWithDirectionComputationBasePoint:self.directionComputationBasePoint];
}

@end

NS_ASSUME_NONNULL_END
