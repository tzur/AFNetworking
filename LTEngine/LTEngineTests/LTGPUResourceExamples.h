// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

/// OpenGL function that returns \c true if the given \c name is a valid OpenGL resource of the kind
/// that is treated by this function.
typedef GLboolean (*LTGLIsResource)(GLuint name);

/// Resource examples shared group name.
extern NSString * const kLTResourceExamples;

/// The resource subject under test as an \c NSValue. Must implement the LTGPUResource protocol.
extern NSString * const kLTResourceExamplesSUTValue;

/// \c GLenum value of the OpenGL parameter name to query the bound resource.
extern NSString * const kLTResourceExamplesOpenGLParameterName;

/// Pointer to an OpenGL function that checks whether an input name is a valid resource, such as
/// \c glIsFramebuffer.
extern NSString * const kLTResourceExamplesIsResourceFunction;
