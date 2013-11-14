// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTLogger.h"

/// Checks if OpenGL is currently reporting an error. If errors are present, they are all popped and
/// logged as an error.
///
/// @param message the message to print if an error is present.
///
/// @return NO if OpenGL is currently reporting an error.
inline BOOL LTGLCheck(NSString *message) {
  BOOL errorFound = NO;
  GLenum error;

  while ((error = glGetError()) != GL_NO_ERROR) {
    errorFound = YES;
    LogError(@"[OpenGL Error: %d]: %@", error, message);
  }
  
  return !errorFound;
}

#ifdef DEBUG
/// Executes the given expression and aborts the program if an OpenGL error is present. In non-debug
/// builds, the expression is executed but no \c abort() is made.
#define LTGLCheckExprDbg(expression, message) \
  do { \
    (expression); \
    if (!LTGLCheck(message)) { \
      abort(); \
    } \
  } while (0)
#else
#define LTGLCheckExprDbg(expression, message) (expression)
#endif
