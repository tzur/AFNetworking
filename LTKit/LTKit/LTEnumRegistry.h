// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTEnumMacros.h"

NS_ASSUME_NONNULL_BEGIN

@class LTBidirectionalMap;

/// Registry for enumeration types defined by the macro \c LTEnumMake(). This allows run-time
/// inspection of enumeration types and their declared fields.
@interface LTEnumRegistry : NSObject

/// Returns the shared singleton instance.
+ (instancetype)sharedInstance;

/// Registers an enum with the given name and a dictionary that maps field names (\c NSString) to
/// their numeric (\c NSNumber) values.
- (void)registerEnumName:(NSString *)enumName
        withFieldToValue:(NSDictionary<NSString *, NSNumber *> *)fieldToValue;

/// Returns \c YES if the given enum is registered.
- (BOOL)isEnumRegistered:(NSString *)enumName;

typedef LTBidirectionalMap<NSString *, NSNumber *> LTEnumFieldToValue;

/// Returns an \c LTBidirectionalMap that maps the given enum's field names (\c NSString) to their
/// numeric (\c NSNumber) values and vice versa, or \c nil if \c enumName is not registered.
- (nullable LTEnumFieldToValue *)enumFieldToValueForName:(NSString *)enumName;

/// Shortcut for \c -enumFieldToValueForName:.
- (nullable LTEnumFieldToValue *)objectForKeyedSubscript:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
