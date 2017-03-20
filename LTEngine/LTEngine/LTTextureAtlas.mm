// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Gluzman.

#import "LTTextureAtlas.h"

#import "LTTexture.h"

NS_ASSUME_NONNULL_BEGIN

@implementation LTTextureAtlas

- (instancetype)initWithAtlasTexture:(LTTexture *)texture
                          imageAreas:(const lt::unordered_map<NSString *, CGRect> &)areas {
  LTParameterAssert(texture);
  LTParameterAssert(areas.size(), @"areas dictionary cannot be empty");

  [LTTextureAtlas assertAreas:areas areInsideTexture:texture];

  if (self = [super init]) {
    _texture = texture;
    _areas = areas;
  }

  return self;
}

+ (void)assertAreas:(const lt::unordered_map<NSString *, CGRect> &)areas
   areInsideTexture:(LTTexture *)texture {
  CGRect textureRect = CGRectFromSize(texture.size);

  for (const auto &keyValue : areas) {
    NSString *key = keyValue.first;
    CGRect areaRect = keyValue.second;

    LTParameterAssert(areaRect.size.width > 0 && areaRect.size.height > 0, @"Area rects must have "
                      "positive widths and heights but rect size of image identifier %@ is %@",
                      key, NSStringFromCGSize(areaRect.size));
    LTParameterAssert(CGRectContainsRect(textureRect, areaRect), @"Area rect of image identifier "
                      "%@: %@ is out of the input texture size bounds: %@",
                      key, NSStringFromCGRect(areaRect), NSStringFromCGSize(texture.size));
  }
}

@end

NS_ASSUME_NONNULL_END
