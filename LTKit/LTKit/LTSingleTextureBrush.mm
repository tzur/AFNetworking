// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTSingleTextureBrush.h"

@implementation LTSingleTextureBrush

@dynamic texture;

#pragma mark -
#pragma mark For Testing
#pragma mark -

- (void)setSingleTexture:(LTTexture *)texture {
  self.texture = texture;
}

@end
