// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "DVNQuadCenterAttributeProvider.h"

#import <LTEngine/LTAttributeData.h>

NS_ASSUME_NONNULL_BEGIN

LTGPUStructImplement(DVNQuadCenterAttributeProviderStruct,
                     LTVector2, quadCenter);

@interface DVNQuadCenterAttributeProviderModel () <DVNAttributeProvider>
@end

@implementation DVNQuadCenterAttributeProviderModel

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (BOOL)isEqual:(DVNQuadCenterAttributeProviderModel *)model {
  if (self == model) {
    return YES;
  }

  return [model isKindOfClass:[DVNQuadCenterAttributeProviderModel class]];
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
    LTGPUStruct *gpuStruct = [[LTGPUStructRegistry sharedInstance]
                              structForName:@"DVNQuadCenterAttributeProviderStruct"];
    sampleAttributeData =
        [[LTAttributeData alloc] initWithData:[NSData data] inFormatOfGPUStruct:gpuStruct];
  });
  return sampleAttributeData;
}

#pragma mark -
#pragma mark DVNAttributeProvider
#pragma mark -

- (LTAttributeData *)attributeDataFromGeometryValues:(dvn::GeometryValues)geometryValues {
  std::vector<lt::Quad>::size_type size = geometryValues.quads().size();
  std::vector<DVNQuadCenterAttributeProviderStruct> attributes;
  attributes.reserve(size);

  for (std::vector<lt::Quad>::size_type i = 0; i < size; ++i) {
    lt::Quad quad = geometryValues.quads()[i];

    LTVector2 center(quad.center());

    std::array<DVNQuadCenterAttributeProviderStruct, 6> values({{
      {center}, {center}, {center}, {center}, {center}, {center}
    }});

    attributes.insert(attributes.end(), values.begin(), values.end());
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
