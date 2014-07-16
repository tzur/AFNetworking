// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTEnumMacros.h"

@class LTBidirectionalMap;

/// Registry for enumeration types defined by the macro \c LTEnumMake(). This allows run-time
/// inspection of enumeration types and their declared fields.
@interface LTEnumRegistry : NSObject

/// Returns the shared singleton instance.
+ (instancetype)sharedInstance;

/// Registers an enum with the given name and a dictionary that maps field names (\c NSString) to
/// their numeric (\c NSNumber) values.
- (void)registerEnumName:(NSString *)enumName withFieldToValue:(NSDictionary *)fieldToValue;

/// Returns \c YES if the given enum is registered.
- (BOOL)isEnumRegistered:(NSString *)enumName;

/// Returns an \c LTBidirectionalMap that maps the given enum's field names (\c NSString) to their
/// numeric (\c NSNumber) values and vice versa.
- (LTBidirectionalMap *)enumFieldToValueForName:(NSString *)enumName;

/// Returns the enum dictionary for the given enum name (\c NSString).
- (id)objectForKeyedSubscript:(NSString *)key;

@end
