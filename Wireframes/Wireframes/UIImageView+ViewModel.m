// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Alex Gershovich.

#import "UIImageView+ViewModel.h"

#import "UIView+LayoutSignals.h"
#import "WFImageViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@implementation UIImageView (ViewModel)

- (nullable id<WFImageViewModel>)wf_viewModel {
  return objc_getAssociatedObject(self, @selector(wf_viewModel));
}

static const void *kBindingDisposableKey = &kBindingDisposableKey;

- (void)setWf_viewModel:(nullable id<WFImageViewModel>)wf_viewModel {
  if (wf_viewModel == self.wf_viewModel) {
    return;
  }

  [self willChangeValueForKey:@keypath(self, wf_viewModel)];

  RACDisposable * _Nullable bindingDisposable =
      objc_getAssociatedObject(self, kBindingDisposableKey);
  [bindingDisposable dispose];

  objc_setAssociatedObject(self, @selector(wf_viewModel), wf_viewModel,
                           OBJC_ASSOCIATION_RETAIN_NONATOMIC);

  bindingDisposable = wf_viewModel ? [self wf_bindViewModel:wf_viewModel] : nil;
  objc_setAssociatedObject(self, kBindingDisposableKey, bindingDisposable,
                           OBJC_ASSOCIATION_RETAIN_NONATOMIC);

  [self didChangeValueForKey:@keypath(self, wf_viewModel)];
}

- (RACDisposable *)wf_bindViewModel:(id<WFImageViewModel>)viewModel {
  RACSubject *unbindTrigger = [RACSubject subject];

  RACSignal<UIImage *> *image = [RACObserve(viewModel, image) takeUntil:unbindTrigger];
  RACSignal<UIImage *> *highlightedImage = [RACObserve(viewModel, highlightedImage)
      takeUntil:unbindTrigger];

  @weakify(self);
  RACDisposable *imagesDisposable = [[[RACSignal
      combineLatest:@[image, highlightedImage]]
      distinctUntilChanged]
      subscribeNext:^(RACTuple *values) {
        @strongify(self);
        RACTupleUnpack(UIImage * _Nullable image, UIImage * _Nullable highlightedImage) = values;

        // UIImageView has a curious bug where in highlighted state, changes of highlightedImage are
        // not visible, until the highlighted state changes further. A solution is to force a reset
        // of the state.
        BOOL resetHighlightedState = self.highlighted &&
            (self.highlightedImage != highlightedImage);

        void (^updateBlock)(void) = ^{
          self.image = image;
          self.highlightedImage = highlightedImage;

          if (resetHighlightedState) {
            self.highlighted = NO;
            self.highlighted = YES;
          }
        };

        if (viewModel.isAnimated) {
          [UIView transitionWithView:self duration:viewModel.animationDuration
                             options:UIViewAnimationOptionTransitionCrossDissolve
                          animations:updateBlock
                          completion:nil];
        } else {
          updateBlock();
        }
      }];

  return [[RACDisposable disposableWithBlock:^{
    [unbindTrigger sendCompleted];
    [imagesDisposable dispose];
  }] asScopedDisposable];
}

@end

NS_ASSUME_NONNULL_END
