// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Shachar Langbeheim.

#import "LTTextureRepository.h"

#import <LTKit/NSArray+Functional.h>

#import "LTTexture.h"

NS_ASSUME_NONNULL_BEGIN

@interface  LTTextureRepository ()

/// Weak pointer array of all added textures.
@property (readonly, nonatomic) NSPointerArray *textureArray;

@end

@implementation LTTextureRepository

- (instancetype)init {
  if (self = [super init]) {
    _textureArray = [NSPointerArray weakObjectsPointerArray];
  }
  return self;
}

- (void)addTexture:(LTTexture *)texture {
  for (LTTexture *internalTexture in self.textureArray) {
    if (internalTexture == texture) {
      return;
    }
  }
  [self.textureArray addPointer:(void *)texture];
}

- (nullable LTTexture *)textureWithGenerationID:(NSString *)generationID {
  [self.textureArray compact];

  for (LTTexture *texture in self.textureArray) {
    if ([texture.generationID isEqualToString:generationID]) {
      return texture;
    }
  }
  return nil;
}

@end

NS_ASSUME_NONNULL_END
