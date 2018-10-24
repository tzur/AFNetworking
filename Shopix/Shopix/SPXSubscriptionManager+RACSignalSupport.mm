// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "SPXSubscriptionManager+RACSignalSupport.h"

#import <Bazaar/NSErrorCodes+Bazaar.h>

NS_ASSUME_NONNULL_BEGIN

@implementation SPXSubscriptionManager (RACSignalSupport)

#pragma mark -
#pragma mark Operations
#pragma mark -

- (RACSignal<NSDictionary<NSString *, BZRProduct *> *> *)fetchProductsInfo:
    (NSSet<NSString *> *)productIdentifiers {
  @weakify(self);
  return [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber> subscriber) {
    @strongify(self);
    if (!self) {
      [subscriber sendCompleted];
      return nil;
    }

    [self fetchProductsInfo:productIdentifiers
          completionHandler:^(NSDictionary<NSString *,BZRProduct *> * _Nullable productsInfo,
                              NSError * _Nullable error) {
            if (error) {
              [subscriber sendError:error];
              return;
            } else if (productsInfo) {
              [subscriber sendNext:productsInfo];
            }

            [subscriber sendCompleted];
          }];

    return nil;
  }];
}

- (RACSignal<BZRReceiptSubscriptionInfo *> *)purchaseSubscription:(NSString *)productIdentifier {
  @weakify(self);
  return [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber> subscriber) {
    @strongify(self);
    if (!self) {
      [subscriber sendCompleted];
      return nil;
    }

    [self purchaseSubscription:productIdentifier
             completionHandler:^(BZRReceiptSubscriptionInfo * _Nullable subscriptionInfo,
                                 NSError * _Nullable error) {
               if (error && error.code != BZRErrorCodeOperationCancelled &&
                   error.code != BZRErrorCodePurchaseNotAllowed) {
                 [subscriber sendError:error];
                 return;
               } else if (subscriptionInfo) {
                 [subscriber sendNext:subscriptionInfo];
               }

               [subscriber sendCompleted];
             }];
    return nil;
  }];
}

- (RACSignal<BZRReceiptInfo *> *)restorePurchases {
  @weakify(self);
  return [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber> subscriber) {
    @strongify(self);
    if (!self) {
      [subscriber sendCompleted];
      return nil;
    }

    [self restorePurchasesWithCompletionHandler:^(BZRReceiptInfo * _Nullable receiptInfo,
                                                  NSError * _Nullable error) {
      if (error && error.code != BZRErrorCodeOperationCancelled) {
        [subscriber sendError:error];
        return;
      } else if (receiptInfo) {
        [subscriber sendNext:receiptInfo];
      }

      [subscriber sendCompleted];
    }];
    return nil;
  }];
}

#pragma mark -
#pragma mark Delegate Replacement
#pragma mark -

static void RACUseDelegateProxy(SPXSubscriptionManager *self) {
  if (self.delegate == self.spx_delegateProxy) {
    return;
  }

  self.spx_delegateProxy.rac_proxiedDelegate = self.delegate;
  self.delegate = (id)self.spx_delegateProxy;
}

- (RACDelegateProxy *)spx_delegateProxy {
  RACDelegateProxy *proxy = objc_getAssociatedObject(self, _cmd);
  if (!proxy) {
    proxy = [[RACDelegateProxy alloc] initWithProtocol:@protocol(SPXSubscriptionManagerDelegate)];
    objc_setAssociatedObject(self, _cmd, proxy, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  }

  return proxy;
}

- (RACSignal<id<SPXAlertViewModel>> *)alertRequested {
  RACUseDelegateProxy(self);
  return [[[self spx_delegateProxy]
      signalForSelector:@selector(presentAlertWithViewModel:)]
      map:^id<SPXAlertViewModel>(RACTuple *parameters) {
        return nn(parameters.first);
      }];
}

- (RACSignal<LTVoidBlock> *)feedbackMailComposerRequested {
  RACUseDelegateProxy(self);
  return [[[self spx_delegateProxy]
      signalForSelector:@selector(presentFeedbackMailComposerWithCompletionHandler:)]
      map:^LTVoidBlock(RACTuple *parameters) {
        return nn(parameters.first);
      }];
}

@end

NS_ASSUME_NONNULL_END
