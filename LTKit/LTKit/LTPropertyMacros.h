// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTWeakContainer.h"
#import "NSNumber+CGFloat.h"

/// Useful property declaration and implementation macros.

#pragma mark -
#pragma mark Interface
#pragma mark -

/// Implement a \c (strong, \c nonatomic) property in a category, using \c objc/runtime.
///
/// @note This macro cannot be used for primitive types.
#define LTCategoryProperty(type, name, Name) \
  - (type)name { \
    return objc_getAssociatedObject(self, @selector(name)); \
  } \
  - (void)set##Name:(type)name { \
    objc_setAssociatedObject(self, @selector(name), name, OBJC_ASSOCIATION_RETAIN_NONATOMIC); \
  }

/// Implement a \c (weak, \c nonatomic) property in a category, using \c objc/runtime.
///
/// @note This macro cannot be used for primitive types.
/// @note This property will be automatically set to \c nil when the target object is deallocated.
#define LTCategoryWeakProperty(type, name, Name) \
  - (nullable type)name { \
    return [(LTWeakContainer *)objc_getAssociatedObject(self, @selector(name)) object]; \
  } \
  - (void)set##Name:(nullable type)name { \
    objc_setAssociatedObject(self, @selector(name), [[LTWeakContainer alloc] initWithObject:name], \
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC); \
  }

/// Implement a struct primitive property in a category, using \c objc/runtime.
#define LTCategoryStructProperty(type, name, Name) \
  - (type)name { \
    NSValue *valueObject = objc_getAssociatedObject(self, @selector(name)); \
    type value; \
    [valueObject getValue:&value]; \
    return value; \
  } \
  - (void)set##Name:(type)name { \
    NSValue *value = [NSValue valueWithBytes:&name objCType:@encode(type)]; \
    objc_setAssociatedObject(self, @selector(name), value, OBJC_ASSOCIATION_RETAIN_NONATOMIC); \
  }

/// Implement a \c BOOL property in a category, using \c objc/runtime.
#define LTCategoryBoolProperty(name, Name) LTCategoryNumberProperty(BOOL, name, Name, boolValue)

/// Implement a \c CGFloat primitive property in a category, using \c objc/runtime.
#define LTCategoryCGFloatProperty(name, Name) \
  LTCategoryNumberProperty(CGFloat, name, Name, CGFloatValue)

/// Implement an \c NSInteger primitive property in a category, using \c objc/runtime.
#define LTCategoryIntegerProperty(name, Name) \
  LTCategoryNumberProperty(NSInteger, name, Name, integerValue)

/// Implement an \c NSUInteger primitive property in a category, using \c objc/runtime.
#define LTCategoryUnsignedIntegerProperty(name, Name) \
  LTCategoryNumberProperty(NSUInteger, name, Name, unsignedIntegerValue)

/// Define the readonly min/max/default properties of a primitive property.
#define LTPropertyDeclare(type, name, Name) \
@property (nonatomic) BOOL __##name##Set; \
@property (readonly, nonatomic) type min##Name; \
@property (readonly, nonatomic) type max##Name; \
@property (readonly, nonatomic) type default##Name;

/// Implement a primitive property, proxying another property with a custom name (updating the
/// proxied property in the setter and returning its value, bounds, and default value in the
/// corresponding getters). In case the customName arguments are not provided, assumes their name
/// is identical to the property's.
#define LTPropertyProxy(...) \
  metamacro_if_eq(4, metamacro_argcount(__VA_ARGS__)) \
  (_LTPropertyProxy(__VA_ARGS__))(_LTPropertyProxyCustom(__VA_ARGS__))

/// Implement a primitive property, proxying another property with a custom name (returning its
/// value, bounds, and default value in the corresponding getters). The setter for the property
/// needs to be manually defined. In case the customName arguments are not provided, assumes their
/// name is identical to the property's.
#define LTPropertyProxyWithoutSetter(...) \
  metamacro_if_eq(4, metamacro_argcount(__VA_ARGS__)) \
  (_LTPropertyProxyWithoutSetter(__VA_ARGS__))(_LTPropertyProxyCustomWithoutSetter(__VA_ARGS__))

