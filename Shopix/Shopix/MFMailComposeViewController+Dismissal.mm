// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "MFMailComposeViewController+Dismissal.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark -
#pragma mark SPXMailComposeViewControllerDelegate
#pragma mark -

/// Delegate that forwards \c MFMailComposeViewControllerDelegate messages.
///
/// @note Acts similar to \c RACDelegateProxy. \c RACDelegateProxy is not used here since it fails
/// to correctly encode the signature of the delegate method because it contains an enum argument.
@interface SPXMailComposeViewControllerDelegate : NSObject <MFMailComposeViewControllerDelegate>

/// Delegate to which messages should be forwarded.
@property (weak, nonatomic, nullable) id<MFMailComposeViewControllerDelegate> proxiedDelegate;

@end

@implementation SPXMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController *)controller
          didFinishWithResult:(MFMailComposeResult)result error:(nullable NSError *)error {
  if (error) {
    LogError(@"Failed composing mail with mail compose result status: %lu, error: %@",
             (unsigned long)result, error);
  }

  [self.proxiedDelegate mailComposeController:controller didFinishWithResult:result error:error];
  [self requestDismiss];
}

- (void)requestDismiss {
  // Handled with \c rac_signalForSelector:.
}

@end

#pragma mark -
#pragma mark MFMailComposeViewController+Dismissal
#pragma mark -

@implementation MFMailComposeViewController (Dismissal)

static void SPXUseDelegateProxy(MFMailComposeViewController *self) {
  if (self.mailComposeDelegate == self.spx_delegateProxy) {
    return;
  }

  self.spx_delegateProxy.proxiedDelegate = self.mailComposeDelegate;
  self.mailComposeDelegate = (id)self.spx_delegateProxy;
}

- (SPXMailComposeViewControllerDelegate *)spx_delegateProxy {
  SPXMailComposeViewControllerDelegate *proxy = objc_getAssociatedObject(self, _cmd);
  if (!proxy) {
    proxy = [[SPXMailComposeViewControllerDelegate alloc] init];
    objc_setAssociatedObject(self, _cmd, proxy, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  }

  return proxy;
}

#pragma mark -
#pragma mark Properties
#pragma mark -

- (RACSignal *)dismissRequested {
  SPXUseDelegateProxy(self);
  return [[self.spx_delegateProxy rac_signalForSelector:@selector(requestDismiss)]
          mapReplace:[RACUnit defaultUnit]];
}

@end

NS_ASSUME_NONNULL_END
