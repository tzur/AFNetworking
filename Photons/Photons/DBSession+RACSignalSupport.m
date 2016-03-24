// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "DBSession+RACSignalSupport.h"

#import <objc/runtime.h>

NS_ASSUME_NONNULL_BEGIN

@implementation DBSession (RACSignalSupport)

static void RACUseDelegateProxy(DBSession *self) {
  if (self.delegate == (id<DBSessionDelegate>)self.ptn_delegateProxy) {
    return;
  }

  self.ptn_delegateProxy.rac_proxiedDelegate = self.delegate;
  self.delegate = (id)self.ptn_delegateProxy;
}

- (RACDelegateProxy *)ptn_delegateProxy {
  RACDelegateProxy *proxy = objc_getAssociatedObject(self, _cmd);
  if (proxy == nil) {
    proxy = [[RACDelegateProxy alloc] initWithProtocol:@protocol(DBSessionDelegate)];
    objc_setAssociatedObject(self, _cmd, proxy, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  }

  return proxy;
}

- (RACSignal *)ptn_authorizationFailureSignal {
  RACSignal *signal = [[[[self.ptn_delegateProxy
      signalForSelector:@selector(sessionDidReceiveAuthorizationFailure:userId:)]
      reduceEach:^(DBSession * __unused session, NSString *userId) {
        return userId;
      }]
      takeUntil:self.rac_willDeallocSignal]
      setNameWithFormat:@"%@ -rac_authorizationFailureSignal", self];
  
  RACUseDelegateProxy(self);
  
  return signal;
}

@end

NS_ASSUME_NONNULL_END
