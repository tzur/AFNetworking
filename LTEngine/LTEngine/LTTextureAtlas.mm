// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Gluzman.

#import "LTTextureAtlas.h"

#import "LTTexture.h"

NS_ASSUME_NONNULL_BEGIN

@implementation LTTextureAtlas

- (instancetype)initWithAtlasTexture:(LTTexture *)texture
                          imageAreas:(NSDictionary<NSString *, NSValue *> *)areas {
  LTParameterAssert(texture);
  LTParameterAssert(areas.count, @"areas dictionary cannot be empty");
  
  [LTTextureAtlas assertAreas:areas areInsideTexture:texture];

  if (self = [super init]) {
    _texture = texture;
    _areas = areas;
  }

  return self;
}

+ (void)assertAreas:(NSDictionary<NSString *, NSValue *> *)areas
   areInsideTexture:(LTTexture *)texture {
  CGRect textureRect = CGRectFromSize(texture.size);

  [areas enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSValue *areaRectValue, BOOL *) {
    CGRect areaRect = [areaRectValue CGRectValue];
    LTParameterAssert(areaRect.size.width > 0 && areaRect.size.height > 0, @"Area rects must have "
                      "positive widths and heights but rect size of image identifier %@ is "
                      "(%g, %g)", key, areaRect.size.width, areaRect.size.height);
    LTParameterAssert(CGRectContainsRect(textureRect, areaRect), @"Area rect of image identifier "
                      "%@: (%g, %g, %g, %g) is out of the input texture size bounds: (%g, %g)",
                      key, areaRect.origin.x, areaRect.origin.y, areaRect.size.width,
                      areaRect.size.height, texture.size.width, texture.size.height);
  }];
}

@end

NS_ASSUME_NONNULL_END
