// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Reuven Siman Tov.

#import "CUIDropDownView.h"

#import "CUIDropDownEntry.h"

NS_ASSUME_NONNULL_BEGIN

@interface CUIDropDownView ()

/// \c UIStackView that arranges the entries' \c mainBarItemView horizontally.
@property (readonly, nonatomic) UIStackView *stackView;

@end

@implementation CUIDropDownView

- (instancetype)initWithFrame:(CGRect)frame {
  if (self = [super initWithFrame:frame]) {
    _entries = @[];
    [self setupStackView];
  }
  return self;
}

- (void)setupStackView {
  _stackView = [[UIStackView alloc] initWithFrame:CGRectZero];
  [self addSubview:self.stackView];
  [self.stackView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.edges.equalTo(self);
  }];
  self.stackView.alignment = UIStackViewAlignmentCenter;
  self.stackView.distribution = UIStackViewDistributionEqualSpacing;
  self.stackView.axis = UILayoutConstraintAxisHorizontal;
}

- (void)hideDropDownViews {
  [self updateSubmenusHiddenStateForTappedEntry:nil];
}

- (void)setEntries:(NSArray *)entries {
  _entries = [entries copy];
  [self removeEntries];
  [self setupEntries];
}

- (void)removeEntries {
  for (UIView *view in self.stackView.arrangedSubviews) {
    [view removeFromSuperview];
  }
}

- (void)setupEntries {
  for (id<CUIDropDownEntry> entry in self.entries) {
    [self.stackView addArrangedSubview:entry.mainBarItemView];
    [entry.mainBarItemView mas_makeConstraints:^(MASConstraintMaker *make) {
      make.height.equalTo(self);
      make.width.greaterThanOrEqualTo(self.mas_height);
    }];
    @weakify(self);
    [entry.didTapSignal subscribeNext:^(RACTuple *tuple) {
      @strongify(self);
      [self updateSubmenusHiddenStateForTappedEntry:tuple.first];
    }];
    entry.submenuView.hidden = YES;
  }
}

- (void)updateSubmenusHiddenStateForTappedEntry:(nullable id<CUIDropDownEntry>)tappedEntry {
  for (id<CUIDropDownEntry> entry in self.entries) {
    entry.submenuView.hidden = (entry != tappedEntry) ? YES : !entry.submenuView.hidden;
  }
}

#pragma mark -
#pragma mark UIView
#pragma mark -

- (nullable UIView *)hitTest:(CGPoint)point withEvent:(nullable UIEvent *)event {
  if (CGRectContainsPoint(self.bounds, point)) {
    return [super hitTest:point withEvent:event];
  }
  for (id<CUIDropDownEntry> entry in self.entries) {
    CGPoint submenuPoint = [entry.submenuView convertPoint:point fromView:self];
    if ([entry.submenuView pointInside:submenuPoint withEvent:event]) {
      return [entry.submenuView hitTest:submenuPoint withEvent:event];
    }
  }
  return nil;
}

@end

NS_ASSUME_NONNULL_END
