// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRProductDownloadManager.h"

#import "BZRFakePaymentTransaction.h"
#import "BZRPaymentQueueAdapter.h"

/// Fake \c SKDownload with a mutable \c downloadState.
@interface BZRFakeDownload : SKDownload

/// State of the download.
@property (readwrite, nonatomic) SKDownloadState downloadState;

/// Error in the download in case of failure.
@property (readwrite, nonatomic) NSError *error;

@end

@implementation BZRFakeDownload
@synthesize downloadState = _downloadState;
@synthesize error = _error;
@end

@interface BZRProductDownloadManager (ForTesting) <BZRPaymentQueueDownloadsDelegate>
@end

/// Fake \c BZRDownloadsPaymentQueue with mutable \c transactions and functionality to inspect input
/// of its methods.
@interface BZRFakeDownloadsPaymentQueue : NSObject <BZRDownloadsPaymentQueue>

/// Mutable array of transactions.
@property (readwrite, nonatomic) NSArray<SKPaymentTransaction *> *transactions;

/// \c YES if \c startDownloads was called, \c NO otherwise.
@property (readonly, nonatomic) BOOL wasStartDownloadsCalled;

/// Array of \c SKDownloads with which \c canceDownloads was called. \c nil if \c canceDownloads was
/// never called.
@property (readonly, nonatomic, nullable) NSArray<SKDownload *> *cancelledDownloads;

@end

@implementation BZRFakeDownloadsPaymentQueue

@synthesize downloadsDelegate = _downloadsDelegate;

- (void)startDownloads:(NSArray<SKDownload *> __unused *)downloads {
  _wasStartDownloadsCalled = YES;
}

- (void)cancelDownloads:(NSArray<SKDownload *> *)downloads {
  _cancelledDownloads = downloads;
}

@end

SpecBegin(BZRProductDownloadManager)

__block BZRFakeDownloadsPaymentQueue *paymentQueue;
__block BZRFakePaymentTransaction *paymentTransaction;

beforeEach(^{
  paymentQueue = [[BZRFakeDownloadsPaymentQueue alloc] init];
  paymentTransaction = [[BZRFakePaymentTransaction alloc] init];
});

context(@"deallocating object", ^{
  it(@"should complete when object is deallocated", ^{
    BZRProductDownloadManager __weak *weakDownloadManager;
    LLSignalTestRecorder *recorder;

    paymentTransaction.transactionState = SKPaymentTransactionStatePurchased;
    paymentQueue.transactions = @[paymentTransaction];
    BZRFakeDownload *download = [[BZRFakeDownload alloc] init];
    paymentTransaction.downloads = @[download];

    @autoreleasepool {
      BZRProductDownloadManager *downloadManager =
          [[BZRProductDownloadManager alloc] initWithPaymentQueue:paymentQueue];
      weakDownloadManager = downloadManager;
      recorder =
          [[[downloadManager downloadContentForTransaction:paymentTransaction]
          firstObject] testRecorder];
    }

    expect(weakDownloadManager).to.beNil();
    expect(recorder).will.complete();
  });
});

