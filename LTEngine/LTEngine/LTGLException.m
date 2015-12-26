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

NSString * const kLTTextureCreationFailedException = @"Texture Creation Failed Exception";

NSString * const kLTMMTextureBufferLockingFailedException =
    @"Texture Buffer Locking Failed Exception";

NSString * const kLTArrayBufferMappingFailedException = @"Array Buffer Mapping Failed Exception";
NSString * const kLTArrayBufferDisallowsStaticBufferUpdateException =
    @"Array Buffer Disallows Static Buffer Update Exception";

NSString * const kLTFboInvalidTextureException = @"Fbo Invalid Texture Exception";
NSString * const kLTFboCreationFailedException = @"Fbo Creation Failed Exception";

NSString * const kLTGPUQueueContextCreationFailedException =
    @"GPU Queue Context Creation Failed Exception";
NSString * const kLTGPUQueueContextSetFailedException = @"GPU Queue Context Set Failed Exception";

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

#pragma mark -
#pragma mark NSError+LTGLException
#pragma mark -

NSString * const kNSErrorLTGLExceptionDomain = @"com.lightricks.LTKit.LTGLExceptionErrorDomain";

const NSInteger kNSErrorLTGLExceptionCode = 0;

NSString * const kNSErrorLTGLExceptionNameKey = @"Exception Name";
NSString * const kNSErrorLTGLExceptionReasonKey = @"Exception Reason";

@implementation NSError (LTGLException)

+ (instancetype)lt_errorWithLTGLException:(LTGLException *)exception {
  return [NSError errorWithDomain:kNSErrorLTGLExceptionDomain
                             code:kNSErrorLTGLExceptionCode
                         userInfo:@{kNSErrorLTGLExceptionNameKey: exception.name,
                                    kNSErrorLTGLExceptionReasonKey: exception.reason}];
}

@end
