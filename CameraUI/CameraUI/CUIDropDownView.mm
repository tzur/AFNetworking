// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Reuven Siman Tov.

#import "CUIDropDownView.h"

#import "CUIDropDownEntry.h"

NS_ASSUME_NONNULL_BEGIN

@interface CUIDropDownView ()

/// List of \c CUIDropDownEntry that this view shows.
@property (readonly, nonatomic) NSArray<id<CUIDropDownEntry>> *entries;

/// \c UIStackView that arranges the entries' \c mainBarItemView horizontally.
@property (readonly, nonatomic) UIStackView *stackView;

@end

@implementation CUIDropDownView

- (instancetype)initWithEntries:(NSArray<id<CUIDropDownEntry>> *)entries {
  LTParameterAssert(entries, @"entries is nil");
  if (self = [super initWithFrame:CGRectZero]) {
    _entries = entries;
    [self setupStackView];
    [self setupEntries];
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

- (void)setupEntries {
  for (id<CUIDropDownEntry> entry in self.entries) {
    [self.stackView addArrangedSubview:entry.mainBarItemView];
    [entry.mainBarItemView mas_makeConstraints:^(MASConstraintMaker *make) {
      make.height.equalTo(self);
      make.width.greaterThanOrEqualTo(self.mas_height);
    }];
    @weakify(self);
    [entry.didTapSignal subscribeNext:^(RACTuple * __unused tuple) {
      @strongify(self);
      [self updateSubmenusHiddenStateForTappedEntry:entry];
    }];
    entry.submenuView.hidden = YES;
  }
}

- (void)updateSubmenusHiddenStateForTappedEntry:(id<CUIDropDownEntry>)tappedEntry {
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
