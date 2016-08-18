// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

@protocol BZRDownloadsPaymentQueue;

NS_ASSUME_NONNULL_BEGIN

/// Manager used to download content for transactions.
@interface BZRProductDownloadManager : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c paymentQueue, used to verify that given transactions are in the queue.
/// Setting \c paymentQueue's \c downloadsDelegate after the initialization of the receiver is
/// considered undefined behavior.
- (instancetype)initWithPaymentQueue:(id<BZRDownloadsPaymentQueue>)paymentQueue
    NS_DESIGNATED_INITIALIZER;

/// Downloads the content of \c transaction. Downloading of content is allowed only for transactions
/// with \c SKDownloadStatePurchased or \c SKDownloadStateRestored state. The transaction should
/// also still be in the payment queue.
///
/// Downloads the content for \c transaction by downloading each download from
/// \c transaction.downloads. Returns an array of \c RACSignal objects, each created from a single
/// \c SKDownload from \c transaction.downloads. The signals start the download upon subscription.
/// Each signal sends the corresponding \c SKDownload as values until its state becomes
/// \c SKDownloadStateFinished and then completes. A signal errs if its corresponding download has
/// failed. When subscription to a signal is disposed, its corresponding download is cancelled. The
/// signals will send events only when
/// \c -[BZRPaymentQueueDownloadsDelegate paymentQueue:UpdatedDownloads:] is called with the
/// download found in \c updatedDownloads.
///
/// @return <tt>NSArray<RACSignal<SKDownload>>></tt>
- (NSArray<RACSignal *> *)downloadContentForTransaction:(SKPaymentTransaction *)transaction;

@end

NS_ASSUME_NONNULL_END
