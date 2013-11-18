// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTLogger.h"

// Borrowed from http://www.mikeash.com/pyblog/friday-qa-2013-05-03-proper-use-of-asserts.html

/// Asserts that the given expression is true. On debug, this behaves similar to \c NSAssert. On
/// release, if the condition is false, an error is logged and the program is aborted.
#ifdef DEBUG
#define LTAssert(expression, ...) NSAssert(expression, __VA_ARGS__)
#else
#define LTAssert(expression, ...) \
  do { \
    if (!(expression)) { \
      NSString *__LTAssert_message = \
          [NSString stringWithFormat:@"Assertion failure: %s in %s on line %s:%d. %@", \
          #expression, __func__, __FILE__, __LINE__, [NSString stringWithFormat:@"" __VA_ARGS__]]; \
      [[LTLogger sharedLogger] logWithFormat:@"%@" file:__FILE__ line:__LINE__ \
          logLevel:LTLogLevelError, __LTAssert_message]; \
      abort(); \
    } \
  } while(0)
#endif
