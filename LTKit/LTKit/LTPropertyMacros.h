// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

/// Useful property declaration and implementation macros.

/// Define the readonly min/max/default properties of a primitve property.
#define LTPropertyDeclare(type, name, Name) \
@property (nonatomic) BOOL __##name##Set; \
@property (readonly, nonatomic) type min##Name; \
@property (readonly, nonatomic) type max##Name; \
@property (readonly, nonatomic) type default##Name;

/// Implement a primitive property, proxying another property with identical name (updating the
/// proxied property in the setter and returning its value, bounds, and default value in the
/// corresponding getters).
#define LTPropertyProxy(type, name, Name, proxyBase) \
  LTPropertyProxyCustom(type, name, Name, proxyBase, name, Name)

/// Implement a primitive property, proxying another property with identical name (returning its
/// value, bounds, and default value in the corresponding getters). The setter for the property
/// needs to be manually defined.
#define LTPropertyProxyWithoutSetter(type, name, Name, proxyBase) \
  LTPropertyProxyCustomWithoutSetter(type, name, Name, proxyBase, name, Name)

/// Implement a primitive property, proxying another property with a custom name (updating the
/// proxied property in the setter and returning its value, bounds, and default value in the
/// corresponding getters).
#define LTPropertyProxyCustom(type, name, Name, proxyBase, customName, CustomName) \
  LTPropertyProxyCustomWithoutSetter(type, name, Name, proxyBase, customName, CustomName) \
  - (void)set##Name:(type)name { \
    proxyBase.customName = name; \
  }

/// Implement a primitve property, proxying another property with a custom name (returning its
/// value, bounds, and default value in the corresponding getters). The setter for the property
/// needs to be manually defined.
#define LTPropertyProxyCustomWithoutSetter(type, name, Name, proxyBase, customName, CustomName) \
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

/// Implement the minProperty, maxProperty, and defaultProperty getters for the property.
#define LTPropertyBounds(type, name, Name, minValue, maxValue, defaultValue) \
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
  }

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
  LTPropertyBounds(type, name, Name, minValue, maxValue, defaultValue) \
  @synthesize name = _##name; \
  - (type)name { \
    if (!___##name##Set) { \
      [self _verifyAndSet##Name:self.default##Name]; \
    } \
    return _##name; \
  } \
  - (void) _verifyAndSet##Name:(type)name { \
    [self _verify##Name:name]; \
    _##name = name; \
    ___##name##Set = YES; \
  }\
  - (void) _verify##Name:(type)name { \
    LTParameterAssert(name >= self.min##Name); \
    LTParameterAssert(name <= self.max##Name); \
  }
