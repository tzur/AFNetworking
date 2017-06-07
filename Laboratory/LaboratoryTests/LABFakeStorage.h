// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import "LABStorage.h"

NS_ASSUME_NONNULL_BEGIN

/// Fakes storage that does not persist. Used for testing.
@interface LABFakeStorage : NSObject <LABStorage>

/// The underlying store.
@property (readonly, nonatomic) NSMutableDictionary<NSString *, id> *storage;

@end

NS_ASSUME_NONNULL_END
