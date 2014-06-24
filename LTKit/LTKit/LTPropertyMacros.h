// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

/// Useful property declaration and implementation macros.

/// Define a primitive property, together with a readonly min/max properties.
#define LTDeclareProperty(type, name, Name) \
@property (nonatomic) type name; \
@property (nonatomic) BOOL __##name##Set; \
@property (readonly, nonatomic) type min##Name; \
@property (readonly, nonatomic) type max##Name; \
@property (readonly, nonatomic) type default##Name;

/// Implement a primitve property, proxying another property (updating the proxied property in the
/// setter and returning its value, bounds, and default value in the corresponding getters).
#define LTProxyProperty(type, name, Name, proxyBase) \
  LTProxyCustomProperty(type, name, Name, proxyBase, name, Name, ^{})

/// Implement a primitve property, proxying another property (updating the proxied property in the
/// setter and returning its value, bounds, and default value in the corresponding getters).
/// Additionally, runs the given custom block in the setter after the new value is set.
#define LTProxyPropertyWithSetter(type, name, Name, proxyBase, afterSetterBlock) \
  LTProxyCustomProperty(type, name, Name, proxyBase, name, Name, afterSetterBlock)

/// Implement a primitve property, proxying another property with a custom name (updating the
/// proxied property in the setter and returning its value, bounds, and default value in the
/// corresponding getters). Additionally, runs the given custom block in the setter after the new
/// value is set.
#define LTProxyCustomProperty(type, name, Name, proxyBase, customName, CustomName, \
    afterSetterBlock) \
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
  } \
  - (void)set##Name:(type)name { \
    proxyBase.customName = name; \
    afterSetterBlock(); \
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
  LTPropertyWithSetter(type, name, Name, minValue, maxValue, defaultValue, ^{})

/// Implement the minProperty, maxProperty, and defaultProperty getters for the property.
/// Implement the getter, using the defaultProperty value as the initial value.
/// Implement the setter, asserting the given value against the min/max values, and performing the
/// given custom block after setting the value.
#define LTPropertyWithSetter(type, name, Name, minValue, maxValue, defaultValue, afterSetterBlock) \
  LTPropertyBounds(type, name, Name, minValue, maxValue, defaultValue) \
  \
  @synthesize name = _##name; \
  - (type)name { \
    if (!___##name##Set) { \
      _##name = self.default##Name; \
      ___##name##Set = YES; \
    } \
    return _##name; \
  } \
  - (void)set##Name:(type)name { \
    LTParameterAssert(name >= self.min##Name); \
    LTParameterAssert(name <= self.max##Name); \
    ___##name##Set = YES; \
    _##name = name; \
    afterSetterBlock(); \
  }
