// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTEasyBoxing.h"

#ifdef __cplusplus

#pragma mark -
#pragma mark Declaration
#pragma mark -

/// Declares and implements a category over \c NSValue for \c STRUCT_NAME that allows boxing and
/// unboxing of the struct, and defines an easy boxing using the \c $ operator over the struct.
///
/// @important when boxing structs with \c NSValue, any Objective-C objects inside the struct will
/// be handled as \c __unsafe_unretained, so ARC will not change their reference count. Be very
/// cautious as this may lead to usage of dangling pointers after unboxing.
///
/// Example of declaration:
///
/// @code
/// typedef struct {
///   int a;
///   float b;
/// } MyStruct;
///
/// LTStructBoxingMake(MyStruct);
/// @endcode
///
/// And usage:
///
/// @code
/// MyStruct instance = {.a = 5, .b = 0.5};
///
/// // Box the struct.
/// NSValue *boxed = $(instance);
///
/// // Unbox it.
/// MyStruct unboxed = [boxed MyStructValue];
/// @endcode
#define LTStructBoxingMake(STRUCT_NAME) \
  LTStructBoxingDeclare(STRUCT_NAME); \
  LTStructBoxingImplement(STRUCT_NAME)

/// Declares a category over \c NSValue for \c STRUCT_NAME that allows boxing and unboxing of the
/// struct, and defines an easy boxing using the \c $ operator over the struct.
///
/// @important when boxing structs with \c NSValue, any Objective-C objects inside the struct will
/// be handled as \c __unsafe_unretained, so ARC will not change their reference count. Be very
/// cautious as this may lead to usage of dangling pointers after unboxing.
#define LTStructBoxingDeclare(STRUCT_NAME) \
  _LTStructBoxingDeclareNSValueCategory(STRUCT_NAME); \
  \
  LTMakeEasyBoxing(STRUCT_NAME);

/// Implements the \c NSValue category for \c STRUCT_NAME. This macro should be used in the
/// implementation file.
#define LTStructBoxingImplement(STRUCT_NAME) \
  _LTStructBoxingImplementNSValueCategory(STRUCT_NAME);

#pragma mark -
#pragma mark Implementation
#pragma mark -

#define _LTStructBoxingDeclareNSValueCategory(STRUCT_NAME) \
  @interface NSValue (STRUCT_NAME) \
  \
  /* Boxes STRUCT_NAME using an \c NSValue */ \
  + (NSValue *)valueWith ## STRUCT_NAME:(const STRUCT_NAME &)value; \
  \
  /* Returns the struct boxed with this given value. No validation that the value actually holds
     \c STRUCT_NAME is done. */ \
  - (STRUCT_NAME)STRUCT_NAME ## Value; \
  \
  @end

#define _LTStructBoxingImplementNSValueCategory(STRUCT_NAME) \
  @implementation NSValue (STRUCT_NAME) \
  \
  + (NSValue *)valueWith ## STRUCT_NAME:(const STRUCT_NAME &)value { \
    return [NSValue valueWithBytes:&value objCType:@encode(STRUCT_NAME)]; \
  } \
  \
  - (STRUCT_NAME)STRUCT_NAME ## Value { \
    STRUCT_NAME value; \
    [self getValue:&value]; \
    return value; \
  } \
  \
  @end

#endif
