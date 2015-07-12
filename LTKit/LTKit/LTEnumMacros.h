// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTMetaMacros.h"

#import "LTBidirectionalMap.h"
#import "LTEnum.h"

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
  typedef NS_ENUM(TYPE, _##NAME) { \
    metamacro_foreach(_LTEnumField,, __VA_ARGS__) \
  }; \
  \
  /* Create NSValue+NAMEValue category. */ \
  _LTEnumDeclareNSValueCategory(TYPE, NAME); \
  \
  /* Declare the Enum wrapper class. */ \
  _LTEnumDeclareClass(NAME); \
  \
  /* Defined easy boxing overloaded method. */ \
  _LTDefineEasyBoxingEnum(NAME); \
  \
  /* Define traits struct. */ \
  _LTDefineTraitsStruct(NAME, __VA_ARGS__)

#define LTEnumDeclareWithValues(TYPE, NAME, ...) \
  /* Define the enum itself. */ \
  typedef NS_ENUM(TYPE, _##NAME) { \
    metamacro_foreach2(_LTEnumFieldWithValue,, _LTNull, __VA_ARGS__) \
  }; \
  \
  /* Create NSValue+NAMEValue category. */ \
  _LTEnumDeclareNSValueCategory(TYPE, NAME); \
  \
  /* Declare the Enum wrapper class. */ \
  _LTEnumDeclareClass(NAME); \
  \
  /* Defined easy boxing overloaded method. */ \
  _LTDefineEasyBoxingEnum(NAME); \
  \
  /* Define traits struct. */ \
  _LTDefineTraitsStructWithValues(NAME, __VA_ARGS__)

#define LTEnumImplement(TYPE, NAME, ...) \
  /* Verify the implementation matches the definition. */ \
  _LTVerifyImplementation(NAME, __VA_ARGS__); \
  \
  /* Register the enum with LTEnumRegistry. */ \
  _LTEnumRegister(NAME, TYPE, __VA_ARGS__) \
  \
  /* Create NSValue+NAMEValue category. */ \
  _LTEnumImplementNSValueCategory(TYPE, NAME) \
  \
  /* Implement the Enum wrapper class. */ \
  _LTEnumImplementClass(NAME);

#define LTEnumImplementWithValues(TYPE, NAME, ...) \
  /* Verify the implementation matches the definition. */ \
  _LTVerifyImplementationWithValues(NAME, __VA_ARGS__); \
  \
  /* Register the enum with LTEnumRegistry. */ \
  _LTEnumRegisterWithValues(NAME, TYPE, __VA_ARGS__) \
  \
  /* Create NSValue+NAMEValue category. */ \
  _LTEnumImplementNSValueCategory(TYPE, NAME) \
  \
  /* Implement the Enum wrapper class. */ \
  _LTEnumImplementClass(NAME);

#pragma mark -
#pragma mark Implementation
#pragma mark -

/// Registers the enum with \c LTEnumRegistry on image load.
#define _LTEnumRegister(NAME, TYPE, ...) \
  __attribute__((constructor)) static void __register##NAME() { \
    [[LTEnumRegistry sharedInstance] \
        registerEnumName:@#NAME \
        withFieldToValue:@{metamacro_foreach_cxt(_LTEnumDictionaryField,, TYPE, __VA_ARGS__)}]; \
  }

/// Registers the enum with \c LTEnumRegistry on image load.
#define _LTEnumRegisterWithValues(NAME, TYPE, ...) \
  __attribute__((constructor)) static void __register##NAME() { \
    [[LTEnumRegistry sharedInstance] \
        registerEnumName:@#NAME \
        withFieldToValue:@{metamacro_foreach2(_LTEnumDictionaryFieldWithValue, TYPE, \
                                              _LTNull, __VA_ARGS__)}]; \
  }

