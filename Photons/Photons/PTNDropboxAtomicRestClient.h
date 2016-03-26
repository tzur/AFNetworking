// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNDropboxRestClient.h"

NS_ASSUME_NONNULL_BEGIN

/// Decorator for \c PTNDropboxRestClient enforcing atomic downloading of thumbnails and files. The
/// atomic client initially downloads assets to a temporary unique path and then moves them to the
/// original path provided by the given \c PTNDropboxPathProvider.
@interface PTNDropboxAtomicRestClient : NSObject <PTNDropboxRestClient>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes an with a \c restClientProvider that supplies Dropbox REST clients, \c pathProvider
/// used to supply file paths in which to save downloaded assets and \c fileManager to perform
/// file move operations.
///
/// @note Assets are initially downloaded to a temporary unique path and then moved to the path
/// provided by \c pathProvider. Moving of files occurs on an arbitrary thread.
- (instancetype)initWithRestClientProvider:(id<PTNDropboxRestClientProvider>)restClientProvider
                              pathProvider:(id<PTNDropboxPathProvider>)pathProvider
                               fileManager:(NSFileManager *)fileManager
    NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
