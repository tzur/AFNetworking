// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Reuven Siman Tov.

#import "CUIMenuItemTextButton.h"

#import "CUIMenuItemViewModel.h"
#import "CUITheme.h"

NS_ASSUME_NONNULL_BEGIN

@implementation CUIMenuItemTextButton

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
  [self rac_liftSelector:@selector(setTitle:forState:)
    withSignalsFromArray:@[
      [[RACObserve(self, model.title) distinctUntilChanged] deliverOnMainThread],
      [RACSignal return:@(UIControlStateNormal)]
    ]];
  [self setupFontAndColor];
  RAC(self, selected) = [RACObserve(self, model.selected) deliverOnMainThread];
  RAC(self, hidden) = [RACObserve(self, model.hidden) deliverOnMainThread];
  RAC(self, enabled) = [RACObserve(self, model.enabled) deliverOnMainThread];
  [self addTarget:self.model action:@selector(didTap) forControlEvents:UIControlEventTouchUpInside];
}

- (void)setupFontAndColor {
  CUITheme *theme = [CUITheme sharedTheme];
  [self setTitleColor:theme.titleColor forState:UIControlStateNormal];
  [self setTitleColor:theme.titleHighlightedColor forState:UIControlStateSelected];
  [self setTitleColor:theme.titleHighlightedColor forState:UIControlStateHighlighted];
  self.titleLabel.font = theme.titleFont;
  RAC(self, titleLabel.font) = [RACObserve(self, selected)
      map:^UIFont *(NSNumber *selected) {
        return selected.boolValue ? theme.titleHighlightedFont : theme.titleFont;
      }];
}

- (void)setEnabled:(BOOL)enabled {
  [super setEnabled:enabled];
  self.alpha = enabled ? 1.0 : 0.4;
}

@end

NS_ASSUME_NONNULL_END
