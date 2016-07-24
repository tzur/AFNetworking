// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRJSONProductsProvider.h"

@class LTPath;

NS_ASSUME_NONNULL_BEGIN

/// Provides a list of JSON-serialized \c BZRProducts from a local source.
@interface BZRLocalJSONProductsProvider : NSObject <BZRJSONProductsProvider>

- (instancetype)init NS_UNAVAILABLE;

/// Initialize with \c path, a path to where to fetch the JSON file from, and with
/// \c fileManager, to read the content of the file into a JSON list.
- (instancetype)initWithPath:(LTPath *)path fileManager:(NSFileManager *)fileManager
    NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
