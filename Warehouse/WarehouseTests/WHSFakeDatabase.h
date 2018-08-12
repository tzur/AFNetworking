// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import <fmdb/FMDB.h>

NS_ASSUME_NONNULL_BEGIN

/// Fake database allowing to fail updates or queries. The default behavior is identical to
/// interaction with regular \c FMDatabase instance.
@interface WHSFakeDatabase : FMDatabase

/// If not \c nil, the next \c -executeUpdate: call will fail with this error.
@property (strong, nonatomic, nullable) NSError *updateError;

/// If not \c nil, the next -c executeQuery: call will fail with this error.
@property (strong, nonatomic, nullable) NSError *queryError;

/// Last error generated by the database.
@property (strong, nonatomic) NSError *lastError;

@end

NS_ASSUME_NONNULL_END
