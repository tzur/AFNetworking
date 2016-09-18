// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Reuven Siman Tov.

#import "CUIDropDownHorizontalView.h"

#import "CUIDropDownEntryViewModel.h"
#import "CUIMenuItemView.h"
#import "CUIMenuItemViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface CUIDropDownHorizontalView ()

/// \c UIStackView that arranges the entries' \c mainBarItemView horizontally.
@property (readonly, nonatomic) UIStackView *mainBarStackView;

/// View that serves as left margin for \c mainBarStackView.
@property (readonly, nonatomic) UIView *leftMarginView;

/// View that serves as right margin for \c mainBarStackView.
@property (readonly, nonatomic) UIView *rightMarginView;

/// View that serves as left margin for the submenus.
@property (readonly, nonatomic) UIView *submenuLeftMarginView;

/// View that serves as right margin for the submenus.
@property (readonly, nonatomic) UIView *submenuRightMarginView;

/// List of drop down submenu views.
@property (readonly, nonatomic) NSMutableArray<UIView *> *submenus;

/// Mapping from item view boxed in \c NSValue to its submenu.
@property (readonly, nonatomic) NSMutableDictionary<NSValue *, UIView *> *itemViewsToSubmenuViews;

@end

@implementation CUIDropDownHorizontalView

static const CGFloat kDefaultMaxMainBarWidth = 450;

- (instancetype)initWithFrame:(CGRect)frame {
  if (self = [super initWithFrame:frame]) {
    _entries = @[];
    _itemViewsToSubmenuViews = [NSMutableDictionary dictionary];
    _submenus = [NSMutableArray array];
    _maxMainBarWidth = kDefaultMaxMainBarWidth;
    self.submenuBackgroundColor = [UIColor clearColor];
    [self setupMainBarStackView];
    [self setupMarginViews];
    [self remakeMainBarStackViewConstraints];
    [self remakeMarginViewsConstraints];
    [self remakeSubmenuMarginViewsConstraints];
  }
  return self;
}

#pragma mark -
#pragma mark Main bar stack view
#pragma mark -

- (void)setupMainBarStackView {
  _mainBarStackView = [[UIStackView alloc] initWithFrame:CGRectZero];
  [self addSubview:self.mainBarStackView];
  self.mainBarStackView.accessibilityIdentifier = @"MainBarStackView";
  self.mainBarStackView.alignment = UIStackViewAlignmentCenter;
  self.mainBarStackView.distribution = UIStackViewDistributionEqualSpacing;
  self.mainBarStackView.axis = UILayoutConstraintAxisHorizontal;
}

- (void)remakeMainBarStackViewConstraints {
  [self.mainBarStackView mas_remakeConstraints:^(MASConstraintMaker *make) {
    make.top.bottom.centerX.equalTo(self);
    make.width.lessThanOrEqualTo(@(self.maxMainBarWidth)).priorityHigh();
    make.left.equalTo(self.leftMarginView.mas_right).priorityLow();
    make.right.equalTo(self.rightMarginView.mas_left).priorityLow();
  }];
}

#pragma mark -
#pragma mark Margin views
#pragma mark -

- (void)setupMarginViews {
  _leftMarginView = [[UIView alloc] initWithFrame:CGRectZero];
  [self addSubview:self.leftMarginView];
  _rightMarginView = [[UIView alloc] initWithFrame:CGRectZero];
  [self addSubview:self.rightMarginView];
  _submenuLeftMarginView = [[UIView alloc] initWithFrame:CGRectZero];
  [self addSubview:self.submenuLeftMarginView];
  _submenuRightMarginView = [[UIView alloc] initWithFrame:CGRectZero];
  [self addSubview:self.submenuRightMarginView];
}

- (void)remakeMarginViewsConstraints {
  [self.leftMarginView mas_remakeConstraints:^(MASConstraintMaker *make) {
    make.left.top.bottom.equalTo(self);
    make.width.equalTo(@(self.lateralMargins));
  }];
  [self.rightMarginView mas_remakeConstraints:^(MASConstraintMaker *make) {
    make.right.top.bottom.equalTo(self);
    make.width.equalTo(@(self.lateralMargins));
  }];
}

