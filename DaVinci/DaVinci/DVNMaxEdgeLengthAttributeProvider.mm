// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "DVNMaxEdgeLengthAttributeProvider.h"

#import <LTEngine/LTAttributeData.h>

NS_ASSUME_NONNULL_BEGIN

LTGPUStructImplement(DVNMaxEdgeLengthAttributeProviderStruct,
                     float, maxEdgeLength);

@interface DVNMaxEdgeLengthAttributeProviderModel () <DVNAttributeProvider>
@end

@implementation DVNMaxEdgeLengthAttributeProviderModel

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (BOOL)isEqual:(DVNMaxEdgeLengthAttributeProviderModel *)model {
  if (self == model) {
    return YES;
  }

  return [model isKindOfClass:[DVNMaxEdgeLengthAttributeProviderModel class]];
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
                              structForName:@"DVNMaxEdgeLengthAttributeProviderStruct"];
    sampleAttributeData =
        [[LTAttributeData alloc] initWithData:[NSData data] inFormatOfGPUStruct:gpuStruct];
  });
  return sampleAttributeData;
}

#pragma mark -
#pragma mark DVNAttributeProvider
#pragma mark -

- (LTAttributeData *)attributeDataFromGeometryValues:(dvn::GeometryValues)geometryValues {
  std::vector<DVNMaxEdgeLengthAttributeProviderStruct> attributes;
  std::vector<lt::Quad>::size_type size = geometryValues.quads().size();
  attributes.reserve(size);

  for (NSUInteger i = 0; i < size; ++i) {
    float maxEdgeLength = geometryValues.quads()[i].maximumEdgeLength();
    attributes.insert(attributes.end(), 6, {maxEdgeLength});
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
