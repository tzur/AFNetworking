// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTMetaMacros.h"

/// Avoid including this file directly. To use these macros, include \c LTEnumRegistry.h.

#pragma mark -
#pragma mark Interface
#pragma mark -

/// Creates an enum type using Apple's \c NS_ENUM macro. The first given parameter is
/// the enum underlying type, then its name. Enum fields follow. Example:
/// @code
/// LTEnumMake(NSUInteger, MyEnum,
///            MyEnumChoiceA,
///            MyEnumChoiceB,
///            MyEnumChoiceC);
/// @endcode
///
/// Enums are defined globally, even if their scope is limited. Avoid defining an enum with a
/// similar name twice.
#define LTEnumMake(TYPE, NAME, ...) \
  LTEnumDeclare(TYPE, NAME, __VA_ARGS__); \
  LTEnumImplement(TYPE, NAME, __VA_ARGS__)

/// Creates an enum type using Apple's \c NS_ENUM macro. The first given parameter is
/// the enum underlying type, then its name. Enum fields follow as pairs of (name, value). Example:
/// @code
/// LTEnumMake(NSUInteger, MyEnum,
///            MyEnumChoiceA, 1,
///            MyEnumChoiceB, 3,
///            MyEnumChoiceC, 5);
/// @endcode
///
/// Enums are defined globally, even if their scope is limited. Avoid defining an enum with a
/// similar name twice.
#define LTEnumMakeWithValues(TYPE, NAME, ...) \
  LTEnumDeclareWithValues(TYPE, NAME, __VA_ARGS__); \
  LTEnumImplementWithValues(TYPE, NAME, __VA_ARGS__)

#define LTEnumDeclare(TYPE, NAME, ...) \
  /* Define the enum itself. */ \
  typedef NS_ENUM(TYPE, NAME) { \
    metamacro_foreach(_LTEnumField,, __VA_ARGS__) \
  }; \
  \
  /* Create NSValue+NAMEValue category. */ \
  _LTEnumDeclareNSValueCategory(TYPE, NAME); \
  \
  /* Define traits struct. */ \
  _LTDefineTraitsStruct(NAME, __VA_ARGS__)

#define LTEnumDeclareWithValues(TYPE, NAME, ...) \
  /* Define the enum itself. */ \
  typedef NS_ENUM(TYPE, NAME) { \
    metamacro_foreach2(_LTEnumFieldWithValue,, _LTNull, __VA_ARGS__) \
  }; \
  \
  /* Create NSValue+NAMEValue category. */ \
  _LTEnumDeclareNSValueCategory(TYPE, NAME); \
  \
  /* Define traits struct. */ \
  _LTDefineTraitsStructWithValues(NAME, __VA_ARGS__)

#define LTEnumImplement(TYPE, NAME, ...) \
  /* Verify the implementation matches the definition. */ \
  _LTVerifyImplementation(NAME, __VA_ARGS__); \
  \
  /* Register the enum with LTEnumRegistry. */ \
  _LTEnumRegister(NAME, __VA_ARGS__) \
  \
  /* Create NSValue+NAMEValue category. */ \
  _LTEnumImplementNSValueCategory(TYPE, NAME)

#define LTEnumImplementWithValues(TYPE, NAME, ...) \
  /* Verify the implementation matches the definition. */ \
  _LTVerifyImplementationWithValues(NAME, __VA_ARGS__); \
  \
  /* Register the enum with LTEnumRegistry. */ \
  _LTEnumRegisterWithValues(NAME, __VA_ARGS__) \
  \
  /* Create NSValue+NAMEValue category. */ \
  _LTEnumImplementNSValueCategory(TYPE, NAME)

#pragma mark -
#pragma mark Implementation
#pragma mark -

/// Registers the enum with \c LTEnumRegistry on image load.
#define _LTEnumRegister(NAME, ...) \
  __attribute__((constructor)) static void __register##NAME() { \
    [[LTEnumRegistry sharedInstance] \
        registerEnumName:@#NAME \
        withFieldToValue:@{metamacro_foreach(_LTEnumDictionaryField,, __VA_ARGS__)}]; \
  }

/// Registers the enum with \c LTEnumRegistry on image load.
#define _LTEnumRegisterWithValues(NAME, ...) \
  __attribute__((constructor)) static void __register##NAME() { \
    [[LTEnumRegistry sharedInstance] \
        registerEnumName:@#NAME \
        withFieldToValue:@{metamacro_foreach2(_LTEnumDictionaryFieldWithValue,, \
                                              _LTNull, __VA_ARGS__)}]; \
  }

