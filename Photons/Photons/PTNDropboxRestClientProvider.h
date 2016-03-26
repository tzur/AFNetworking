// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

@class DBRestClient;

NS_ASSUME_NONNULL_BEGIN

/// Protocol for providers of \c DBRestClient objects.
@protocol PTNDropboxRestClientProvider <NSObject>

/// Returns a newly formed \c DBRestClient object. This must be an unused instance with no active
/// requests.
- (DBRestClient *)ptn_restClient;

@end

NS_ASSUME_NONNULL_END
