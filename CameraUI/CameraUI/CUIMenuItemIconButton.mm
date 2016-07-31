// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Reuven Siman Tov.

#import "CUIMenuItemIconButton.h"

#import <Wireframes/UIButton+ViewModel.h>
#import <Wireframes/UIView+LayoutSignals.h>
#import <Wireframes/WFImageViewModelBuilder.h>

#import "CUIMenuItemViewModel.h"
#import "CUISharedTheme.h"

NS_ASSUME_NONNULL_BEGIN

@implementation CUIMenuItemIconButton

@synthesize model = _model;

- (instancetype)initWithModel:(id<CUIMenuItemViewModel>)model {
  LTParameterAssert(model, @"model is nil.");
  if (self = [super initWithFrame:CGRectZero]) {
    _model = model;
    [self setup];
  }
  return self;
}

- (void)setup {
  RAC(self, hidden) = [RACObserve(self, model.hidden) deliverOnMainThread];
  RAC(self, selected) = [RACObserve(self, model.selected) deliverOnMainThread];
  RAC(self, enabled) = [RACObserve(self, model.enabled) deliverOnMainThread];
  [self addTarget:self.model action:@selector(didTap) forControlEvents:UIControlEventTouchUpInside];
  [self setupImageViewModel];
}

- (void)setupImageViewModel {
  RAC(self, wf_viewModel) = [[RACObserve(self, model.iconURL)
      map:^id<WFImageViewModel>(NSURL *url) {
        id<CUITheme> theme = [CUISharedTheme sharedTheme];
        return WFImageViewModel(url)
            .color(theme.iconColor)
            .highlightedColor(theme.iconHighlightedColor)
            .sizeSignal(self.wf_positiveSizeSignal)
            .build();
      }]
      deliverOnMainThread];
}

@end

NS_ASSUME_NONNULL_END