/// Defines NSValue category with boxing / unboxing methods.
#define _LTEnumDeclareNSValueCategory(TYPE, NAME) \
  @interface NSValue (_ ## NAME) \
  \
  - (NAME)NAME ## Value; \
  \
  + (NSValue *)valueWith ## NAME:(NAME)value; \
  \
  @end

/// Implements NSValue category with boxing / unboxing methods.
#define _LTEnumImplementNSValueCategory(TYPE, NAME) \
  @implementation NSValue (_ ## NAME) \
  \
  - (NAME)NAME ## Value { \
    NAME value; \
    [self getValue:&value]; \
    return value; \
  } \
  \
  + (NSValue *)valueWith ## NAME:(NAME)value { \
    return [NSValue valueWithBytes:&value objCType:@encode(NAME)]; \
  } \
  \
  @end

/// Defines a traits struct used to verify that the declaration and implementation are similar.
#define _LTDefineTraitsStruct(NAME, ...) \
  struct _## NAME { \
    metamacro_foreach(_LTEnumTraitsStuctField,, __VA_ARGS__) \
    static const int fieldCount = metamacro_argcount(__VA_ARGS__); \
  };

/// Defines a traits struct with given field values used to verify that the declaration and
/// implementation are similar.
#define _LTDefineTraitsStructWithValues(NAME, ...) \
  struct _## NAME { \
    metamacro_foreach2(_LTEnumTraitsStuctFieldAndValue,, _LTNull, __VA_ARGS__) \
    static const int fieldCount = metamacro_argcount(__VA_ARGS__); \
  };

/// Defines a method which does nothing but to statically verify that the declaration and
/// implementation are similar.
#define _LTVerifyImplementation(NAME, ...) \
  __unused static void __verify##NAME() { \
    static_assert(_##NAME::fieldCount == metamacro_argcount(__VA_ARGS__), \
                  "Field count doesn't match for enum " #NAME); \
    metamacro_foreach_cxt(_LTEnumVerifyField,, NAME, __VA_ARGS__) \
  }

/// Defines a method which does nothing but to statically verify that the declaration and
/// implementation are similar.
#define _LTVerifyImplementationWithValues(NAME, ...) \
  __unused static void __verify##NAME() { \
    static_assert(_##NAME::fieldCount == metamacro_argcount(__VA_ARGS__), \
                  "Field count doesn't match for enum " #NAME); \
    metamacro_foreach2(_LTEnumVerifyFieldWithValue, NAME, _LTNull, __VA_ARGS__) \
  }

/// Callback to define an enum field with an ending comma.
#define _LTEnumField(INDEX, ARG) \
  _LTEnumFieldWithValue(, ARG, INDEX)

/// Callback to define an enum field with a given value and an ending comma.
#define _LTEnumFieldWithValue(CONTEXT, ARG, VALUE) \
  ARG = VALUE,

/// Callback to define a dictionary field with \c ARG as \c NSString and INDEX as \c NSNumber.
#define _LTEnumDictionaryField(INDEX, ARG) \
  _LTEnumDictionaryFieldWithValue(, ARG, INDEX)

/// Callback to define a dictionary field with \c ARG as \c NSString and INDEX as \c NSNumber.
#define _LTEnumDictionaryFieldWithValue(CONTEXT, ARG, VALUE) \
  @#ARG: @(VALUE),

/// Callback to define a single enum field in the traits struct.
#define _LTEnumTraitsStuctField(INDEX, ARG) \
  _LTEnumTraitsStuctFieldAndValue(, ARG, INDEX)

/// Callback to define a single enum field with a value in the traits struct.
#define _LTEnumTraitsStuctFieldAndValue(CONTEXT, ARG, VALUE) \
  static const int ARG = VALUE;

/// Callback to define a validation for a single enum field.
#define _LTEnumVerifyField(INDEX, NAME, ARG) \
  _LTEnumVerifyFieldWithValue(NAME, ARG, INDEX)

/// Callback to define a validation for a single enum field with its value.
#define _LTEnumVerifyFieldWithValue(NAME, ARG, VALUE) \
  static_assert(_##NAME::ARG == VALUE, "Enum field " #ARG " with value " #VALUE " doesn't " \
                "match declaration");
