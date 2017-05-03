// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Nir Bruner.

NS_ASSUME_NONNULL_BEGIN

@interface NSDate (Formatting)

/// Returns a string representation of the receiver, formatted according to the device's timezone
/// and locale-neutral.
///
/// @see <tt>[NSDateFormatter lt_deviceTimezoneDateFormatter]</tt>.
- (NSString *)lt_deviceTimezoneString;

@end

NS_ASSUME_NONNULL_END
