// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

NS_ASSUME_NONNULL_BEGIN

/// Protocol for providing content of products.
@protocol BZRProductContentProvider

/// Fetches the content for the given \c productIdentifier. After the fetching is completed, the
/// content resides in \c LTPathBaseDirectoryTemp directory.
///
/// Returns a signal that fetches the content according to \c productIdentifier. The signal sends a
/// single \c LTPath, which is the path to the content and then completes. The signal errs if there
/// was an error in fetching.
///
/// @return <tt>RACSignal<LTPath></tt>
- (RACSignal *)fetchContentForProduct:(NSString *)productIdentifier;

@end

NS_ASSUME_NONNULL_END