/// Implement the minProperty, maxProperty, and defaultProperty getters for the property.
/// Implement the getter, using the defaultProperty value as the initial value.
/// Implement the setter, asserting the given value against the min/max values.
#define LTProperty(type, name, Name, minValue, maxValue, defaultValue) \
  LTPropertyWithoutSetter(type, name, Name, minValue, maxValue, defaultValue) \
  - (void)set##Name:(type)name { \
    [self _verifyAndSet##Name:name]; \
  }

/// Implement the minProperty, maxProperty, and defaultProperty getters for the property.
/// Implement the getter, using the defaultProperty value as the initial value.
/// Implement the _verifyProperty and verifyAndSetProperty helper methods that can be used in the
/// custom setter that will be implemented.
///
/// @note the custom setter will be called when the default value is assigned. However, this isn't
/// called automatically upon initialization, hence will require a manual call to the getter.
#define LTPropertyWithoutSetter(type, name, Name, minValue, maxValue, defaultValue) \
  @synthesize name = _##name; \
  static const type __kMin##Name = minValue; \
  - (type)min##Name { \
    return __kMin##Name; \
  } \
  static const type __kMax##Name = maxValue; \
  - (type)max##Name { \
    return __kMax##Name; \
  } \
  static const type __kDefault##Name = defaultValue; \
  - (type)default##Name { \
    return __kDefault##Name; \
  } \
  - (type)name { \
    if (!___##name##Set) { \
      [self _verifyAndSet##Name:self.default##Name]; \
    } \
    return _##name; \
  } \
  - (void)_verifyAndSet##Name:(type)name { \
    [self _verify##Name:name]; \
    _##name = name; \
    ___##name##Set = YES; \
  }\
  - (void) _verify##Name:(type)name { \
    LTParameterAssert(name >= self.min##Name); \
    LTParameterAssert(name <= self.max##Name); \
  }

#pragma mark -
#pragma mark Implementation
#pragma mark -

/// Implement the property proxying to a property with an identical name.
#define _LTPropertyProxy(type, name, Name, proxyBase) \
  _LTPropertyProxyCustom(type, name, Name, proxyBase, name, Name)

/// Implement the property proxying to a property with a custom name.
#define _LTPropertyProxyCustom(type, name, Name, proxyBase, customName, CustomName) \
  LTPropertyProxyWithoutSetter(type, name, Name, proxyBase, customName, CustomName) \
  - (void)set##Name:(type)name { \
    proxyBase.customName = name; \
  }

/// Implement the property proxying to a property with an identical name, without the default
/// setter.
#define _LTPropertyProxyWithoutSetter(type, name, Name, proxyBase) \
  _LTPropertyProxyCustomWithoutSetter(type, name, Name, proxyBase, name, Name)

/// Implement the property proxying to a property with a custom name, without the default setter.
#define _LTPropertyProxyCustomWithoutSetter(type, name, Name, proxyBase, customName, CustomName) \
  - (type)min##Name { \
    return proxyBase.min##CustomName; \
  } \
  - (type)max##Name { \
    return proxyBase.max##CustomName; \
  } \
  - (type)default##Name { \
    return proxyBase.default##CustomName; \
  } \
  - (type)name { \
    return proxyBase.customName; \
  }

/// Implement the category for primitives boxed by \c NSNumber, accepting the name of the selector
/// used for unboxing them.
#define LTCategoryNumberProperty(type, name, Name, valueSelector) \
  - (type)name { \
    return [objc_getAssociatedObject(self, @selector(name)) valueSelector]; \
  } \
  - (void)set##Name:(type)name { \
    objc_setAssociatedObject(self, @selector(name), @(name), OBJC_ASSOCIATION_RETAIN_NONATOMIC); \
  }
