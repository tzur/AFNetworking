// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

#import "NSErrorCodes+Intelligence.h"

NS_ASSUME_NONNULL_BEGIN

@interface NSError (Intelligence)

/// Creates an error with Lightricks' domain, given error code and the associated \c NSData record.
+ (instancetype)int_errorWithCode:(NSInteger)code record:(nullable NSData *)record;

/// Creates an error with Lightricks' domain, given error code, the associated \c NSData record and
/// underlyign error.
+ (instancetype)int_errorWithCode:(NSInteger)code record:(nullable NSData *)record
                  underlyingError:(nullable NSError *)underlyingError;

/// JSON record associated with the error.
@property (readonly, nonatomic, nullable) NSData *int_record;

@end

NS_ASSUME_NONNULL_END
