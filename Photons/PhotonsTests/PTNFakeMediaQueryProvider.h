// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Michael Kimyagarov.

#import "PTNMediaQueryProvider.h"

NS_ASSUME_NONNULL_BEGIN

@class PTNFakeMediaQuery;

/// Implementation of \c PTNMediaQueryProvider which allows precise control queries creation.
@interface PTNFakeMediaQueryProvider : NSObject <PTNMediaQueryProvider>

/// Initializes with the given \c query, which always be returned by this instance when calling
/// \c -queryWithFilterPredicates:.
- (instancetype)initWithQuery:(PTNFakeMediaQuery *)query;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
