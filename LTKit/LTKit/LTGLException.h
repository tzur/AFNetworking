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
extern NSString * const kLTTextureUnsupportedFormatException;
extern NSString * const kLTTextureCreationFailedException;

// LTBuffer.
extern NSString * const kLTArrayBufferMappingFailedException;
extern NSString * const kLTArrayBufferDisallowsStaticBufferUpdateException;

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
