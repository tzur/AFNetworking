// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "DVNSquareProvider.h"

#import <LTEngine/LTParameterizationKeyToValues.h>
#import <LTEngine/LTParameterizedObject.h>
#import <LTEngine/LTQuad.h>
#import <LTEngine/LTSampleValues.h>
#import <LTEngine/LTSplineControlPoint.h>

#import "DVNGeometryValues.h"

NS_ASSUME_NONNULL_BEGIN

@interface DVNSquareProviderModel () <DVNGeometryProvider>
@end

@implementation DVNSquareProviderModel

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithEdgeLength:(CGFloat)edgeLength {
  return [self initWithEdgeLength:edgeLength
                   xCoordinateKey:@instanceKeypath(LTSplineControlPoint, xCoordinateOfLocation)
                   yCoordinateKey:@instanceKeypath(LTSplineControlPoint, yCoordinateOfLocation)];
}

- (instancetype)initWithEdgeLength:(CGFloat)edgeLength xCoordinateKey:(NSString *)xCoordinateKey
                    yCoordinateKey:(NSString *)yCoordinateKey {
  LTParameterAssert(edgeLength > 0, @"Invalid edge length provided: %g", edgeLength);
  LTParameterAssert(xCoordinateKey.length);
  LTParameterAssert(yCoordinateKey.length);
  LTParameterAssert(![xCoordinateKey isEqualToString:yCoordinateKey], @"Keys (%@) must be distinct",
                    xCoordinateKey);

  if (self = [super init]) {
    _edgeLength = edgeLength;
    _xCoordinateKey = xCoordinateKey;
    _yCoordinateKey = yCoordinateKey;
  }
  return self;
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (BOOL)isEqual:(DVNSquareProviderModel *)model {
  if (self == model) {
    return YES;
  }

  if (![model isKindOfClass:[DVNSquareProviderModel class]]) {
    return NO;
  }

  return self.edgeLength == model.edgeLength &&
      [self.xCoordinateKey isEqual:model.xCoordinateKey] &&
      [self.yCoordinateKey isEqual:model.yCoordinateKey];
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
#pragma mark DVNGeometryProviderModel
#pragma mark -

- (id<DVNGeometryProvider>)provider {
  return self;
}

#pragma mark -
#pragma mark DVNGeometryProvider
#pragma mark -

- (dvn::GeometryValues)valuesFromSamples:(id<LTSampleValues>)samples end:(__unused BOOL)end {
  LTParameterizationKeyToValues *mapping = samples.mappingOfSampledValues;
  std::vector<CGFloat> sampledParametricValues = samples.sampledParametricValues;

  [self validateMapping:mapping];

  std::vector<CGFloat> xCoordinates = [mapping valuesForKey:self.xCoordinateKey];
  std::vector<CGFloat> yCoordinates = [mapping valuesForKey:self.yCoordinateKey];

  LTAssert(xCoordinates.size() == yCoordinates.size(),
           @"Number (%lu) of x-coordinates does not match number (%lu) of y-coordinates",
           (unsigned long)xCoordinates.size(), (unsigned long)yCoordinates.size());

  std::vector<lt::Quad> quads;
  quads.reserve(xCoordinates.size());

  CGSize size = CGSizeMakeUniform(self.edgeLength);

  for (NSUInteger i = 0; i < xCoordinates.size(); ++i) {
    CGRect rect = CGRectCenteredAt(CGPointMake(xCoordinates[i], yCoordinates[i]), size);
    quads.push_back(lt::Quad(rect));
  }

  std::vector<NSUInteger> indices;
  indices.reserve(quads.size());

  for (NSUInteger i = 0; i < quads.size(); ++i) {
    indices.push_back(i);
  }

  return dvn::GeometryValues(quads, indices, samples);
}

- (void)validateMapping:(LTParameterizationKeyToValues *)mapping {
  LTParameterAssert([mapping.keys containsObject:self.xCoordinateKey],
                    @"The keys (%@) of the given mapping (%@) do not contain the key (%@) required "
                    "to construct geometry", mapping.keys, mapping, self.xCoordinateKey);
  LTParameterAssert([mapping.keys containsObject:self.yCoordinateKey],
                    @"The keys (%@) of the given mapping (%@) do not contain the key (%@) required "
                    "to construct geometry", mapping.keys, mapping, self.yCoordinateKey);
}

- (id<DVNGeometryProviderModel>)currentModel {
  return self;
}

@end

NS_ASSUME_NONNULL_END
