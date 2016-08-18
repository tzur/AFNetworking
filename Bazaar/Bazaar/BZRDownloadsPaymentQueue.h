// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

NS_ASSUME_NONNULL_BEGIN

@protocol BZRPaymentQueueDownloadsDelegate;

/// \c BZRDownlodsPaymentQueue provides an interface for downloading content and sending updates
/// regarding the downloads.
@protocol BZRDownloadsPaymentQueue <NSObject>

/// Starts downloading the content from each download in \c downloads. Will initiate sending updates
/// of downloads to \c downloadsDelegate.
- (void)startDownloads:(NSArray<SKDownload *> *)downloads;

/// Cancels downloading the content from each download in \c downloads.
- (void)cancelDownloads:(NSArray<SKDownload *> *)downloads;

/// Array of unfinished transactions created by the underlying \c SKPaymentQueue.
@property (readonly, nonatomic) NSArray<SKPaymentTransaction *> *transactions;

/// Delegate that will be receiving update regarding content downloads.
@property (weak, nonatomic, nullable) id<BZRPaymentQueueDownloadsDelegate> downloadsDelegate;

@end

/// Protocol for delegates that want to to receive updates regarding product content downloads.
@protocol BZRPaymentQueueDownloadsDelegate <NSObject>

/// Invoked when \c paymentQueue informs its delegates that the state of downloads in \c downloads
/// was updated.
- (void)paymentQueue:(id<BZRDownloadsPaymentQueue>)paymentQueue
    updatedDownloads:(NSArray<SKDownload *> *)downloads;

@end

NS_ASSUME_NONNULL_END
