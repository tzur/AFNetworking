// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

NS_ASSUME_NONNULL_BEGIN

/// Declares an \c lt::Interval with the given \c type.
#define _DVNIntervalDeclare(type) lt::Interval<type>

/// Declares \c name, \c defaultName, \c minName, \c softMinName, \c maxName and \c softMaxName
/// properties for the given \c name.
#define DVNPropertyDeclare(type, name, Name) \
  @property (nonatomic) type name; \
  @property (nonatomic) type softMin##Name; \
  @property (nonatomic) type softMax##Name; \
  @property (nonatomic) type default##Name; \
  @property (readonly, nonatomic) type min##Name; \
  @property (readonly, nonatomic) type max##Name; \
  @property (readonly, nonatomic) BOOL __softMin##Name##Set; \
  @property (readonly, nonatomic) BOOL __softMax##Name##Set; \
  @property (readonly, nonatomic) BOOL __##name##Set; \
  @property (readonly, nonatomic) BOOL __default##Name##Set; \

/// Declares a getter named \c nameRange returning an open \c lt::Interval of the given \c type and
/// with the given \c infimum and \c supremum.
#define DVNOpenRangeClassProperty(type, name, Name, infimum, supremum) \
  _DVNRangeClassProperty(type, name, Name, infimum, supremum, Open, Open)

/// Declares a getter named \c nameRange returning a left-open \c lt::Interval of the given \c type
/// and with the given \c infimum and \c supremum.
#define DVNLeftOpenRangeClassProperty(type, name, Name, infimum, supremum) \
  _DVNRangeClassProperty(type, name, Name, infimum, supremum, Open, Closed)

/// Declares a getter named \c nameRange returning a right-open \c lt::Interval of the given \c type
/// and with the given \c infimum and \c supremum.
#define DVNRightOpenRangeClassProperty(type, name, Name, infimum, supremum) \
  _DVNRangeClassProperty(type, name, Name, infimum, supremum, Closed, Open)

/// Declares a getter named \c nameRange returning a closed \c lt::Interval of the given \c type and
/// with the given \c infimum and \c supremum.
#define DVNClosedRangeClassProperty(type, name, Name, infimum, supremum) \
  _DVNRangeClassProperty(type, name, Name, infimum, supremum, Closed, Closed)

/// Declares a getter named \c nameRange returning an \c lt::Interval of the given \c type and with
/// the given \c infimum and \c supremum. The infimum (/supremum) of the returned interval is
/// included if the given \c infEndpointInclusion (/supEndpointInclusion) is \c Open, and excluded
/// if \c Closed.
#define _DVNRangeClassProperty(type, name, Name, infimum, supremum, \
  infEndpointInclusion, supEndpointInclusion) \
  static const _DVNIntervalDeclare(type) k##Name##Values({infimum, supremum}, \
  _DVNIntervalDeclare(type)::infEndpointInclusion, \
  _DVNIntervalDeclare(type)::supEndpointInclusion); \
  + (_DVNIntervalDeclare(type))name##Range {\
    return k##Name##Values;\
  } \

/// Implements \c minName and \c maxName getters for the given property \c name in addition to
/// <tt>setName:<\tt>, <tt>setSoftMinName:<\tt>, <tt>setSoftMaxName:<\tt> and
/// <tt>setDefaultName:<\tt> setters. The <tt>setName:<\tt> and <tt>setDefaultName:<\tt> assert that
/// the given value is in <tt>[softMinName, softMaxName]<\tt> range. The <tt>setSoftMinName:<\tt>
/// asserts that the given value is in <tt>[minName, softMaxName]<\tt> range. The
/// <tt>setSoftMaxName:<\tt> asserts that the given value is in <tt>[softMinName, maxName]<\tt>
/// range. Initially, \c name, \c defaultName, \c softMinName and \c softMaxName are set to
/// \c defaultValue, \c defaultValue, \c minValue and \c maxValue, respectively.
#define DVNProperty(type, name, Name, minValue, maxValue, defaultValue) \
  @synthesize softMin##Name = _softMin##Name; \
  @synthesize softMax##Name = _softMax##Name; \
  @synthesize __softMin##Name##Set = ___softMin##Name##Set; \
  @synthesize __softMax##Name##Set = ___softMax##Name##Set; \
  @synthesize name = _##name; \
  @synthesize default##Name = _default##Name; \
  @synthesize __##name##Set = ___##name##Set; \
  @synthesize __default##Name##Set = ___default##Name##Set; \
  static const type kDefault##Name = defaultValue; \
  static const type kMin##Name = minValue; \
  - (type)min##Name { \
    return kMin##Name; \
  } \
  static const type kMax##Name = maxValue; \
  - (type)max##Name { \
    return kMax##Name; \
  } \
  - (type)name { \
    if (!___##name##Set) { \
      _##name = kDefault##Name; \
      ___##name##Set = YES; \
    } \
    return _##name; \
  } \
  - (void)set##Name:(type)name { \
    _##name = name; \
    ___##name##Set = YES; \
  } \
  - (type)default##Name { \
    if (!___default##Name##Set) { \
      _default##Name = kDefault##Name; \
      ___default##Name##Set = YES; \
    } \
    return _default##Name; \
  } \
  - (void)setDefault##Name:(type)default##Name { \
    _default##Name = default##Name; \
    ___default##Name##Set = YES; \
  } \
  - (type)softMin##Name { \
    if (!___softMin##Name##Set) { \
      _softMin##Name = self.min##Name; \
      ___softMin##Name##Set = YES; \
    } \
    return _softMin##Name; \
  } \
  - (void)setSoftMin##Name:(type)softMin##Name { \
    _softMin##Name = softMin##Name; \
    ___softMin##Name##Set = YES; \
  } \
  - (type)softMax##Name { \
    if (!___softMax##Name##Set) { \
      _softMax##Name = self.max##Name; \
      ___softMax##Name##Set = YES; \
    } \
    return _softMax##Name; \
  } \
  - (void)setSoftMax##Name:(type)softMax##Name { \
    _softMax##Name = softMax##Name; \
    ___softMax##Name##Set = YES; \
  }

NS_ASSUME_NONNULL_END
