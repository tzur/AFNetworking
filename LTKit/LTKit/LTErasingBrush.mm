// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTErasingBrush.h"

#import "LTProgram.h"
#import "LTShaderStorage+LTBrushVsh.h"
#import "LTShaderStorage+LTErasingBrushFsh.h"

@implementation LTErasingBrush

- (LTProgram *)createProgram {
  return [[LTProgram alloc] initWithVertexSource:[LTBrushVsh source]
                                  fragmentSource:[LTErasingBrushFsh source]];
}

@end
