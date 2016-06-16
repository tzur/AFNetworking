// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Lior Bar.

#import "CUIIconWithTitleCell.h"

#import <Wireframes/UIImageView+ViewModel.h>
#import <Wireframes/WFImageViewModelBuilder.h>

#import "CUIMenuItemViewModel.h"
#import "CUISharedTheme.h"

NS_ASSUME_NONNULL_BEGIN

@interface CUIIconWithTitleCell ()

/// Shows the menu item's label.
@property (readonly, nonatomic) UILabel *titleLabel;

/// Shows the menu item's icon.
@property (readonly, nonatomic) UIImageView *iconView;

@end

@implementation CUIIconWithTitleCell

@synthesize viewModel = _viewModel;

- (instancetype)initWithFrame:(CGRect)frame {
  if (self = [super initWithFrame:frame]) {
    [self setup];
  }
  return self;
}

- (void)setup {
  self.backgroundColor = [CUISharedTheme sharedTheme].menuBackgroundColor;
  [self setupTitleLabel];
  [self setupIconView];
  [self setupViewModel];
}

- (void)setupTitleLabel {
  _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
  self.titleLabel.textColor =[CUISharedTheme sharedTheme].titleColor;
  self.titleLabel.highlightedTextColor = [CUISharedTheme sharedTheme].titleHighlightedColor;
  self.titleLabel.font = [CUISharedTheme sharedTheme].titleFont;
  self.titleLabel.textAlignment = NSTextAlignmentCenter;

  [self.contentView addSubview:self.titleLabel];
}

- (void)setupIconView {
  _iconView = [[UIImageView alloc] initWithFrame:CGRectZero];
  [self.contentView addSubview:self.iconView];
}

#pragma mark -
#pragma mark View model
#pragma mark -

- (void)setupViewModel {
  [self setupViewModelLabel];
  [self setupViewModelIcon];
}

- (void)setupViewModelLabel {
  RAC(self.titleLabel, text) = [RACObserve(self, viewModel.title) deliverOnMainThread];
  RAC(self.titleLabel, highlighted, @NO) = [RACObserve(self, viewModel.selected)
      deliverOnMainThread];
}

- (void)setupViewModelIcon {
  @weakify(self);
  RAC(self.iconView, wf_viewModel) = [[RACObserve(self, viewModel.iconURL)
      map:^id<WFImageViewModel>(NSURL *iconURL) {
        @strongify(self);
        return WFImageViewModel(iconURL)
               .color([CUISharedTheme sharedTheme].iconColor)
               .highlightedColor([CUISharedTheme sharedTheme].iconHighlightedColor)
               .sizeToBounds(self.iconView)
               .build();
      }]
      deliverOnMainThread];
  RAC(self.iconView, highlighted, @NO) = [RACObserve(self, viewModel.selected) deliverOnMainThread];
}

- (void)setSelected:(BOOL __unused)selected {
  // Selected is only derived from the model. This method is empty since calling the default
  // \c setSelected will also set the inner views selected state.
}

- (void)setHighlighted:(BOOL __unused)highlighted {
  // Highlight is only derived from the model. This method is empty since calling the default
  // \c setHighlighted will also set the inner views highlighted state.
}

#pragma mark -
#pragma mark Layout
#pragma mark -

- (void)layoutSubviews {
  [super layoutSubviews];

  [self layoutTitleAndIcon];
}

static const CGFloat kIconEdgeLength = 44;
static const CGFloat kIconTitleSpace = 2;
static const CGFloat kTextHeight = 17;

- (void)layoutTitleAndIcon {
  CGFloat cellHeight = self.bounds.size.height;
  CGFloat cellWidth = self.bounds.size.width;
  CGFloat topSpacing = std::floor(0.5 * (cellHeight - kIconEdgeLength - kIconTitleSpace -
      kTextHeight));
  CGPoint iconCenter = CGPointMake(std::floor(0.5 * cellWidth), topSpacing +
      std::floor(0.5 * kIconEdgeLength));
  self.iconView.frame = CGRectCenteredAt(iconCenter, CGSizeMakeUniform(kIconEdgeLength));
  self.titleLabel.frame = CGRectMake(0, topSpacing + kIconEdgeLength + kIconTitleSpace,
      cellWidth, kTextHeight);
}

@end

NS_ASSUME_NONNULL_END
