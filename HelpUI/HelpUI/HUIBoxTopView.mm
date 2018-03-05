// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Daniel Hadar.

#import "HUIBoxTopView.h"

#import <Wireframes/UIImageView+ViewModel.h>
#import <Wireframes/WFGradientView.h>
#import <Wireframes/WFImageViewModelBuilder.h>

#import "HUIBoxTopLayout.h"

NS_ASSUME_NONNULL_BEGIN

@interface HUIBoxTopView ()

/// View that shows the title.
@property (readonly, nonatomic) UILabel *titleLabel;

/// View that shows an icon taken from \c iconURL.
@property (readonly, nonatomic) UIImageView *iconImageView;

/// View that shows the body.
@property (readonly, nonatomic) UILabel *bodyLabel;

/// View that shows a gradient as the background of this view.
@property (readonly, nonatomic) WFGradientView *gradientView;

/// Current layout of this view.
@property (readonly, nonatomic) HUIBoxTopLayout *layout;

@end

@implementation HUIBoxTopView

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithFrame:(CGRect)frame {
  if (self = [super initWithFrame:frame]) {
    [self setup];
  }
  return self;
}

- (void)layoutSubviews {
  [super layoutSubviews];

  _layout = [[HUIBoxTopLayout alloc] initWithBounds:self.bounds title:self.title body:self.body
                                            hasIcon:self.iconURL != nil];
  self.titleLabel.frame = self.layout.titleFrame;
  self.bodyLabel.frame = self.layout.bodyFrame;
  self.iconImageView.frame = self.layout.iconFrame;
  self.titleLabel.attributedText = self.layout.titleAttributedString;
  self.bodyLabel.attributedText = self.layout.bodyAttributedString;

  [self invalidateIntrinsicContentSize];
}

- (CGSize)intrinsicContentSize {
  return CGSizeMake(UIViewNoIntrinsicMetric, self.layout.intrinsicHeight);
}

- (void)setup {
  [self setupGradientView];
  [self setupTitleLabel];
  [self setupIconImageView];
  [self setupBodyLabel];
}

#pragma mark -
#pragma mark Content View
#pragma mark -

- (void)setupGradientView {
  auto topColor = [HUISettings instance].titleBoxGradientTopColor;
  auto bottomColor = [HUISettings instance].titleBoxGradientBottomColor;
  _gradientView = [WFGradientView verticalGradientWithTopColor:topColor bottomColor:bottomColor];
  self.gradientView.startPoint = CGPointMake(0.5, 0.25);
  self.gradientView.endPoint = CGPointMake(0.5, 0.75);
  self.gradientView.autoresizingMask =
      UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
  [self addSubview:self.gradientView];
}

#pragma mark -
#pragma mark Title Container View
#pragma mark -

- (void)setupTitleLabel {
  _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
  self.titleLabel.accessibilityIdentifier = @"Title";
  self.titleLabel.numberOfLines = 0;
  self.titleLabel.textAlignment = NSTextAlignmentCenter;
  [self addSubview:self.titleLabel];
}

- (void)setupIconImageView {
  _iconImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
  self.iconImageView.accessibilityIdentifier = @"Icon";
  self.iconImageView.contentMode = UIViewContentModeScaleAspectFill;
  [self addSubview:self.iconImageView];

  @weakify(self);
  RAC(self, iconImageView.wf_viewModel) =
    [RACObserve(self, iconURL) map:^id<WFImageViewModel>(NSURL * _Nullable url) {
      @strongify(self);
      return WFImageViewModel(url)
          .color([HUISettings instance].titleBoxIconColor)
          .highlightedColor([HUISettings instance].titleBoxHighlightedIconColor)
          .sizeToBounds(self.iconImageView)
          .build();
      }];
}

#pragma mark -
#pragma mark Body View
#pragma mark -

- (void)setupBodyLabel {
  _bodyLabel = [[UILabel alloc] initWithFrame:CGRectZero];
  self.bodyLabel.accessibilityIdentifier = @"Body";
  self.bodyLabel.numberOfLines = 0;
  self.bodyLabel.textAlignment = NSTextAlignmentCenter;
  [self addSubview:self.bodyLabel];
}

#pragma mark -
#pragma mark Public
#pragma mark -

+ (CGFloat)boxTopHeightForTitle:(nullable NSString *)title body:(nullable NSString *)body
                        iconURL:(nullable NSURL *)iconURL width:(CGFloat)boxTopWidth {
  auto layout = [[HUIBoxTopLayout alloc] initWithBounds:CGRectMake(0, 0, boxTopWidth, 0) title:title
                                                   body:body hasIcon:iconURL != nil];
  return layout.intrinsicHeight;
}

#pragma mark -
#pragma mark Properties
#pragma mark -

- (void)setTitle:(nullable NSString *)title {
  if ((!_title && !title) || [_title isEqualToString:title]) {
    return;
  }
  _title = title;
  [self setNeedsLayout];
}

- (void)setBody:(nullable NSString *)body {
  if ((!_body && !body) || [_body isEqualToString:body]) {
    return;
  }
  _body = body;
  [self setNeedsLayout];
}

- (void)setIconURL:(nullable NSURL *)iconURL {
  if ((!_iconURL && !iconURL) || [_iconURL isEqual:iconURL]) {
    return;
  }
  _iconURL = iconURL;
  [self setNeedsLayout];
}

@end

NS_ASSUME_NONNULL_END