/// Defines NSValue category with boxing / unboxing methods.
#define _LTEnumDeclareNSValueCategory(TYPE, NAME) \
  @interface NSValue (_##NAME) \
  \
  - (_##NAME)NAME ## Value; \
  \
  + (NSValue *)valueWith ## NAME:(_##NAME)value; \
  \
  @end

/// Implements NSValue category with boxing / unboxing methods.
#define _LTEnumImplementNSValueCategory(TYPE, NAME) \
  @implementation NSValue (_ ## NAME) \
  \
  - (_##NAME)NAME ## Value { \
    _LTEnumGetValue(NAME, "i", int) \
    _LTEnumGetValue(NAME, "l", long) \
    _LTEnumGetValue(NAME, "q", long long) \
    _LTEnumGetValue(NAME, "I", unsigned int) \
    _LTEnumGetValue(NAME, "L", unsigned long) \
    _LTEnumGetValue(NAME, "Q", unsigned long long) \
    LTAssert(NO, @"Invalid type encoding for enum value: %s", self.objCType); \
  } \
  \
  + (NSValue *)valueWith ## NAME:(_##NAME)value { \
    return [NSValue valueWithBytes:&value objCType:@encode(_##NAME)]; \
  } \
  \
  @end

#define _LTEnumGetValue(NAME, TYPE_ENCODING, TYPE) \
  if (!strcmp(self.objCType, TYPE_ENCODING))  { \
    TYPE value; \
    [self getValue:&value]; \
    return (_##NAME)value; \
  }

/// Declares the enum wrapper class.
#define _LTEnumDeclareClass(NAME) \
  @interface NAME : NSObject <LTEnum> \
  \
  - (instancetype)initWithValue:(_##NAME)value; \
  \
  + (instancetype)enumWithValue:(_##NAME)value; \
  \
  + (void)enumerateValuesUsingBlock:(void (^)(_##NAME value))block; \
  + (void)enumerateEnumUsingBlock:(void (^)(NAME *value))block; \
  \
  @property (nonatomic) _##NAME value; \
  \
  @end

/// Implement the enum wrapper class.
#define _LTEnumImplementClass(NAME) \
  @implementation NAME \
  \
  - (instancetype)initWithName:(NSString *)name { \
    NSValue *value = [LTEnumRegistry sharedInstance][@#NAME][name]; \
    LTParameterAssert(value, @"Field %@ does not exist in the enum %@", name, @#NAME); \
    return [self initWithValue:[value NAME##Value]]; \
  } \
  \
  - (instancetype)initWithValue:(_##NAME)value { \
    if (self = [super init]) { \
      self.value = value; \
    } \
    return self; \
  } \
  \
  - (instancetype)initWithCoder:(NSCoder *)aDecoder {\
    return [self initWithValue:[[aDecoder decodeObjectForKey:@"value"] NAME##Value]]; \
  } \
  \
  - (void)encodeWithCoder:(NSCoder *)aCoder { \
    [aCoder encodeObject:[NSValue valueWith##NAME:self.value] forKey:@"value"]; \
  } \
  \
  - (instancetype)enumWithNextValue { \
    LTBidirectionalMap *mapping = [[LTEnumRegistry sharedInstance] \
        enumFieldToValueForName:@#NAME]; \
    NSArray *enumValues = [mapping.allValues sortedArrayUsingSelector:@selector(compare:)]; \
    NSUInteger selfIndex = [enumValues indexOfObject:@(self.value)]; \
    LTAssert(selfIndex != NSNotFound, @"Could not find mapping for enum value %@", self); \
    if (selfIndex == enumValues.count - 1) { \
      return nil; \
    } \
    return [[self class] enumWithValue:[enumValues[selfIndex + 1] NAME ## Value]]; \
  } \
  \
  + (instancetype)enum { \
    return [[[self class] alloc] init]; \
  } \
  \
  + (instancetype)enumWithName:(NSString *)name { \
    return [[[self class] alloc] initWithName:name]; \
  } \
  \
  + (instancetype)enumWithValue:(_##NAME)value { \
    return [[NAME alloc] initWithValue:value]; \
  } \
  \
  + (void)enumerateValuesUsingBlock:(void (^)(_##NAME value))block { \
    LTParameterAssert(block); \
    LTBidirectionalMap *mapping = [[LTEnumRegistry sharedInstance] \
        enumFieldToValueForName:@#NAME]; \
    \
    for (NSNumber *value in mapping.allValues) { \
      block([value NAME##Value]); \
    } \
  } \
  \
  + (void)enumerateEnumUsingBlock:(void (^)(NAME *value))block { \
    LTParameterAssert(block); \
    [self enumerateValuesUsingBlock:^(_##NAME value) { \
      block([[NAME alloc] initWithValue:value]); \
    }]; \
  } \
  \
  - (NSString *)name { \
    return [[LTEnumRegistry sharedInstance][@#NAME] keyForObject:@(self.value)]; \
  } \
  \
  - (NSUInteger)hash { \
    return (NSUInteger)self.value; \
  } \
  \
  - (BOOL)isEqual:(id)object { \
    if (self == object) { \
      return YES; \
    } \
    \
    if (![object isKindOfClass:[NAME class]]) { \
      return NO; \
    } \
    \
    return self.value == ((NAME *)object).value; \
  } \
  \
  - (NSComparisonResult)compare:(NAME *)object { \
    if (self.value < object.value) { \
      return NSOrderedAscending; \
    } else if (self.value > object.value) { \
      return NSOrderedDescending; \
    } else { \
      return NSOrderedSame; \
    } \
  } \
  \
  - (NSString *)description { \
    return [NSString stringWithFormat:@"<%@: %p, %@: %lu>", [self class], self, \
        self.name, (unsigned long)self.value]; \
  } \
  \
  - (id)copyWithZone:(NSZone __unused *)zone { \
    return [NAME enumWithValue:self.value]; \
  } \
  \
  @end

/// Declare easy boxing method.
#define _LTDefineEasyBoxingEnum(NAME) \
  NS_INLINE NAME __unused *$(const _##NAME value) { \
    return [NAME enumWithValue:value]; \
  }

/// Defines a traits struct used to verify that the declaration and implementation are similar.
#define _LTDefineTraitsStruct(NAME, ...) \
  struct __## NAME { \
    metamacro_foreach(_LTEnumTraitsStuctField,, __VA_ARGS__) \
    static const int fieldCount = metamacro_argcount(__VA_ARGS__); \
  };

/// Defines a traits struct with given field values used to verify that the declaration and
/// implementation are similar.
#define _LTDefineTraitsStructWithValues(NAME, ...) \
  struct __## NAME { \
    metamacro_foreach2(_LTEnumTraitsStuctFieldAndValue,, _LTNull, __VA_ARGS__) \
    static const int fieldCount = metamacro_argcount(__VA_ARGS__); \
  };

/// Defines a method which does nothing but to statically verify that the declaration and
/// implementation are similar.
#define _LTVerifyImplementation(NAME, ...) \
  __unused static void __verify##NAME() { \
    static_assert(__##NAME::fieldCount == metamacro_argcount(__VA_ARGS__), \
                  "Field count doesn't match for enum " #NAME); \
    metamacro_foreach_cxt(_LTEnumVerifyField,, NAME, __VA_ARGS__) \
  }

/// Defines a method which does nothing but to statically verify that the declaration and
/// implementation are similar.
#define _LTVerifyImplementationWithValues(NAME, ...) \
  __unused static void __verify##NAME() { \
    static_assert(__##NAME::fieldCount == metamacro_argcount(__VA_ARGS__), \
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
#define _LTEnumDictionaryField(INDEX, TYPE, ARG) \
  _LTEnumDictionaryFieldWithValue(TYPE, ARG, INDEX)

/// Callback to define a dictionary field with \c ARG as \c NSString and INDEX as \c NSNumber.
#define _LTEnumDictionaryFieldWithValue(TYPE, ARG, VALUE) \
  @#ARG: @((TYPE)VALUE),

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
  static_assert(__##NAME::ARG == VALUE, "Enum field " #ARG " with value " #VALUE " doesn't " \
                "match declaration");
