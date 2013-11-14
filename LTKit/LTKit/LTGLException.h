// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#pragma mark -
#pragma mark Exception names
#pragma mark -

// LTShader.
extern NSString * const kLTShaderCreationFailedException;
extern NSString * const kLTShaderCompilationFailedException;

// LTProgram.
extern NSString * const kLTProgramCreationFailedException;
extern NSString * const kLTProgramLinkFailedException;

// LTTexture.
extern NSString * const kLTTextureInvalidNumberOfChannelsException;
extern NSString * const kLTTextureInvalidDepthException;
extern NSString * const kLTTextureCreationFailedException;

#pragma mark -
#pragma mark LTGLException
#pragma mark -

/// Exception class for OpenGL errors.
@interface LTGLException : NSException

/// Raises \c LTGLException with the causing glError and a format string.
+ (void)raise:(NSString *)name GLError:(GLuint)glError
       format:(NSString *)format, ... NS_FORMAT_FUNCTION(3,4);

@end