context(@"downloading content for transaction", ^{
  __block BZRProductDownloadManager *downloadManager;

  beforeEach(^{
    downloadManager = [[BZRProductDownloadManager alloc] initWithPaymentQueue:paymentQueue];
  });

  it(@"should raise exception when transaction isn't completed", ^{
    paymentTransaction.transactionState = SKPaymentTransactionStatePurchasing;
    expect(^{
      [downloadManager downloadContentForTransaction:paymentTransaction];
    }).to.raise(NSInvalidArgumentException);

    paymentTransaction.transactionState = SKPaymentTransactionStateFailed;
    expect(^{
      [downloadManager downloadContentForTransaction:paymentTransaction];
    }).to.raise(NSInvalidArgumentException);

    paymentTransaction.transactionState = SKPaymentTransactionStateDeferred;
    expect(^{
      [downloadManager downloadContentForTransaction:paymentTransaction];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise exception when transaction isn't found in payment queue", ^{
    paymentTransaction.transactionState = SKPaymentTransactionStatePurchased;

    expect(^{
      [downloadManager downloadContentForTransaction:paymentTransaction];
    }).to.raise(NSInvalidArgumentException);
  });

  context(@"unfinished transaction", ^{
    __block BZRFakeDownload *download;

    beforeEach(^{
      paymentTransaction.transactionState = SKPaymentTransactionStatePurchased;
      paymentQueue.transactions = @[paymentTransaction];
      download = [[BZRFakeDownload alloc] init];
      paymentTransaction.downloads = @[download];
    });

    it(@"should send download for every call to delegate and complete when download finishes", ^{
      [[[downloadManager downloadContentForTransaction:paymentTransaction]
          firstObject] testRecorder];

      expect(paymentQueue.wasStartDownloadsCalled).to.beTruthy();
    });

    it(@"should send download for every call to delegate and complete when download finishes", ^{
      LLSignalTestRecorder *recorder =
          [[[downloadManager downloadContentForTransaction:paymentTransaction]
          firstObject] testRecorder];

      download.downloadState = SKDownloadStateActive;
      [downloadManager paymentQueue:paymentQueue updatedDownloads:paymentTransaction.downloads];
      [downloadManager paymentQueue:paymentQueue updatedDownloads:paymentTransaction.downloads];
      download.downloadState = SKDownloadStateFinished;
      [downloadManager paymentQueue:paymentQueue updatedDownloads:paymentTransaction.downloads];

      expect(recorder).will.complete();
      expect(recorder).will.sendValues(@[download, download, download]);
    });

    it(@"should not send cancelled download", ^{
      LLSignalTestRecorder *recorder =
          [[[downloadManager downloadContentForTransaction:paymentTransaction]
          firstObject] testRecorder];

      download.downloadState = SKDownloadStateCancelled;
      [downloadManager paymentQueue:paymentQueue updatedDownloads:paymentTransaction.downloads];
      download.downloadState = SKDownloadStateFinished;
      [downloadManager paymentQueue:paymentQueue updatedDownloads:paymentTransaction.downloads];

      expect(recorder).will.complete();
      expect(recorder).will.sendValues(@[download]);
    });

    it(@"should call cancel downloads when subscriber is disposed", ^{
      RACSignal *signal =
          [[downloadManager downloadContentForTransaction:paymentTransaction] firstObject];
      [[signal subscribeNext:^(SKDownload __unused *download) {
      }] dispose];

      expect(paymentQueue.cancelledDownloads).to.equal(@[download]);
    });

    it(@"should err when download has failed", ^{
      LLSignalTestRecorder *recorder =
          [[[downloadManager downloadContentForTransaction:paymentTransaction]
          firstObject] testRecorder];

      download.downloadState = SKDownloadStateFailed;
      download.error = [NSError lt_errorWithCode:1337];
      [downloadManager paymentQueue:paymentQueue updatedDownloads:paymentTransaction.downloads];

      expect(recorder).will.sendError(download.error);
    });

    it(@"should send download through the correct signal", ^{
      BZRFakeDownload *secondDownload = [[BZRFakeDownload alloc] init];
      paymentTransaction.downloads = @[download, secondDownload];
      NSArray<RACSignal *> *downloadsSignals =
          [downloadManager downloadContentForTransaction:paymentTransaction];
      LLSignalTestRecorder *firstRecorder = [[downloadsSignals firstObject] testRecorder];
      LLSignalTestRecorder *secondRecorder = [[downloadsSignals lastObject] testRecorder];

      secondDownload.downloadState = SKDownloadStateActive;
      [downloadManager paymentQueue:paymentQueue updatedDownloads:@[secondDownload]];
      download.downloadState = SKDownloadStateFinished;
      [downloadManager paymentQueue:paymentQueue updatedDownloads:@[download, secondDownload]];

      expect(firstRecorder).will.complete();
      expect(firstRecorder).will.sendValues(@[download]);

      secondDownload.downloadState = SKDownloadStateFinished;
      [downloadManager paymentQueue:paymentQueue updatedDownloads:@[download, secondDownload]];

      expect(secondRecorder).will.complete();
      expect(secondRecorder).will.sendValues(@[secondDownload, secondDownload, secondDownload]);
    });
  });
});

SpecEnd
