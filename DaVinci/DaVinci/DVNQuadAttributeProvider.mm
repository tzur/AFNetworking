// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "DVNQuadAttributeProvider.h"

#import <LTEngine/LTAttributeData.h>

NS_ASSUME_NONNULL_BEGIN

LTGPUStructImplement(DVNQuadAttributeProviderStruct,
                     LTVector2, quadVertex0,
                     LTVector2, quadVertex1,
                     LTVector2, quadVertex2,
                     LTVector2, quadVertex3);

@interface DVNQuadAttributeProviderModel () <DVNAttributeProvider>
@end

@implementation DVNQuadAttributeProviderModel

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (BOOL)isEqual:(DVNQuadAttributeProviderModel *)model {
  if (self == model) {
    return YES;
  }

  return [model isKindOfClass:[DVNQuadAttributeProviderModel class]];
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
    sampleAttributeData =
        [[LTAttributeData alloc] initWithData:[NSData data]
                          inFormatOfGPUStruct:[[LTGPUStructRegistry sharedInstance]
                                               structForName:@"DVNQuadAttributeProviderStruct"]];
  });
  return sampleAttributeData;
}

#pragma mark -
#pragma mark DVNAttributeProvider
#pragma mark -

- (LTAttributeData *)attributeDataFromGeometryValues:(dvn::GeometryValues)geometryValues {
  std::vector<DVNQuadAttributeProviderStruct> attributes;
  std::vector<lt::Quad>::size_type size = geometryValues.quads().size();
  attributes.reserve(size);

  for (NSUInteger i = 0; i < size; ++i) {
    lt::Quad quad = geometryValues.quads()[i];

    LTVector2 v0(quad.v0());
    LTVector2 v1(quad.v1());
    LTVector2 v2(quad.v2());
    LTVector2 v3(quad.v3());

    DVNQuadAttributeProviderStruct values({.quadVertex0 = v0, .quadVertex1 = v1, .quadVertex2 = v2,
        .quadVertex3 = v3});

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
