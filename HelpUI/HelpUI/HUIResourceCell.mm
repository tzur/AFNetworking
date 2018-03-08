// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Daniel Hadar.

#import "HUIResourceCell.h"

#import "HUIBoxView.h"
#import "HUIResourceCell+Protected.h"

NS_ASSUME_NONNULL_BEGIN

@interface HUIResourceCell ()

/// Layer used for drawing shadow behind the cell.
@property (readonly, nonatomic) CALayer *shadowLayer;

@end

@implementation HUIResourceCell

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithFrame:(CGRect)frame {
  if (self = [super initWithFrame:frame]) {
    [self setupShadow];
    [self setupBoxView];
  }
  return self;
}

- (void)setupShadow {
  _shadowLayer = [CALayer layer];
  self.shadowLayer.backgroundColor = [HUISettings instance].boxShadowBackgroundColor.CGColor;
  self.shadowLayer.shadowColor = [HUISettings instance].boxShadowColor.CGColor;
  self.shadowLayer.shadowOffset = CGSizeMake(0, 0);
  self.shadowLayer.shadowOpacity = 0.95f;
  self.shadowLayer.shadowRadius = 16.0f;
  self.shadowLayer.zPosition = self.layer.zPosition - 1;
  [self.layer addSublayer:self.shadowLayer];
}

- (void)setupBoxView {
  _boxView = [[HUIBoxView alloc] initWithFrame:CGRectZero];
  self.boxView.accessibilityIdentifier = @"Box";
  [self.contentView addSubview:self.boxView];
  [self.boxView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.edges.equalTo(self.contentView);
  }];
}

#pragma mark -
#pragma mark UIView
#pragma mark -

- (void)layoutSubviews {
  [super layoutSubviews];
  [self updateShadowPathWithBounds:self.bounds];
}

- (void)updateShadowPathWithBounds:(CGRect)bounds {
  self.shadowLayer.frame = bounds;

  auto origin =
      self.shadowLayer.bounds.origin + self.shadowLayer.bounds.size * CGSizeMake(0.1, 0.7);
  auto size = self.shadowLayer.bounds.size * CGSizeMake(0.8, 0.3);
  auto shadowRect = CGRectFromOriginAndSize(origin, size);
  self.shadowLayer.shadowPath = [UIBezierPath bezierPathWithRect:shadowRect].CGPath;
}

#pragma mark -
#pragma mark Public
#pragma mark -

+ (CGFloat)cellHeightForTitle:(nullable NSString *)title body:(nullable NSString *)body
                      iconURL:(nullable NSURL *)iconURL width:(CGFloat)cellWidth {
  return [HUIBoxView boxHeightForTitle:title body:body iconURL:iconURL width:cellWidth];
}

@end

NS_ASSUME_NONNULL_END
