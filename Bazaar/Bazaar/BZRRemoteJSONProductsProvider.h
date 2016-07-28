// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRJSONProductsProvider.h"

NS_ASSUME_NONNULL_BEGIN

@class FBRHTTPClient;

/// Provider used to fetch JSON-serialized \c BZRProduct list from a remote source.
@interface BZRRemoteJSONProductsProvider : NSObject <BZRJSONProductsProvider>

- (instancetype)init NS_UNAVAILABLE;

/// Initialize with \c URL, a path to where to fetch the JSON file from, and with \c HTTPClient, to
/// request the JSON file with.
- (instancetype)initWithURL:(NSURL *)URL HTTPClient:(FBRHTTPClient *)HTTPClient
    NS_DESIGNATED_INITIALIZER;

/// Initialize with \c URL, a path to where to fetch the JSON file from, using the default
/// \c HTTPClient. Similar to calling \c [initWithURL:URL HTTPClient:[FBRHTTPClient client]].
- (instancetype)initWithURL:(NSURL *)URL;

@end

NS_ASSUME_NONNULL_END
