// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTTextureArchiveMetadata.h"

#import "LTTextureArchiveType.h"
#import "LTTextureMetadata.h"
#import "LTTransformers.h"

NS_ASSUME_NONNULL_BEGIN

@implementation LTTextureArchiveMetadata

#pragma mark -
#pragma mark Intialization
#pragma mark -

- (instancetype)initWithArchiveType:(LTTextureArchiveType *)type
                    textureMetadata:(LTTextureMetadata *)metadata {
  LTParameterAssert(type);
  LTParameterAssert(metadata);
  if (self = [super init]) {
    _archiveType = type;
    _textureMetadata = metadata;
  }
  return self;
}

#pragma mark -
#pragma mark Serialization
#pragma mark -

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
  return @{};
}

+ (NSValueTransformer *)archiveTypeJSONTransformer {
  return [LTTransformers transformerForClass:[LTTextureArchiveType class]];
}

+ (NSValueTransformer *)textureMetadataJSONTransformer {
  return [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:[LTTextureMetadata class]];
}

@end

NS_ASSUME_NONNULL_END
