// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "MFMailComposeViewController+Dismissal.h"

NS_ASSUME_NONNULL_BEGIN

@implementation MFMailComposeViewController (Dismissal)

- (nullable LTVoidBlock)spx_dismissBlock {
  return objc_getAssociatedObject(self, @selector(spx_dismissBlock));
}

- (void)setSpx_dismissBlock:(nullable LTVoidBlock)dismissBlock {
  objc_setAssociatedObject(self, @selector(spx_dismissBlock), dismissBlock,
                           OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

NS_ASSUME_NONNULL_END