- (void)remakeSubmenuMarginViewsConstraints {
  [self.submenuLeftMarginView mas_remakeConstraints:^(MASConstraintMaker *make) {
    make.left.height.equalTo(self);
    make.top.equalTo(self.mas_bottom);
    make.right.equalTo(self.mainBarStackView.mas_left).with.offset(self.submenuLateralMargins);
  }];
  [self.submenuRightMarginView mas_remakeConstraints:^(MASConstraintMaker *make) {
    make.right.height.equalTo(self);
    make.top.equalTo(self.mas_bottom);
    make.left.equalTo(self.mainBarStackView.mas_right).with.offset(-self.submenuLateralMargins);
  }];
}

#pragma mark -
#pragma mark Hide drop down views
#pragma mark -

- (void)hideDropDownViews {
  [self handleSubmenusHiddenStateForSelectedSubmenu:nil];
}

- (void)handleSubmenusHiddenStateForSelectedSubmenu:(nullable UIView *)selectedSubmenu {
  for (UIView *submenu in self.submenus) {
    submenu.hidden = (submenu != selectedSubmenu) ? YES : !submenu.hidden;
  }
}

#pragma mark -
#pragma mark Entries
#pragma mark -

- (void)setEntries:(NSArray *)entries {
  [self validateEntries:entries];
  [self removeEntries];
  _entries = [entries copy];
  [self setupEntries];
}

- (void)validateEntries:(NSArray *)entries {
  for (CUIDropDownEntryViewModel *entry in entries) {
    LTAssert(!entry.mainBarItem.subitems ||
             [entry.mainBarItemViewClass isSubclassOfClass:[UIControl class]],
             @"Main bar item view with subitems must be kind of UIControl.");
  }
}

- (void)removeEntries {
  for (UIView *view in self.mainBarStackView.arrangedSubviews) {
    [view removeFromSuperview];
  }
  for (UIView *submenuView in self.submenus) {
    [submenuView removeFromSuperview];
  }
  [self.submenus removeAllObjects];
  [self.itemViewsToSubmenuViews removeAllObjects];
}

- (void)setupEntries {
  [self.entries enumerateObjectsUsingBlock:^(CUIDropDownEntryViewModel *entry, NSUInteger idx,
                                             BOOL *) {
    UIView *mainBarItemView = [self setupMainItemForEntry:entry];
    UIView *submenu = [self setupSubmenuForEntryInNeeded:entry withIndex:idx];
    if (submenu) {
      self.itemViewsToSubmenuViews[[NSValue valueWithNonretainedObject:mainBarItemView]] = submenu;
    }
  }];
}

#pragma mark -
#pragma mark Main bar item
#pragma mark -

- (UIView *)setupMainItemForEntry:(CUIDropDownEntryViewModel *)entry {
  UIView *mainBarItemView = [self itemViewForMenuItem:entry.mainBarItem
                                            viewClass:entry.mainBarItemViewClass];
  [self.mainBarStackView addArrangedSubview:mainBarItemView];
  [self makeConstraintForItemView:mainBarItemView];
  return mainBarItemView;
}

- (UIView *)itemViewForMenuItem:(id<CUIMenuItemViewModel>)menuItem viewClass:(Class)viewClass {
  UIView *menuItemView = (UIView *)[(id<CUIMenuItemView>)[viewClass alloc] initWithModel:menuItem];
  [self setupControlEventsForItemViewIfNeeded:menuItemView];
  return menuItemView;
}

- (void)setupControlEventsForItemViewIfNeeded:(UIView *)itemView {
  if ([itemView isKindOfClass:[UIControl class]]) {
    [self setupControlEventsForItemView:itemView];
  }
}

- (void)setupControlEventsForItemView:(UIView *)itemView {
  [(UIControl *)itemView addTarget:self action:@selector(didTapMenuItemView:)
                  forControlEvents:UIControlEventTouchUpInside];
}

- (void)didTapMenuItemView:(UIView *)menuItemView {
  NSValue *key = [NSValue valueWithNonretainedObject:menuItemView];
  [self handleSubmenusHiddenStateForSelectedSubmenu:self.itemViewsToSubmenuViews[key]];
}

