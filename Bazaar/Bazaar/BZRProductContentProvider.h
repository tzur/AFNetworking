// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

NS_ASSUME_NONNULL_BEGIN

@class BZRProduct;

/// Protocol for providing content of products.
@protocol BZRProductContentProvider <NSObject>

/// Fetches the content for the given \c product. After the fetching is completed, the content
/// resides in \c LTPathBaseDirectoryTemp directory.
///
/// Returns a signal that fetches the content of the product. The signal sends a single \c LTPath,
/// which is the path to the content and then completes. The signal errs if there was an error while
/// fetching.
///
/// @return <tt>RACSignal<LTPath></tt>
- (RACSignal *)fetchContentForProduct:(BZRProduct *)product;

/// Returns the class that an instance of the receining class expects to receive from \c product.
+ (Class)expectedParametersClass;

@end

NS_ASSUME_NONNULL_END
