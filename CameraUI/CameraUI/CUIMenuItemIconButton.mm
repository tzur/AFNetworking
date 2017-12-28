// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Reuven Siman Tov.

#import "CUIMenuItemIconButton.h"

#import <Wireframes/UIButton+ViewModel.h>
#import <Wireframes/UIView+LayoutSignals.h>
#import <Wireframes/WFImageViewModelBuilder.h>

#import "CUIMenuItemViewModel.h"
#import "CUITheme.h"

NS_ASSUME_NONNULL_BEGIN

@implementation CUIMenuItemIconButton

@synthesize model = _model;

- (instancetype)initWithModel:(id<CUIMenuItemViewModel>)model {
  LTParameterAssert(model, @"model is nil.");
  if (self = [super initWithFrame:CGRectZero]) {
    _model = model;
    self.accessibilityIdentifier = model.title;
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
  [self setupImageViewShadow];
}

- (void)setupImageViewModel {
  @weakify(self);
  RAC(self, wf_viewModel) = [[RACObserve(self, model.iconURL)
      deliverOnMainThread]
      map:^id<WFImageViewModel>(NSURL *url) {
        @strongify(self);
        CUITheme *theme = [CUITheme sharedTheme];
        return WFImageViewModel(url)
            .color(theme.iconColor)
            .highlightedColor(theme.iconHighlightedColor)
            .sizeSignal(self.wf_positiveSizeSignal)
            .build();
      }];
}

- (void)setupImageViewShadow {
  auto sharedTheme = [CUITheme sharedTheme];

  if (sharedTheme.iconShadowOpacity > 0) {
    self.imageView.layer.shadowOpacity = sharedTheme.iconShadowOpacity;
    self.imageView.layer.shadowRadius = sharedTheme.iconShadowRadius;
    self.imageView.layer.shadowOffset = sharedTheme.iconShadowOffset;
    self.imageView.layer.shouldRasterize = YES;
    self.imageView.layer.rasterizationScale = UIScreen.mainScreen.scale;
  }
}

- (void)setEnabled:(BOOL)enabled {
  [super setEnabled:enabled];
  self.alpha = enabled ? 1.0 : 0.4;
}

@end

NS_ASSUME_NONNULL_END
