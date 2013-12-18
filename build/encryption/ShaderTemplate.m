// Copyright (c) @YEAR@ Lightricks. All rights reserved.
// Created by @SCRIPT_NAME@.

#import "LTShaderStorage.h"

@BUFFER@

@interface @CONTAINER_CLASS_NAME@ ()

+ (NSString *)shaderWithBuffer:(void *)buffer ofLength:(NSUInteger)length;

@end

@implementation @CONTAINER_CLASS_NAME@ (@SHADER_OBJC_NAME@)

@GETTER_IMPLEMENTATION@

@end
