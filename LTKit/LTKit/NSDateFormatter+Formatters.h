// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Boris Talesnik.

NS_ASSUME_NONNULL_BEGIN

@interface NSDateFormatter (Formatters)

/// Returns a date formatter with a UTC timezone, which outputs date strings according to ISO 8601,
/// using the <tt>combined date and time</tt> format <tt>yyyy-MM-ddTHH:mm:ss.SSSZ</tt>. The output
/// is locale neutral, meaning it's independent of any localization considerations.
+ (instancetype)lt_UTCDateFormatter;

/// Returns a date formatter with the device's timezone, which outputs date strings according to ISO
/// 8601, using the <tt>partial time</tt> format <tt>HH:mm:ss.SSS</tt>. The output is locale
/// neutral, meaning it's independent of any localization considerations.
///
/// @note the formatter ignores DST offsets, and always treats the device's timezone as the non-DST
/// variant.
///
/// @note when transforming a <tt>HH:mm:ss.SSS</tt> string to an \c NSDate the resulting \c NSDate
/// will have the date set to <tt>1970-01-01 HH:mm:ss.SSS ±<Timezone Offset on the Device></tt>
+ (instancetype)lt_deviceTimezoneDateFormatter;

@end

NS_ASSUME_NONNULL_END
