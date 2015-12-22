// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#pragma mark -
#pragma mark Exception names
#pragma mark -

// OpenGL.
extern NSString * const kLTOpenGLRuntimeErrorException;

// LTShader.
extern NSString * const kLTShaderCreationFailedException;
extern NSString * const kLTShaderCompilationFailedException;

// LTProgram.
extern NSString * const kLTProgramCreationFailedException;
extern NSString * const kLTProgramLinkFailedException;

// LTTexture.
extern NSString * const kLTTextureCreationFailedException;

// LTMMTexture.
extern NSString * const kLTMMTextureBufferLockingFailedException;

// LTArrayBuffer.
extern NSString * const kLTArrayBufferMappingFailedException;
extern NSString * const kLTArrayBufferDisallowsStaticBufferUpdateException;

// LTFbo.
extern NSString * const kLTFboInvalidTextureException;
extern NSString * const kLTFboCreationFailedException;

// LTGPUQueue.
extern NSString * const kLTGPUQueueContextCreationFailedException;
extern NSString * const kLTGPUQueueContextSetFailedException;

#pragma mark -
#pragma mark LTGLException
#pragma mark -

/// Exception class for OpenGL errors.
@interface LTGLException : NSException

/// Raises \c LTGLException with \c kLTOpenGLRuntimeErrorException.
///
/// @param glError the causing glError.
/// @param format the exception format string.
+ (void)raiseWithGLError:(GLenum)glError
                  format:(NSString *)format, ... NS_FORMAT_FUNCTION(2, 3);

/// Raises \c LTGLException with \c kLTOpenGLRuntimeErrorException.
///
/// @param glErrors an array of the causing glError(s) \c GLenum values.
/// @param format the exception format string.
+ (void)raiseWithGLErrors:(NSArray *)glError
                   format:(NSString *)format, ... NS_FORMAT_FUNCTION(2, 3);

/// Raises \c LTGLException with \c kLTOpenGLRuntimeErrorException.
///
/// @param glErrors an array of the causing glError(s) \c GLenum values.
/// @param format the exception format string.
+ (void)raiseWithGLErrors:(NSArray *)glErrors
                   format:(NSString *)format args:(va_list)args NS_FORMAT_FUNCTION(2, 0);

@end

#pragma mark -
#pragma mark NSError+LTGLException
#pragma mark -

/// Error domain when translating from \c LTGLException.
extern NSString * const kNSErrorLTGLExceptionDomain;

/// Code for \c NSError that was translated from \c LTGLException;
extern const NSInteger kNSErrorLTGLExceptionCode;

/// Error user info key which includes the name of the \c LTGLException.
extern NSString * const kNSErrorLTGLExceptionNameKey;

/// Error user info key which includes the reason of the \c LTGLException.
extern NSString * const kNSErrorLTGLExceptionReasonKey;

@interface NSError (LTGLException)

/// Builds an \c NSError which corresponds to the exception name and reason.
+ (instancetype)lt_errorWithLTGLException:(LTGLException *)exception;

@end
