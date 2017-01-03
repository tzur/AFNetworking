// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Boris Talesnik.

NS_ASSUME_NONNULL_BEGIN

@interface NSDateFormatter (Formatters)

/// Returns a date formatter with a UTC timezone, which outputs date strings according to ISO 8601,
/// using the <tt>combined date and time</tt> format <tt>yyyy-MM-ddTHH:mm:ss.SSSZ</tt>. The output
/// is locale neutral, meaning it's independent of any localization considerations.
+ (instancetype)lt_UTCDateFormatter;

@end

NS_ASSUME_NONNULL_END
