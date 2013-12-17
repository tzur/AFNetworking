// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTLogger.h"

#pragma mark -
#pragma mark Interface
#pragma mark -

// Borrowed from http://www.mikeash.com/pyblog/friday-qa-2013-05-03-proper-use-of-asserts.html

/// Asserts that the given expression or parameter is true. If \c LT_ABORT_ON_ASSERTIONS is defined,
/// the program will \c abort() on assertion failure. Otherwise, an exception will be thrown, named
/// \c NSInternalInconsistencyException for \c LTAssert and \c NSInvalidArgumentException for \c
/// LTParameterAssert.

#ifdef LT_ABORT_ON_ASSERTIONS
#define LTAssert(expression, ...) _LTAssertAbort(expression, __VA_ARGS__)
#define LTParameterAssert(expression, ...) _LTParameterAssertAbort(expression, __VA_ARGS__)
#else
#define LTAssert(expression, ...) _LTAssertRaise(expression, __VA_ARGS__)
#define LTParameterAssert(expression, ...) _LTParameterAssertRaise(expression, __VA_ARGS__)
#endif

#pragma mark -
#pragma mark Implementation
#pragma mark -

#define _LTAssertAbort(expression, ...) \
  _LTAssertAndAbort(expression, @"Assertion failure: %s in %s on line %s:%d. %@", __VA_ARGS__)

#define _LTAssertRaise(expression, ...) \
  _LTAssertAndRaise(expression, @"Assertion failure: %s in %s on line %s:%d. %@", \
      NSInternalInconsistencyException, __VA_ARGS__)

#define _LTParameterAssertAbort(expression, ...) \
 _LTAssertAndAbort(expression, @"Parameter assertion failure: %s in %s on line %s:%d. %@", \
      __VA_ARGS__)

#define _LTParameterAssertRaise(expression, ...) \
  _LTAssertAndRaise(expression, @"Parameter assertion failure: %s in %s on line %s:%d. %@", \
      NSInvalidArgumentException, __VA_ARGS__)

#define _LTAssertMessage(EXPRESSION, MESSAGE, ...) \
  [NSString stringWithFormat:MESSAGE, #EXPRESSION, __func__, __FILE__, __LINE__, \
      [NSString stringWithFormat:@"" __VA_ARGS__]]

#define _LTAssertAndAbort(EXPRESSION, MESSAGE, ...) \
  do { \
    _LTAssertAndDo(EXPRESSION, _LTAssertMessage(EXPRESSION, MESSAGE, __VA_ARGS__), abort()); \
  } while (0)

#define _LTAssertAndRaise(EXPRESSION, MESSAGE, EXCEPTION, ...) \
  do { \
    _LTAssertAndDo(EXPRESSION, _LTAssertMessage(EXPRESSION, MESSAGE, __VA_ARGS__), \
        [[[NSException alloc] initWithName:EXCEPTION \
        reason:_LTAssertMessage(EXPRESSION, MESSAGE, __VA_ARGS__) userInfo:nil] raise]); \
  } while (0)

#define _LTAssertAndDo(EXPRESSION, MESSAGE, EXECUTE_AFTER) \
  do { \
    if (!(EXPRESSION)) { \
      [[LTLogger sharedLogger] logWithFormat:@"%@" file:__FILE__ line:__LINE__ \
          logLevel:LTLogLevelError, MESSAGE]; \
      (EXECUTE_AFTER); \
      __builtin_unreachable(); \
    } \
  } while(0)
