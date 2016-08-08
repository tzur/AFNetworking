// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "SKReceiptRefreshRequest+RACSignalSupport.h"

#import <ReactiveCocoa/RACDelegateProxy.h>

#import "NSError+Bazaar.h"
#import "NSErrorCodes+Bazaar.h"

NS_ASSUME_NONNULL_BEGIN

@implementation SKReceiptRefreshRequest (RACSignalSupport)

static void RACUseDelegateProxy(SKReceiptRefreshRequest *self) {
  if (self.delegate == self.bzr_delegateProxy) {
    return;
  }

  self.bzr_delegateProxy.rac_proxiedDelegate = self.delegate;
  self.delegate = (id)self.bzr_delegateProxy;
}

- (RACDelegateProxy *)bzr_delegateProxy {
  RACDelegateProxy *proxy = objc_getAssociatedObject(self, _cmd);
  if (!proxy) {
    proxy = [[RACDelegateProxy alloc] initWithProtocol:@protocol(SKRequestDelegate)];
    objc_setAssociatedObject(self, _cmd, proxy, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  }

  return proxy;
}

- (RACSignal *)bzr_statusSignal {
  RACSignal *signal = [[self.bzr_errorSignal takeUntil:self.bzr_completionSignal]
      setNameWithFormat:@"%@ -bzr_statusSignal", self.description];
  RACUseDelegateProxy(self);

  return signal;
}

// A signal that sends a value when the request invokes \c requestDidFinsih: on its delegate. It
// completes when the proxy delegate deallocs and never errs.
- (RACSignal *)bzr_completionSignal {
  return [self.bzr_delegateProxy signalForSelector:@selector(requestDidFinish:)];
}

// A signal that only errs or completes, it does not send any values. It errs when the reuqest
// invokes \c request:didFailWithError: on its delegate and completes when the proxy delegate
// deallocs.
- (RACSignal *)bzr_errorSignal {
  return [[self.bzr_delegateProxy signalForSelector:@selector(request:didFailWithError:)]
      flattenMap:^RACStream *(RACTuple *parameters) {
        NSError *error = [NSError lt_errorWithCode:BZRErrorCodeReceiptRefreshFailed
                                   underlyingError:parameters.second];
        return [RACSignal error:error];
      }];
}

@end

NS_ASSUME_NONNULL_END
