// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTBoxFilterProcessor.h"

#import "LTProgram.h"
#import "LTShaderStorage+LTBoxFilterVsh.h"
#import "LTShaderStorage+LTBoxFilterFsh.h"
#import "LTTexture.h"

@implementation LTBoxFilterProcessor

- (instancetype)initWithInput:(LTTexture *)input outputs:(NSArray *)outputs {
  return [super initWithProgram:[self createProgram] sourceTexture:input outputs:outputs];
}

- (LTProgram *)createProgram {
  return [[LTProgram alloc] initWithVertexSource:[LTBoxFilterVsh source]
                                  fragmentSource:[LTBoxFilterFsh source]];
}

@end
