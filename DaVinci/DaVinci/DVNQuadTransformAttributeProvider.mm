// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

#import "DVNQuadTransformAttributeProvider.h"

#import <LTEngine/LTAttributeData.h>

NS_ASSUME_NONNULL_BEGIN

LTGPUStructImplement(DVNQuadTransformAttributeProviderStruct,
                     GLKVector3, row0,
                     GLKVector3, row1,
                     GLKVector3, row2);

@interface DVNQuadTransformAttributeProviderModel () <DVNAttributeProvider>
@end

@implementation DVNQuadTransformAttributeProviderModel

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithIsInverse:(BOOL)isInverse {
  if (self = [super init]) {
    _isInverse = isInverse;
  }
  return self;
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (BOOL)isEqual:(DVNQuadTransformAttributeProviderModel *)model {
  if (self == model) {
    return YES;
  }

  return [model isKindOfClass:[DVNQuadTransformAttributeProviderModel class]];
}

- (NSUInteger)hash {
  return 0;
}

#pragma mark -
#pragma mark NSCopying
#pragma mark -

- (instancetype)copyWithZone:(nullable NSZone __unused *)zone {
  return self;
}

#pragma mark -
#pragma mark DVNAttributeProviderModel
#pragma mark -

- (id<DVNAttributeProvider>)provider {
  return self;
}

- (LTAttributeData *)sampleAttributeData {
  static LTAttributeData *sampleAttributeData;

  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    LTGPUStruct *transformStruct = [[LTGPUStructRegistry sharedInstance]
                                    structForName:@"DVNQuadTransformAttributeProviderStruct"];
    sampleAttributeData = [[LTAttributeData alloc] initWithData:[NSData data]
                                            inFormatOfGPUStruct:transformStruct];
  });
  return sampleAttributeData;
}

#pragma mark -
#pragma mark DVNAttributeProvider
#pragma mark -

- (LTAttributeData *)attributeDataFromGeometryValues:(dvn::GeometryValues)geometryValues {
  std::vector<DVNQuadTransformAttributeProviderStruct> attributes;
  std::vector<lt::Quad>::size_type size = geometryValues.quads().size();
  attributes.reserve(size);

  for (NSUInteger i = 0; i < size; ++i) {
    lt::Quad quad = geometryValues.quads()[i];
    GLKMatrix3 transform = quad.transform();

    if (self.isInverse) {
      bool isInvertible;
      transform = GLKMatrix3Invert(transform, &isInvertible);
      LTAssert(isInvertible);
    }
    DVNQuadTransformAttributeProviderStruct values({
      .row0 = GLKMatrix3GetRow(transform, 0),
      .row1 = GLKMatrix3GetRow(transform, 1),
      .row2 = GLKMatrix3GetRow(transform, 2)
    });
    attributes.insert(attributes.end(), 6, {values});
  }

  NSData *data = [NSData dataWithBytes:attributes.data()
                                length:attributes.size() * sizeof(attributes[0])];
  return [[LTAttributeData alloc] initWithData:data inFormatOfGPUStruct:self.gpuStruct];
}

- (id<DVNAttributeProviderModel>)currentModel {
  return self;
}

#pragma mark -
#pragma mark Properties
#pragma mark -

- (LTGPUStruct *)gpuStruct {
  return self.sampleAttributeData.gpuStruct;
}

@end

NS_ASSUME_NONNULL_END
