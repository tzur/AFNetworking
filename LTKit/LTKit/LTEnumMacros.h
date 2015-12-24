// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTMetaMacros.h"

#import "LTBidirectionalMap.h"

/// Avoid including this file directly. To use these macros, include \c LTEnum.h.

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
/// LTEnumMakeWithValues(NSUInteger, MyEnum,
///                      MyEnumChoiceA, 1,
///                      MyEnumChoiceB, 3,
///                      MyEnumChoiceC, 5);
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
  /* Create the Enum wrapper category providing list of fields and mappings of fields to values */ \
  _LTEnumDeclareRegistryCategory(NAME) \
  _LTEnumImplementRegistryCategory(NAME, TYPE, __VA_ARGS__) \
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
  /* Create the Enum wrapper category providing list of fields and mappings of fields to values */ \
  _LTEnumDeclareRegistryCategory(NAME) \
  _LTEnumImplementRegistryCategoryWithValues(NAME, TYPE, __VA_ARGS__) \
  \
  /* Create NSValue+NAMEValue category. */ \
  _LTEnumImplementNSValueCategory(TYPE, NAME) \
  \
  /* Implement the Enum wrapper class. */ \
  _LTEnumImplementClass(NAME);

#pragma mark -
#pragma mark Implementation
#pragma mark -

/// Declares the Registry category for the enum wrapper class.
#define _LTEnumDeclareRegistryCategory(NAME) \
  @interface NAME (Registry) \
  \
  /* Returns an array of the names of all the enum fields, in the order they were defined. */ \
  + (NSArray<NSString *> *)_fieldNames; \
  \
  /* Returns a bidirectional mapping between enum field names and their corresponding values. */ \
  + (LTBidirectionalMap<NSString *, NSNumber *> *)_fieldNamesToValues; \
  \
  @end

/// Implements the Registry category for the enum wrapper class, when the default values are used.
#define _LTEnumImplementRegistryCategory(NAME, TYPE, ...) \
  @implementation NAME (Registry) \
  \
  + (NSArray<NSString *> *)_fieldNames { \
    static NSArray<NSString *> *fieldNames; \
    static dispatch_once_t onceToken; \
    dispatch_once(&onceToken, ^{ \
      fieldNames = @[metamacro_foreach(_LTEnumArrayField,, __VA_ARGS__)]; \
    }); \
    return fieldNames; \
  } \
  \
  + (LTBidirectionalMap<NSString *, NSNumber *> *)_fieldNamesToValues { \
    static LTBidirectionalMap<NSString *, NSNumber *> *fieldNamesToValues; \
    static dispatch_once_t onceToken; \
    dispatch_once(&onceToken, ^{ \
      NSDictionary *dict = @{metamacro_foreach_cxt(_LTEnumDictionaryField,, TYPE, __VA_ARGS__)}; \
      fieldNamesToValues = [LTBidirectionalMap mapWithDictionary:dict]; \
    }); \
    return fieldNamesToValues; \
  } \
  \
  @end

