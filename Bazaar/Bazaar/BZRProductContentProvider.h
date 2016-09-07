// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

NS_ASSUME_NONNULL_BEGIN

@class BZRProduct, BZRProductContentManager;

@protocol BZRProductContentFetcher;

/// Provider used to fetch content of products.
@interface BZRProductContentProvider : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c contentFetcher, used to fetch content, and with \c contentManager, used to
/// extract content from an archive file.
- (instancetype)initWithContentFetcher:(id<BZRProductContentFetcher>)contentFetcher
                        contentManager:(BZRProductContentManager *)contentManager
    NS_DESIGNATED_INITIALIZER;

/// Provides the content of the given \c product if the user is allowed to use it.
///
/// Returns a signal that fetches the content. If the content already exists locally, the signal
/// just sends the path to that content. Otherwise, it fetches the content and sends the path to the
/// content. The signal completes after sending the path to the product's content, or immediately if
/// the product has no content. The signal errs if the user is not allowed to use the
/// product, or if there was an error while fetching the content.
///
/// @return <tt>RACSignal<LTPath></tt>
- (RACSignal *)fetchProductContent:(BZRProduct *)product;

@end

NS_ASSUME_NONNULL_END
