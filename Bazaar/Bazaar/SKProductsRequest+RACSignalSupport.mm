// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "SKProductsRequest+RACSignalSupport.h"

#import "NSError+Bazaar.h"
#import "NSErrorCodes+Bazaar.h"

NS_ASSUME_NONNULL_BEGIN

@implementation SKProductsRequest (RACSignalSupport)

static void RACUseDelegateProxy(SKProductsRequest *self) {
  if (self.delegate == self.bzr_delegateProxy) {
    return;
  }

  self.bzr_delegateProxy.rac_proxiedDelegate = self.delegate;
  self.delegate = (id)self.bzr_delegateProxy;
}

- (RACDelegateProxy *)bzr_delegateProxy {
  RACDelegateProxy *proxy = objc_getAssociatedObject(self, _cmd);
  if (!proxy) {
    proxy = [[RACDelegateProxy alloc] initWithProtocol:@protocol(SKProductsRequestDelegate)];
    objc_setAssociatedObject(self, _cmd, proxy, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  }

  return proxy;
}

- (RACSignal<SKProductsResponse *> *)statusSignal {
  RACSignal<SKProductsResponse *> *signal = [[[RACSignal merge:@[
    self.bzr_responseSignal,
    self.bzr_errorSignal
  ]]
  takeUntil:self.bzr_completionSignal]
  setNameWithFormat:@"%@ -bzr_statusSignal", self.description];

  RACUseDelegateProxy(self);

  return signal;
}

// A signal that sends \c SKProductsResponse values. It completes when the proxy delegate deallocs
// and never errs.
- (RACSignal<SKProductsResponse *> *)bzr_responseSignal {
  return [[self.bzr_delegateProxy signalForSelector:@selector(productsRequest:didReceiveResponse:)]
      map:^SKProductsResponse *(RACTuple *parameters) {
        return parameters.second;
      }];
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
      flattenMap:^(RACTuple *parameters) {
        RACTupleUnpack(SKProductsRequest *request, NSError *error) = parameters;
        error = [NSError bzr_errorWithCode:BZRErrorCodeProductsMetadataFetchingFailed
                           productsRequest:request underlyingError:error];
        return [RACSignal error:error];
      }];
}

@end

NS_ASSUME_NONNULL_END