/// Implements the Registry category for the enum wrapper class, when custom values are provided.
#define _LTEnumImplementRegistryCategoryWithValues(NAME, TYPE, ...) \
  @implementation NAME (Registry) \
  \
  + (NSArray<NSString *> *)_fieldNames { \
    static NSArray<NSString *> *fieldNames; \
    static dispatch_once_t onceToken; \
    dispatch_once(&onceToken, ^{ \
      fieldNames = @[metamacro_foreach2(_LTEnumArrayFieldWithValue,, _LTNull, __VA_ARGS__)]; \
    }); \
    return fieldNames; \
  } \
  \
  + (LTBidirectionalMap<NSString *, NSNumber *> *)_fieldNamesToValues { \
    static LTBidirectionalMap<NSString *, NSNumber *> *fieldNamesToValues; \
    static dispatch_once_t onceToken; \
    dispatch_once(&onceToken, ^{ \
      NSDictionary *dict = @{metamacro_foreach2(_LTEnumDictionaryFieldWithValue, TYPE, \
                                                _LTNull, __VA_ARGS__)}; \
      fieldNamesToValues = [LTBidirectionalMap mapWithDictionary:dict]; \
    }); \
    return fieldNamesToValues; \
  } \
  \
  @end

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
  - (instancetype)init NS_UNAVAILABLE; \
  \
  /* Designated initializer: Initializes a new enum object with the given value. */ \
  - (instancetype)initWithValue:(_##NAME)value NS_DESIGNATED_INITIALIZER; \
  \
  /* Returns a new enum object with the given value. */ \
  + (instancetype)enumWithValue:(_##NAME)value; \
  \
  /* Executes the given block using each enum value, starting from the smallest value and */ \
  /* continuing through all values to the greatest value. */ \
  + (void)enumerateSortedValuesUsingBlock:(void (^)(_##NAME value))block; \
  \
  /* Executes the given block using each enum value, iterating according to the order the */ \
  /* fields were defined. */ \
  + (void)enumerateValuesUsingBlock:(void (^)(_##NAME value))block; \
  \
  /* Executes the given block using each enum object, iterating according to the order the */ \
  /* fields were defined. */ \
  + (void)enumerateEnumUsingBlock:(void (^)(NAME *value))block; \
  \
  /* Returns an array of new enum objects of all possible enum fields, in the order they were */ \
  /* defined. */ \
  + (NSArray<NAME *> *)fields; \
  \
  /* Underlying value of the enum object. */ \
  @property (readonly, nonatomic) _##NAME value; \
  \
  @end

#define _LTEnumImplementClass(NAME) \
  @implementation NAME \
  \
  - (instancetype)initWithName:(NSString *)name { \
    NSValue *value = [[self class] fieldNamesToValues][name]; \
    LTParameterAssert(value, @"Field %@ does not exist in the enum %@", name, @#NAME); \
    return [self initWithValue:[value NAME##Value]]; \
  } \
  \
  - (instancetype)initWithValue:(_##NAME)value { \
    if (self = [super init]) { \
      _value = value; \
    } \
    return self; \
  } \
  \
  - (nullable instancetype)initWithCoder:(NSCoder *)aDecoder {\
    return [self initWithValue:[[aDecoder decodeObjectForKey:@"value"] NAME##Value]]; \
  } \
  \
  - (void)encodeWithCoder:(NSCoder *)aCoder { \
    [aCoder encodeObject:[NSValue valueWith##NAME:self.value] forKey:@"value"]; \
  } \
  \
  - (nullable instancetype)enumWithNextValue { \
    LTBidirectionalMap *mapping = [[self class] fieldNamesToValues]; \
    NSArray *enumValues = [mapping.allValues sortedArrayUsingSelector:@selector(compare:)]; \
    NSUInteger selfIndex = [enumValues indexOfObject:@(self.value)]; \
    LTAssert(selfIndex != NSNotFound, @"Could not find mapping for enum value %@", self); \
    if (selfIndex == enumValues.count - 1) { \
      return nil; \
    } \
    return [[self class] enumWithValue:[enumValues[selfIndex + 1] NAME ## Value]]; \
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
  + (instancetype)enumWithLowestValue { \
    LTBidirectionalMap *mapping = [self fieldNamesToValues]; \
    NSArray *enumValues = [mapping.allValues sortedArrayUsingSelector:@selector(compare:)]; \
    return [self enumWithValue:[enumValues.firstObject NAME##Value]]; \
  } \
  \
  + (void)enumerateSortedValuesUsingBlock:(void (^)(_##NAME value))block { \
    LTParameterAssert(block); \
    LTBidirectionalMap *mapping = [[self class] fieldNamesToValues]; \
    \
    NSArray *sortedValues = [mapping.allValues sortedArrayUsingSelector:@selector(compare:)]; \
    for (NSNumber *value in sortedValues) { \
      block([value NAME##Value]); \
    } \
  } \
  \
  + (void)enumerateValuesUsingBlock:(void (^)(_##NAME value))block { \
    LTParameterAssert(block); \
    [self enumerateEnumUsingBlock:^(NAME *value) { \
      block(value.value); \
    }]; \
  } \
  \
  + (void)enumerateEnumUsingBlock:(void (^)(NAME *value))block { \
    LTParameterAssert(block); \
    for (NAME *value in [self fields]) { \
      block(value); \
    } \
  } \
  \
  /* This method always returns a new array of new objects for the same reason we didn't want */ \
  /* each enum value to be a singleton - in case categories with associated objects are added */ \
  /* to the enum, this may lead to confusing scenarios. */ \
  + (NSArray<NAME *> *)fields { \
    NSMutableArray<NAME *> *fields = [NSMutableArray array]; \
    for (NSString *fieldName in [self _fieldNames]) { \
      [fields addObject:[[NAME alloc] initWithName:fieldName]]; \
    } \
    return fields; \
  } \
  \
  + (LTBidirectionalMap<NSString *, NSNumber *> *)fieldNamesToValues { \
    return [self _fieldNamesToValues]; \
  } \
  \
  - (NSString *)name { \
    return [[[self class] fieldNamesToValues] keyForObject:@(self.value)]; \
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
  - (id)copyWithZone:(nullable NSZone __unused *)zone { \
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

/// Callback to define a dictionary field with \c ARG as \c NSString and VALUE as \c NSNumber.
#define _LTEnumDictionaryFieldWithValue(TYPE, ARG, VALUE) \
  @#ARG: @((TYPE)VALUE),

/// Callback to define an array field with \c ARG as \c NSString, and an ending comma.
#define _LTEnumArrayField(INDEX, ARG) \
  _LTEnumArrayFieldWithValue(, ARG, INDEX)

/// Callback to define an array field with \c ARG as \c NSString, and an ending comma.
#define _LTEnumArrayFieldWithValue(CONTEXT, ARG, VALUE) \
  @#ARG,

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
