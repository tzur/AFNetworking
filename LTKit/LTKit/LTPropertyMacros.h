// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

/// Useful property declaration and implementation macros.

/// Define a primitive property, together with a readonly min/max properties.
#define LTBoundedPrimitiveProperty(type, name, Name) \
@property (nonatomic) type name; \
@property (readonly, nonatomic) type min##Name; \
@property (readonly, nonatomic) type max##Name; \
@property (readonly, nonatomic) type default##Name;

/// Implement a primitve property, creating constants named \c kMinProperty, \c kMaxProperty, and
/// \c kDefaultProperty, and implement the minProperty and maxProperty getters.
#define LTBoundedPrimitivePropertyImplementWithoutSetter(type, name, Name, minValue, maxValue, \
    defaultValue) \
  static const type kMin##Name = minValue; \
  static const type kMax##Name = maxValue; \
  static const type kDefault##Name = defaultValue; \
  \
  - (type)min##Name { \
    return kMin##Name; \
  } \
  - (type)max##Name { \
    return kMax##Name; \
  } \
  - (type)default##Name { \
    return kDefault##Name; \
  }

/// Implement a primitive property using \c LTBoundedPrimitivePropertyImplementWithoutSetter, and
/// additionally implement the default setter, asserting the given value against the min/max values.
#define LTBoundedPrimitivePropertyImplement(type, name, Name, minValue, maxValue, defaultValue) \
  LTBoundedPrimitivePropertyImplementWithCustomSetter(type, name, Name, minValue, maxValue, \
      defaultValue, ^{})

/// Implement a primitive property using \c LTBoundedPrimitivePropertyImplementWithoutSetter, and
/// additionally implement the default setter clamping the given value to the min/max values, and
/// perform the given custom block after setting the value.
#define LTBoundedPrimitivePropertyImplementWithCustomSetter(type, name, Name, minValue, maxValue, \
    defaultValue, afterSetterBlock) \
  LTBoundedPrimitivePropertyImplementWithoutSetter(type, name, Name, minValue, maxValue, \
      defaultValue) \
  \
  - (void)set##Name:(type)name { \
    LTParameterAssert(name >= self.min##Name); \
    LTParameterAssert(name <= self.max##Name); \
    _##name = name; \
    afterSetterBlock(); \
  }
