// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTErrorCodesRegistry.h"
#import "LTMetaMacros.h"

#pragma mark -
#pragma mark Definition
#pragma mark -

/// Main macro for declaring error codes given a product ID and error codes related to that product.
#define _LTErrorCodesDeclare(PRODUCT_ID, SUBSYSTEM_ID, ...) \
  /* Define the enum itself. */ \
  NS_ENUM(NSInteger) { \
    metamacro_if_eq(1, metamacro_argcount(__VA_ARGS__)) \
      (_LTErrorCodesDeclareOne(PRODUCT_ID, SUBSYSTEM_ID, __VA_ARGS__)) \
      (_LTErrorCodesDeclareMany(PRODUCT_ID, SUBSYSTEM_ID, __VA_ARGS__)) \
  }; \
  /* Define traits struct. */ \
  _LTErrorCodesTraitsStruct(PRODUCT_ID, SUBSYSTEM_ID, __VA_ARGS__)

#define _LTErrorCodesSubsystemMask \
    ((1 << (LTErrorCodeOffsetProductID - LTErrorCodeOffsetSubsystemID)) - 1)

#define _LTErrorCodeGenerate(PRODUCT_ID, SUBSYSTEM_ID) \
  ((PRODUCT_ID) << LTErrorCodeOffsetProductID | \
      ((SUBSYSTEM_ID & _LTErrorCodesSubsystemMask) << LTErrorCodeOffsetSubsystemID))

#define _LTErrorCodesDeclareOne(PRODUCT_ID, SUBSYSTEM_ID, ERROR_CODE) \
  ERROR_CODE = _LTErrorCodeGenerate(PRODUCT_ID, SUBSYSTEM_ID)

#define _LTErrorCodesDeclareMany(PRODUCT_ID, SUBSYSTEM_ID, ...) \
  metamacro_head(__VA_ARGS__) = _LTErrorCodeGenerate(PRODUCT_ID, SUBSYSTEM_ID), \
  metamacro_foreach(_LTErrorCodeEnumField,, metamacro_tail(__VA_ARGS__)) \

/// Callback to define an enum field with an ending comma.
#define _LTErrorCodeEnumField(INDEX, ARG) \
  ARG,

/// Defines a traits struct used to verify that the declaration and implementation are similar.
#ifdef __cplusplus
  #define _LTErrorCodesTraitsStruct(PRODUCT_ID, SUBSYSTEM_ID, ...) \
    struct __## PRODUCT_ID ## _## SUBSYSTEM_ID { \
      metamacro_foreach(_LTErrorCodesTraitsStuctField,, __VA_ARGS__) \
      static const int fieldCount = metamacro_argcount(__VA_ARGS__); \
    }
#else
  #define _LTErrorCodesTraitsStruct(PRODUCT_ID, SUBSYSTEM_ID, ...)
#endif

/// Callback to define a single enum field with a value in the traits struct.
#define _LTErrorCodesTraitsStuctField(INDEX, ARG) \
  static const int _##ARG = INDEX;

#pragma mark -
#pragma mark Implementation
#pragma mark -

/// Main macro for implementing error codes given a product ID and error codes related to that
/// product.
#define _LTErrorCodesImplement(PRODUCT_ID, SUBSYSTEM_ID, ...) \
  /* Define a function that will register the codes. */ \
  __attribute__((constructor)) static void metamacro_concat(__registerErrorCodes, __LINE__)() { \
    @autoreleasepool { \
      [[LTErrorCodesRegistry sharedRegistry] registerErrorCodes:@{ \
        metamacro_foreach(_LTErrorCodesToDescription,, __VA_ARGS__) \
      }]; \
    } \
  } \
  /* Verify the declaration in the header file. */ \
  _LTErrorCodesVerifyDeclaration(PRODUCT_ID, SUBSYSTEM_ID, __VA_ARGS__) \
  /* Define dummy class so that the constructor function will not be stripped. */ \
  _LTErrorCodesDummyClass(PRODUCT_ID, SUBSYSTEM_ID)

/// Defines a method which does nothing but to statically verify that the declaration and
/// implementation are similar.
#ifdef __cplusplus
  #define _LTErrorCodesVerifyDeclaration(PRODUCT_ID, SUBSYSTEM_ID, ...) \
    __unused static void metamacro_concat(__verifyErrorCodesDeclaration, __LINE__)() { \
      static_assert(__##PRODUCT_ID##_##SUBSYSTEM_ID::fieldCount == \
        metamacro_argcount(__VA_ARGS__), "Field count doesn't match for errors codes for product " \
            "ID " #PRODUCT_ID ", subsystem ID " #SUBSYSTEM_ID); \
        metamacro_foreach_cxt(_LTErrorCodesVerifyField,, __##PRODUCT_ID##_##SUBSYSTEM_ID, \
            __VA_ARGS__) \
    }

  /// Callback to define a validation for a single enum field with its value.
  #define _LTErrorCodesVerifyField(VALUE, STRUCT, ARG) \
    static_assert(STRUCT::_##ARG == VALUE, "Error code " #ARG " doesn't match declaration");
#else
  #define _LTErrorCodesVerifyDeclaration(PRODUCT_ID, SUBSYSTEM_ID, ...)
#endif

/// Callback to define an enum field with an ending comma.
#define _LTErrorCodesToDescription(INDEX, ARG) \
  @(ARG): @#ARG,

/// Defines dummy class that will force the constuctor function not to be stripped.
#define _LTErrorCodesDummyClass(PRODUCT_ID, SUBSYSTEM_ID) \
  @interface __LTErrorCodesRegistrar##PRODUCT_ID##_##SUBSYSTEM_ID : NSObject \
  @end \
  \
  @implementation __LTErrorCodesRegistrar##PRODUCT_ID##_##SUBSYSTEM_ID \
  @end
