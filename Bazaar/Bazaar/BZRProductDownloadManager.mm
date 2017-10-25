// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "BZRProductDownloadManager.h"

#import <LTKit/NSArray+Functional.h>

#import "BZRDownloadsPaymentQueue.h"

NS_ASSUME_NONNULL_BEGIN

@interface BZRProductDownloadManager () <BZRPaymentQueueDownloadsDelegate>

/// Queue used to start downloads and verify that given transactions are unfinished.
@property (readonly, nonatomic) id<BZRDownloadsPaymentQueue> paymentQueue;

@end

@implementation BZRProductDownloadManager

- (instancetype)initWithPaymentQueue:(id<BZRDownloadsPaymentQueue>)paymentQueue {
  if (self = [super init]) {
    _paymentQueue = paymentQueue;
    self.paymentQueue.downloadsDelegate = self;
  }
  return self;
}

- (NSArray<RACSignal<SKDownload *> *> *)
    downloadContentForTransaction:(SKPaymentTransaction *)transaction {
  LTParameterAssert(transaction.transactionState == SKPaymentTransactionStatePurchased ||
                    transaction.transactionState == SKPaymentTransactionStateRestored,
                    @"Content can only be downloaded for completed transactions, got %@ at state"
                    "%lu", transaction, (unsigned long)transaction.transactionState);
  LTParameterAssert([self.paymentQueue.transactions containsObject:transaction],
                    @"Content can only be downloaded for transactions that are still in the payment"
                    "queue, transaction %@ is not in %@", transaction,
                    self.paymentQueue.transactions);

  return [transaction.downloads lt_map:^RACSignal<SKDownload *> *(SKDownload *download) {
    return [self downloadContent:download];
  }];
}

- (RACSignal<SKDownload *> *)downloadContent:(SKDownload *)download {
  RACSignal<SKDownload *> *updatedDownloadsSignal =
      [[[self rac_signalForSelector:@selector(paymentQueue:updatedDownloads:)]
      filter:^BOOL(RACTuple *parameters) {
        return [(NSArray *)parameters.second containsObject:download];
      }]
      mapReplace:download];

  @weakify(self);
  return [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    @strongify(self);
    [updatedDownloadsSignal subscribeNext:^(SKDownload *download) {
      if (download.downloadState == SKDownloadStateCancelled) {
        return;
      } else if (download.downloadState == SKDownloadStateFailed) {
        [subscriber sendError:download.error];
      } else {
        [subscriber sendNext:download];
        if (download.downloadState == SKDownloadStateFinished) {
          [subscriber sendCompleted];
        }
      }
    }];
    [self.paymentQueue startDownloads:@[download]];
    @weakify(self);
    return [RACDisposable disposableWithBlock:^{
      @strongify(self);
      [self.paymentQueue cancelDownloads:@[download]];
    }];
  }]
  takeUntil:[self rac_willDeallocSignal]];
}

#pragma mark -
#pragma mark BZRPaymentQueueDownloadsDelegate
#pragma mark -

- (void)paymentQueue:(id<BZRDownloadsPaymentQueue> __unused)paymentQueue
    updatedDownloads:(NSArray<SKDownload *> __unused *)downloads {
  // Required by protocol.
}

@end

NS_ASSUME_NONNULL_END
