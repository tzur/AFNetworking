// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Dekel Avrahami.

#import <LTKit/LTStorage.h>

NS_ASSUME_NONNULL_BEGIN

/// Fakes storage that does not persist. Used for testing.
@interface LTFakeStorage : NSObject <LTStorage>

/// The underlying storage.
@property (readonly, nonatomic) NSMutableDictionary *storage;

@end

NS_ASSUME_NONNULL_END
