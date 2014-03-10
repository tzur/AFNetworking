// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTErasingBrush.h"

#import "LTProgram.h"
#import "LTShaderStorage+LTBrushShaderVsh.h"
#import "LTShaderStorage+LTErasingBrushShaderFsh.h"

@implementation LTErasingBrush

- (LTProgram *)createProgram {
  return [[LTProgram alloc] initWithVertexSource:[LTBrushShaderVsh source]
                                  fragmentSource:[LTErasingBrushShaderFsh source]];
}

@end
