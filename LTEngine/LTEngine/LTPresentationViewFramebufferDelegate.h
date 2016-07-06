// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

NS_ASSUME_NONNULL_BEGIN

@class LTPresentationView;

/// Protocol which should be implemented by objects that should be informed about size changes of
/// the framebuffer of an \c LTPresentationView.
@protocol LTPresentationViewFramebufferDelegate <NSObject>

@optional

/// Notifies the delegate that the size of the framebuffer used by the given \c presentationView has
/// changed.
- (void)presentationView:(LTPresentationView *)view framebufferChangedToSize:(CGSize)size;

@end

NS_ASSUME_NONNULL_END
