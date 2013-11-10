// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTGLException.h"

#pragma mark -
#pragma mark Exception names
#pragma mark -

NSString * const kLTShaderCreationFailedException = @"Shader Creation Failed Exception";
NSString * const kLTShaderCompilationFailedException = @"Shader Compilation Failed Exception";
NSString * const kLTProgramCreationFailedException = @"Program Creation Failed Exception";
NSString * const kLTProgramUniformNotFoundException = @"Program Uniform Not Found Exception";
NSString * const kLTProgramLinkFailedException = @"Program Link Failed Exception";

#pragma mark -
#pragma mark LTGLException
#pragma mark -

@implementation LTGLException

+ (void)raise:(NSString *)name GLError:(GLuint)glError
       format:(NSString *)format, ... NS_FORMAT_FUNCTION(3,4) {
  va_list argList;
  va_start(argList, format);
  [NSException raise:name
              format:[NSString stringWithFormat:@"[OpenGL Error %d] %@", glError, format]
           arguments:argList];
  va_end(argList);
}

@end
