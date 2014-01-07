// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTOneShotImageProcessor.h"

#import "LTFbo.h"
#import "LTRectDrawer.h"

@implementation LTOneShotImageProcessor

- (instancetype)initWithProgram:(LTProgram *)program inputs:(NSArray *)inputs
                        outputs:(NSArray *)outputs {
  LTParameterAssert(inputs.count == 1 && outputs.count == 1,
                    @"Inputs and outputs should contain a single texture");
  return [super initWithProgram:program inputs:inputs outputs:outputs];
}

- (LTSingleTextureOutput *)process {
  LTMultipleTextureOutput *output = [super process];
  return [[LTSingleTextureOutput alloc] initWithTexture:[output.textures firstObject]];
}

@end
