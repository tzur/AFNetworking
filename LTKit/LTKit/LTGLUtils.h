// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTLogger.h"

#import "LTGLException.h"

/// Checks if OpenGL is currently reporting an error. If errors are present, they are all popped and
/// logged as an error.
///
/// @param format the message format to raise if an error is present.
///
/// @return NO if OpenGL is currently reporting an error.
inline void LTGLCheck(NSString *format, ...) NS_FORMAT_FUNCTION(1, 2);

inline void LTGLCheck(NSString *format, ...) {
  GLenum error;
  NSMutableArray *errors = [NSMutableArray array];

  while ((error = glGetError()) != GL_NO_ERROR) {
    [errors addObject:@(error)];
  }
  
  if (errors.count) {
    va_list args;
    va_start(args, format);
    [LTGLException raiseWithGLErrors:errors format:format args:args];
    va_end(args);
  }
}

/// Debug macro for checking GL errors and reporting them. This is useful to avoid calling \c
/// glGetError() in production code, but maintain flexibility when debugging.
#ifdef DEBUG
#define LTGLCheckDbg(format, ...) LTGLCheck(format, ##__VA_ARGS__)
#else
#define LTGLCheckDbg(format, ...)
#endif
