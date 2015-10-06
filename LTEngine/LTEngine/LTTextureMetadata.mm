// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTTextureMetadata.h"

#import "LTGLTexture.h"
#import "LTJSONSerializationAdapter.h"
#import "LTTexture+Factory.h"
#import "LTTexture+Protected.h"
#import "LTTransformers.h"

NS_ASSUME_NONNULL_BEGIN

@interface LTTextureMetadata ()

/// @see \c LTTexture.size.
@property (readwrite, nonatomic) CGSize size;

/// @see \c LTTexture.format.
@property (readwrite, nonatomic) LTTextureFormat format;

/// @see \c LTTexture.precision.
@property (readwrite, nonatomic) LTTexturePrecision precision;

/// @see \c LTTexture.maxMipmapLevel.
@property (readwrite, nonatomic) GLint maxMipmapLevel;

/// @see \c LTTexture.usingAlphaChannel.
@property (readwrite, nonatomic) BOOL usingAlphaChannel;

/// @see \c LTTexture.minFilterInterpolation.
@property (readwrite, nonatomic) LTTextureInterpolation minFilterInterpolation;

/// @see \c LTTexture.magFilterInterpolation.
@property (readwrite, nonatomic) LTTextureInterpolation magFilterInterpolation;

/// @see \c LTTexture.wrap.
@property (readwrite, nonatomic) LTTextureWrap wrap;

/// @see \c LTTexture.generationID.
@property (readwrite, nonatomic) NSString *generationID;

/// @see \c LTTexture.fillColor.
@property (readwrite, nonatomic) LTVector4 fillColor;

@end

#pragma mark -
#pragma mark LTTextureMetadata
#pragma mark -

@implementation LTTextureMetadata

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
  return @{};
}

+ (NSValueTransformer *)sizeJSONTransformer {
  return [MTLValueTransformer reversibleTransformerWithForwardBlock:^NSValue *(id string) {
    return [string isKindOfClass:[NSString class]] ? $((CGSize)LTVector2FromString(string)) : nil;
  } reverseBlock:^NSString *(NSValue *value) {
    return NSStringFromLTVector2(LTVector2([value CGSizeValue]));
  }];
}

+ (NSValueTransformer *)fillColorJSONTransformer {
  return [LTTransformers transformerForTypeEncoding:@(@encode(LTVector4))];
}

@end

#pragma mark -
#pragma mark LTTexture (LTTextureMetadata)
#pragma mark -

@implementation LTTexture (LTTextureMetadata)

+ (instancetype)textureWithMetadata:(LTTextureMetadata *)metadata {
  LTParameterAssert(metadata);
  LTTexture *texture;
  if (metadata.maxMipmapLevel) {
    texture = [[LTGLTexture alloc]
               initWithSize:metadata.size precision:metadata.precision
               format:metadata.format maxMipmapLevel:metadata.maxMipmapLevel];
  } else {
    texture = [LTTexture textureWithSize:metadata.size precision:metadata.precision
                                  format:metadata.format allocateMemory:YES];
  }

  texture.usingAlphaChannel = metadata.usingAlphaChannel;
  texture.minFilterInterpolation = metadata.minFilterInterpolation;
  texture.magFilterInterpolation = metadata.magFilterInterpolation;
  texture.wrap = metadata.wrap;

  return texture;
}

- (LTTextureMetadata *)metadata {
  LTTextureMetadata *metadata = [[LTTextureMetadata alloc] init];

  metadata.size = self.size;
  metadata.format = self.format;
  metadata.precision = self.precision;
  metadata.maxMipmapLevel = self.maxMipmapLevel;
  metadata.usingAlphaChannel = self.usingAlphaChannel;

  metadata.minFilterInterpolation = self.minFilterInterpolation;
  metadata.magFilterInterpolation = self.magFilterInterpolation;
  metadata.wrap = self.wrap;

  metadata.generationID = self.generationID;
  metadata.fillColor = self.fillColor;

  return metadata;
}

@end

NS_ASSUME_NONNULL_END
