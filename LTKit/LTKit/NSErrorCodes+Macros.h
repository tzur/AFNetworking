// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTErrorCodesRegistry.h"
#import "LTMetaMacros.h"

#pragma mark -
#pragma mark Definition
#pragma mark -

/// Main macro for declaring error codes given a product ID and error codes related to that product.
#define _LTErrorCodesDeclare(PRODUCT_ID, ...) \
  /* Define the enum itself. */ \
  NS_ENUM(NSInteger) { \
    metamacro_if_eq(1, metamacro_argcount(__VA_ARGS__)) \
      (_LTErrorCodesDeclareOne(PRODUCT_ID, __VA_ARGS__)) \
      (_LTErrorCodesDeclareMany(PRODUCT_ID, __VA_ARGS__)) \
  }; \
  /* Define traits struct. */ \
  _LTErrorCodesTraitsStruct(PRODUCT_ID, __VA_ARGS__)

#define _LTErrorCodesDeclareOne(PRODUCT_ID, ERROR_CODE) \
  ERROR_CODE = (PRODUCT_ID) << LTErrorCodeBaseOffset

#define _LTErrorCodesDeclareMany(PRODUCT_ID, ...) \
  metamacro_head(__VA_ARGS__) = (PRODUCT_ID) << LTErrorCodeBaseOffset, \
  metamacro_foreach(_LTErrorCodeEnumField,, metamacro_tail(__VA_ARGS__)) \

/// Callback to define an enum field with an ending comma.
#define _LTErrorCodeEnumField(INDEX, ARG) \
  ARG,

/// Defines a traits struct used to verify that the declaration and implementation are similar.
#ifdef __cplusplus
  #define _LTErrorCodesTraitsStruct(PRODUCT_ID, ...) \
    struct __## PRODUCT_ID { \
      metamacro_foreach(_LTErrorCodesTraitsStuctField,, __VA_ARGS__) \
      static const int fieldCount = metamacro_argcount(__VA_ARGS__); \
    }
#else
  #define _LTErrorCodesTraitsStruct(PRODUCT_ID, ...)
#endif

/// Callback to define a single enum field with a value in the traits struct.
#define _LTErrorCodesTraitsStuctField(INDEX, ARG) \
  static const int _##ARG = INDEX;

#pragma mark -
#pragma mark Implementation
#pragma mark -

/// Main macro for implementing error codes given a product ID and error codes related to that
/// product.
#define _LTErrorCodesImplement(PRODUCT_ID, ...) \
  /* Define a function that will register the codes. */ \
  __attribute__((constructor)) static void __registerErrorCodes() { \
    [[LTErrorCodesRegistry sharedRegistry] registerErrorCodes:@{ \
      metamacro_foreach(_LTErrorCodesToDescription,, __VA_ARGS__) \
    }]; \
  } \
  /* Verify the declaration in the header file. */ \
  _LTErrorCodesVerifyDeclaration(PRODUCT_ID, __VA_ARGS__) \
  /* Define dummy class so that the constructor function will not be stripped. */ \
  _LTErrorCodesDummyClass(PRODUCT_ID)

/// Defines a method which does nothing but to statically verify that the declaration and
/// implementation are similar.
#ifdef __cplusplus
  #define _LTErrorCodesVerifyDeclaration(PRODUCT_ID, ...) \
    __unused static void __verify##PRODUCT_ID() { \
      static_assert(__##PRODUCT_ID::fieldCount == metamacro_argcount(__VA_ARGS__), \
                    "Field count doesn't match for errors codes for product ID " #PRODUCT_ID); \
      metamacro_foreach_cxt(_LTErrorCodesVerifyField,, PRODUCT_ID, __VA_ARGS__) \
    }
#else
  #define _LTErrorCodesVerifyDeclaration(PRODUCT_ID, ...)
#endif

/// Callback to define a validation for a single enum field with its value.
#define _LTErrorCodesVerifyField(VALUE, PRODUCT_ID, ARG) \
  static_assert(__##PRODUCT_ID::_##ARG == VALUE, "Error code " #ARG " doesn't match declaration");

/// Callback to define an enum field with an ending comma.
#define _LTErrorCodesToDescription(INDEX, ARG) \
  @(ARG): @#ARG,

/// Defines dummy class that will force the constuctor function not to be stripped.
#define _LTErrorCodesDummyClass(PRODUCT_ID) \
  @interface __LTErrorCodesRegistrar##PRODUCT_ID : NSObject \
  @end \
  \
  @implementation __LTErrorCodesRegistrar##PRODUCT_ID \
  @end
