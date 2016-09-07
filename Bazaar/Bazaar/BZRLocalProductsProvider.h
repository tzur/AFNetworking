// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRProductsProvider.h"

@class LTPath;

NS_ASSUME_NONNULL_BEGIN

/// Provides a list of JSON-serialized \c BZRProducts from a local source.
@interface BZRLocalProductsProvider : NSObject <BZRProductsProvider>

- (instancetype)init NS_UNAVAILABLE;

/// Initialize with \c path, a path to where to fetch the JSON file from, and with
/// \c fileManager set to \c -[NSFileManager defaultManager].
- (instancetype)initWithPath:(LTPath *)path;

/// Initialize with \c path, a path to where to fetch the JSON file from, and with
/// \c fileManager, to read the content of the file into a JSON list.
- (instancetype)initWithPath:(LTPath *)path fileManager:(NSFileManager *)fileManager
    NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
