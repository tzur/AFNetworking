// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTTextureBrush.h"

/// TextureBrush examples shared group name.
extern NSString * const kLTTextureBrushExamples;

/// Class object, a subclass of the \c LTTextureBrush class to test.
extern NSString * const kLTTextureBrushClass;

@interface LTTextureBrush (ForTesting)

/// Sets a single texture as the texture used for painting.
- (void)setSingleTexture:(LTTexture *)texture;

@end
