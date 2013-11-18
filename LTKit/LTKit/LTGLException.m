// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTGLException.h"

#pragma mark -
#pragma mark Exception names
#pragma mark -

NSString * const kLTOpenGLRuntimeErrorException = @"OpenGL Runtime Error Exception";

NSString * const kLTShaderCreationFailedException = @"Shader Creation Failed Exception";
NSString * const kLTShaderCompilationFailedException = @"Shader Compilation Failed Exception";

NSString * const kLTProgramCreationFailedException = @"Program Creation Failed Exception";
NSString * const kLTProgramLinkFailedException = @"Program Link Failed Exception";

NSString * const kLTTextureUnsupportedFormatException =
    @"Texture Unsupported Format Exception";
NSString * const kLTTextureCreationFailedException = @"Texture Creation Failed Exception";

NSString * const kLTArrayBufferMappingFailedException = @"Array Buffer Mapping Failed Exception";
NSString * const kLTArrayBufferDisallowsStaticBufferUpdateException =
    @"Array Buffer Disallows Static Buffer Update Exception";

#pragma mark -
#pragma mark LTGLException
#pragma mark -

@implementation LTGLException

+ (void)raiseWithGLError:(GLenum)glError
                  format:(NSString *)format, ... NS_FORMAT_FUNCTION(2, 3) {
  va_list argList;
  va_start(argList, format);
  [[self class] raiseWithGLErrors:@[@(glError)] format:format args:argList];
  va_end(argList);
}

+ (void)raiseWithGLErrors:(NSArray *)glErrors
                   format:(NSString *)format, ... NS_FORMAT_FUNCTION(2, 3) {
  va_list argList;
  va_start(argList, format);
  [[self class] raiseWithGLErrors:glErrors format:format args:argList];
  va_end(argList);
}

+ (void)raiseWithGLErrors:(NSArray *)glErrors
                   format:(NSString *)format args:(va_list)args NS_FORMAT_FUNCTION(2, 0) {
  NSString *errorString = [glErrors componentsJoinedByString:@", "];

  [NSException raise:kLTOpenGLRuntimeErrorException
              format:[NSString stringWithFormat:@"[OpenGL Error %@] %@", errorString, format]
           arguments:args];
}

@end
