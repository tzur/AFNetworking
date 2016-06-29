// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Reuven Siman Tov.

#import "CUIDropDownMenuItemsEntry.h"

#import "CUIMenuItemButton.h"
#import "CUIMenuItemViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface CUIDropDownMenuItemsEntry ()

/// Main view-model of this entry.
@property (readonly, nonatomic) id<CUIMenuItemViewModel> item;

/// \c UIStackView that arranges the views that show the \c subitems.
@property (readonly, nonatomic, nullable) UIStackView *stackView;

@end

@implementation CUIDropDownMenuItemsEntry

@synthesize mainBarItemView = _mainBarItemView;
@synthesize didTapSignal = _didTapSignal;

- (instancetype)initWithItem:(id<CUIMenuItemViewModel>)item
        mainBarItemViewClass:(Class)mainBarItemViewClass
        submenuItemViewClass:(Class)submenuItemViewClass {
  LTParameterAssert(item, @"item is nil");
  LTParameterAssert([self validateItemViewClass:mainBarItemViewClass],
                    @"invalid itemViewClass: %@", mainBarItemViewClass);
  LTParameterAssert([self validateItemViewClass:submenuItemViewClass],
                    @"invalid submenuItemViewClass %@", submenuItemViewClass);
  if (self = [super init]) {
    _item = item;
    [self setupMainBarItemViewWithViewClass:mainBarItemViewClass];
    [self setupSubmenuViewWithItemsViewClass:submenuItemViewClass];
    [self setupDidTapSignal];
  }
  return self;
}

- (BOOL)validateItemViewClass:(Class)itemViewClass {
  return [itemViewClass conformsToProtocol:@protocol(CUIMenuItemButton)] &&
      [itemViewClass isSubclassOfClass:[UIButton class]];
}

- (void)setupMainBarItemViewWithViewClass:(Class)mainBarItemViewClass  {
  // Casting because the compiler does not find self.item as valid type for initWithModel.
  UIButton<CUIMenuItemButton> *itemButton =
      [(UIButton<CUIMenuItemButton> *)[mainBarItemViewClass alloc] initWithModel:self.item];
  [itemButton addTarget:self action:@selector(didTap:)
       forControlEvents:UIControlEventTouchUpInside];
  _mainBarItemView = itemButton;
}

- (void)setupSubmenuViewWithItemsViewClass:(Class)itemViewClass {
  if (!self.item.subitems) {
    return;
  }
  [self setupStackView];
  [self addSubmenuItemsWithViewClass:itemViewClass];
}

- (void)setupStackView {
  _stackView = [[UIStackView alloc] initWithFrame:CGRectZero];
  [self.mainBarItemView addSubview:self.stackView];
  self.stackView.alignment = UIStackViewAlignmentCenter;
  self.stackView.distribution = UIStackViewDistributionEqualSpacing;
  self.stackView.axis = UILayoutConstraintAxisVertical;
  [self.stackView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(self.mainBarItemView.mas_bottom);
    make.centerX.equalTo(self.mainBarItemView);
    make.width.greaterThanOrEqualTo(self.mainBarItemView);
  }];
}

- (void)addSubmenuItemsWithViewClass:(Class)itemViewClass {
  for (id<CUIMenuItemViewModel> item in self.item.subitems) {
    UIButton<CUIMenuItemButton> *itemButton = [[itemViewClass alloc] initWithModel:item];
    [itemButton addTarget:self action:@selector(didTap:)
         forControlEvents:UIControlEventTouchUpInside];
    [self.stackView addArrangedSubview:itemButton];
    [itemButton mas_makeConstraints:^(MASConstraintMaker *make) {
      make.width.greaterThanOrEqualTo(self.mainBarItemView);
      make.height.equalTo(self.mainBarItemView);
    }];
  }
}

- (void)didTap:(UIButton * __unused)button {
  // Observed by \c didTapSignal.
}

- (void)setupDidTapSignal {
  @weakify(self);
  _didTapSignal = [[self rac_signalForSelector:@selector(didTap:)]
      reduceEach:(id)^RACTuple *(UIButton * button) {
        @strongify(self);
        return RACTuplePack(self, button);
      }];
}

#pragma mark -
#pragma mark CUIDropDownEntry
#pragma mark -

- (nullable UIView *)submenuView {
  return self.stackView;
}

@end

NS_ASSUME_NONNULL_END
