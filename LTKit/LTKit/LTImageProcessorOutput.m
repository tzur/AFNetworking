// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTImageProcessorOutput.h"

#pragma mark -
#pragma mark LTSingleTextureOutput
#pragma mark -

@interface LTSingleTextureOutput ()
@property (readwrite, nonatomic) LTTexture *texture;
@end

@implementation LTSingleTextureOutput

- (instancetype)initWithTexture:(LTTexture *)texture {
  if (self = [super init]) {
    self.texture = texture;
  }
  return self;
}

@end

#pragma mark -
#pragma mark LTMultipleTextureOutput
#pragma mark -

@interface LTMultipleTextureOutput ()
@property (readwrite, nonatomic) NSArray *textures;
@end

@implementation LTMultipleTextureOutput

- (instancetype)initWithTextures:(NSArray *)textures {
  if (self = [super init]) {
    self.textures = textures;
  }
  return self;
}

@end
