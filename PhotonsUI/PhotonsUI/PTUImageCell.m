// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTUImageCell.h"

#import "PTUImageCellViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTUImageCell ()

/// Image view to display image in.
@property (readonly, nonatomic) UIImageView *imageView;

/// Label for main title.
@property (readonly, nonatomic) UILabel *titleLabel;

/// Label for supplementary subtitle.
@property (readonly, nonatomic) UILabel *subtitleLabel;

/// Grouping of both title and subtitle labels for layout purposes.
@property (readonly, nonatomic) UIView *labelsView;

@end

@implementation PTUImageCell

- (instancetype)initWithFrame:(CGRect)frame {
  if (self = [super initWithFrame:frame]) {
    [self setup];
  }
  return self;
}

#pragma mark -
#pragma mark Setup
#pragma mark -

- (void)setup {
  self.backgroundColor = [UIColor darkGrayColor];
  [self bindViewModel];
  [self setupImageView];
  [self setupLabels];
}

- (void)setupLabels {
  static const CGFloat kHorizontalOffsetFactor = 0.1;

  UIView *leftMargin = [[UIView alloc] initWithFrame:CGRectZero];
  [self.contentView addSubview:leftMargin];
  [leftMargin mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.equalTo(self.imageView.mas_right);
    make.width.equalTo(self.imageView).multipliedBy(kHorizontalOffsetFactor);
  }];

  UIView *rightMargin = [[UIView alloc] initWithFrame:CGRectZero];
  [self.contentView addSubview:rightMargin];
  [rightMargin mas_makeConstraints:^(MASConstraintMaker *make) {
    make.right.equalTo(self.contentView);
    make.width.equalTo(self.imageView).multipliedBy(kHorizontalOffsetFactor);
  }];

  _labelsView = [[UIView alloc] initWithFrame:CGRectZero];
  [self.contentView addSubview:self.labelsView];
  [self.labelsView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.equalTo(leftMargin.mas_right);
    make.right.equalTo(rightMargin.mas_left);
    make.centerY.equalTo(self.contentView);
  }];

  [self setupTitleLabel];
  [self setupSubtitleLabel];
}

- (void)setupTitleLabel {
  _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
  self.titleLabel.textColor = [UIColor lightGrayColor];
  [self.labelsView addSubview:self.titleLabel];

  [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.right.bottom.equalTo(self.labelsView);
  }];
}

- (void)setupSubtitleLabel {
  _subtitleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
  self.subtitleLabel.textColor = [UIColor lightGrayColor];
  [self.labelsView addSubview:self.subtitleLabel];

  [self.subtitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.right.top.equalTo(self.labelsView);
  }];
}

- (void)setupImageView {
  _imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
  self.imageView.contentMode = UIViewContentModeScaleAspectFill;
  self.imageView.clipsToBounds = YES;
  self.imageView.backgroundColor = [UIColor grayColor];
  [self.contentView addSubview:self.imageView];

  [self.imageView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.width.height.equalTo(self.contentView.mas_height);
    make.top.left.equalTo(self.contentView);
  }];
}

#pragma mark -
#pragma mark Update
#pragma mark -

- (void)layoutSubviews {
  [super layoutSubviews];
  [self updateLabels];
}

- (void)updateLabels {
  self.labelsView.hidden = [self shouldHideText];

  [self updateTitleLabel];
  [self updateSubtitleLabel];
}

- (void)updateTitleLabel {
  self.titleLabel.font = [self titleFont];
}

- (void)updateSubtitleLabel {
  self.subtitleLabel.font = [self subtitleFont];
}

- (UIFont *)titleFont {
  static const CGFloat kTitleFontFactor = 0.19;
  return [UIFont italicSystemFontOfSize:self.contentView.bounds.size.height * kTitleFontFactor];
}

- (UIFont *)subtitleFont {
  static const CGFloat kSubtitleFontFactor = 0.17;
  return [UIFont italicSystemFontOfSize:self.contentView.bounds.size.height * kSubtitleFontFactor];
}

- (BOOL)shouldHideText {
  return (self.contentView.frame.size.width /
      (self.contentView.frame.size.height + FLT_EPSILON)) < 2.0;
}

- (void)prepareForReuse {
  [super prepareForReuse];
  self.viewModel = nil;
}

#pragma mark -
#pragma mark View model
#pragma mark -

- (void)bindViewModel {
  RAC(self, imageView.image) = RACObserve(self, viewModel.image);
  RAC(self, titleLabel.text) = RACObserve(self, viewModel.title);
  RAC(self, subtitleLabel.text) = RACObserve(self, viewModel.subtitle);
}

#pragma mark -
#pragma mark Current attributes
#pragma mark -

- (nullable NSString *)title {
  return self.titleLabel.text;
}

- (nullable NSString *)subtitle {
  return self.subtitleLabel.text;
}

- (nullable UIImage *)image {
  return self.imageView.image;
}

@end

NS_ASSUME_NONNULL_END
