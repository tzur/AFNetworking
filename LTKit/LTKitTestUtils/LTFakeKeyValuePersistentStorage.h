// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Dekel Avrahami.

#import <LTKit/LTKeyValuePersistentStorage.h>

NS_ASSUME_NONNULL_BEGIN

/// Fakes storage that does not persist. Used for testing.
@interface LTFakeKeyValuePersistentStorage : NSObject <LTKeyValuePersistentStorage>

/// The underlying storage.
@property (readonly, nonatomic) NSMutableDictionary *storage;

@end

NS_ASSUME_NONNULL_END
