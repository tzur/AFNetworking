// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Alex Gershovich.

#import "UIButton+ViewModel.h"

#import "UIView+LayoutSignals.h"
#import "WFImageViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@implementation UIButton (ViewModel)

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
  RACSignal<UIImage *> *highlightedImage  = [RACObserve(viewModel, highlightedImage)
      takeUntil:unbindTrigger];

  @weakify(self);
  RACDisposable *imagesDisposable = [[[RACSignal
      combineLatest:@[image, highlightedImage]]
      distinctUntilChanged]
      subscribeNext:^(RACTuple *values) {
        @strongify(self);
        RACTupleUnpack(UIImage * _Nullable image, UIImage * _Nullable highlightedImage) = values;

        [self setImage:image forState:UIControlStateNormal];
        [self setImage:highlightedImage forState:UIControlStateHighlighted];
        [self setImage:highlightedImage forState:UIControlStateSelected];
        [self setImage:highlightedImage
              forState:UIControlStateSelected | UIControlStateHighlighted];
      }];

  return [[RACDisposable disposableWithBlock:^{
    [imagesDisposable dispose];
    [unbindTrigger sendCompleted];
  }] asScopedDisposable];
}

@end

NS_ASSUME_NONNULL_END
