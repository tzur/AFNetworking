// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Daniel Hadar.

#import "HUIBoxView.h"

#import <Wireframes/WFTransparentView.h>

#import "HUIBoxTopView.h"

NS_ASSUME_NONNULL_BEGIN

@interface HUIBoxView ()

/// Top view of a help box which displays \c title, \c body and \c iconURL.
@property (readonly, nonatomic) HUIBoxTopView *boxTopView;

@end

@implementation HUIBoxView

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithFrame:(CGRect)frame {
  if (self = [super initWithFrame:frame]) {
    [self setup];
  }
  return self;
}

- (void)setup {
  [self setupBackground];
  [self setupBoxTopView];
  [self setupContentView];
}

- (void)setupBackground {
  self.backgroundColor = [HUISettings instance].boxBackgroundColor;
  self.layer.cornerRadius = 6;
  self.clipsToBounds = YES;
}

- (void)setupBoxTopView {
  _boxTopView = [[HUIBoxTopView alloc] initWithFrame:CGRectZero];
  self.boxTopView.accessibilityIdentifier = @"BoxTop";
  [self addSubview:self.boxTopView];

  [self.boxTopView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.width.centerX.top.equalTo(self);
  }];
}

- (void)setupContentView {
  _contentView = [[WFTransparentView alloc] initWithFrame:CGRectZero];
  [self addSubview:self.contentView];

  [self.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.right.bottom.equalTo(self);
    make.top.equalTo(self.boxTopView.mas_bottom);
    make.height.equalTo(self.contentView.mas_width).
        multipliedBy(1 / [HUISettings instance].contentAspectRatio);
  }];
}

#pragma mark -
#pragma mark Public
#pragma mark -

+ (CGFloat)boxHeightForTitle:(nullable NSString *)title body:(nullable NSString *)body
                     iconURL:(nullable NSURL *)iconURL width:(CGFloat)boxWidth {
  auto boxTopHeight = [HUIBoxTopView boxTopHeightForTitle:title body:body iconURL:iconURL
                                                    width:boxWidth];
  return boxTopHeight + boxWidth / [HUISettings instance].contentAspectRatio;
}

#pragma mark -
#pragma mark Properties
#pragma mark -

- (void)setTitle:(nullable NSString *)title {
  _title = title;
  self.boxTopView.title = title;
}

- (void)setBody:(nullable NSString *)body {
  _body = body;
  self.boxTopView.body = body;
}

- (void)setIconURL:(nullable NSURL *)iconURL {
  _iconURL = iconURL;
  self.boxTopView.iconURL = iconURL;
}

@end

NS_ASSUME_NONNULL_END