- (void)makeConstraintForItemView:(UIView *)itemView {
  [itemView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.height.equalTo(self);
    make.width.greaterThanOrEqualTo(self.mas_height);
  }];
}

#pragma mark -
#pragma mark Submenu
#pragma mark -

- (nullable UIView *)setupSubmenuForEntryInNeeded:(CUIDropDownEntryViewModel *)entry
                                        withIndex:(NSUInteger)idx {
  if (!entry.mainBarItem.subitems) {
    return nil;
  }
  return [self setupSubmenuForEntry:entry withIndex:idx];
}

- (UIView *)setupSubmenuForEntry:(CUIDropDownEntryViewModel *)entry  withIndex:(NSUInteger)idx {
  UIView *submenu = [self createSubmenuViewWithIndex:idx];
  UIStackView *stackView = [self stackViewForSubmenuView:submenu];
  [self setupSubmenuItemsForEntry:entry submenu:submenu stackView:stackView];
  return submenu;
}

- (UIView *)createSubmenuViewWithIndex:(NSUInteger)idx {
  UIView *submenu = [[UIView alloc] init];
  submenu.accessibilityIdentifier =
      [NSString stringWithFormat:@"SubmenuView#%ld", (unsigned long)idx];
  [self addSubview:submenu];
  [self.submenus addObject:submenu];
  submenu.hidden = YES;
  [submenu mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.right.height.equalTo(self);
    make.top.equalTo(self.mas_bottom);
  }];
  RAC(submenu, backgroundColor) = RACObserve(self, submenuBackgroundColor);
  return submenu;
}

- (UIStackView *)stackViewForSubmenuView:(UIView *)submenu {
  UIStackView *stackView = [[UIStackView alloc] initWithFrame:CGRectZero];
  stackView.accessibilityIdentifier = @"SubmenuStackView";
  [submenu addSubview:stackView];
  [stackView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.bottom.equalTo(submenu);
    make.left.equalTo(self.submenuLeftMarginView.mas_right);
    make.right.equalTo(self.submenuRightMarginView.mas_left);
  }];
  stackView.alignment = UIStackViewAlignmentCenter;
  stackView.distribution = UIStackViewDistributionEqualSpacing;
  stackView.axis = UILayoutConstraintAxisHorizontal;
  return stackView;
}

- (void)setupSubmenuItemsForEntry:(CUIDropDownEntryViewModel *)entry submenu:(UIView *)submenu
                        stackView:(UIStackView *)stackView {
  for (id<CUIMenuItemViewModel>  menuItem in entry.mainBarItem.subitems) {
    UIView *menuItemView = [self itemViewForMenuItem:menuItem
                                           viewClass:entry.submenuItemsViewClass];

    [stackView addArrangedSubview:menuItemView];
    [self makeConstraintForItemView:menuItemView];
    self.itemViewsToSubmenuViews[[NSValue valueWithNonretainedObject:menuItemView]] = submenu;
  };
}

#pragma mark -
#pragma mark Properties
#pragma mark -

- (void)setMaxMainBarWidth:(CGFloat)maxMainBarWidth {
  _maxMainBarWidth = maxMainBarWidth;
  [self remakeMainBarStackViewConstraints];
}

- (void)setLateralMargins:(CGFloat)lateralMargins {
  _lateralMargins = lateralMargins;
  [self remakeMarginViewsConstraints];
}

- (void)setSubmenuLateralMargins:(CGFloat)submenuLateralMargins {
  _submenuLateralMargins = submenuLateralMargins;
  [self remakeSubmenuMarginViewsConstraints];
}

#pragma mark -
#pragma mark UIView
#pragma mark -

- (nullable UIView *)hitTest:(CGPoint)point withEvent:(nullable UIEvent *)event {
  if (CGRectContainsPoint(self.bounds, point)) {
    return [super hitTest:point withEvent:event];
  }
  for (UIView *submenuView in self.submenus) {
    if (submenuView.hidden) {
      continue;
    }
    CGPoint submenuPoint = [submenuView convertPoint:point fromView:self];
    if ([submenuView pointInside:submenuPoint withEvent:event]) {
      return [submenuView hitTest:submenuPoint withEvent:event];
    }
  }
  return nil;
}

@end

NS_ASSUME_NONNULL_END
