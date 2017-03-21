// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTUImageCellView.h"

#import <LTKit/LTCGExtensions.h>

#import "PTUImageCellController.h"
#import "PTUImageCellViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTUImageCellView () <PTUImageCellControllerDelegate>

/// Image view to display image in.
@property (readonly, nonatomic) UIImageView *imageView;

/// Label for main title.
@property (readonly, nonatomic) UILabel *titleLabel;

/// Label for supplementary subtitle.
@property (readonly, nonatomic) UILabel *subtitleLabel;

/// Grouping of both title and subtitle labels for layout purposes.
@property (readonly, nonatomic) UIView *labelsView;

/// Controller handling view model signal management.
@property (readonly, nonatomic) PTUImageCellController *imageCellController;

@end

@implementation PTUImageCellView

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
  [self setupImageCellController];
  [self setupImageView];
  [self setupLabels];
}

- (void)setupImageCellController {
  _imageCellController = [[PTUImageCellController alloc] init];
  self.imageCellController.delegate = self;
}

- (void)setupImageView {
  _imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
  self.imageView.contentMode = UIViewContentModeScaleAspectFill;
  self.imageView.clipsToBounds = YES;
  [self addSubview:self.imageView];
}

- (void)setupLabels {
  _labelsView = [[UIView alloc] initWithFrame:CGRectZero];
  [self addSubview:self.labelsView];

  [self setupTitleLabel];
  [self setupSubtitleLabel];
}

- (void)setupTitleLabel {
  _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
  self.titleLabel.textColor = [UIColor lightGrayColor];
  [self.labelsView addSubview:self.titleLabel];
}

- (void)setupSubtitleLabel {
  _subtitleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
  self.subtitleLabel.textColor = [UIColor lightGrayColor];
  [self.labelsView addSubview:self.subtitleLabel];
}

#pragma mark -
#pragma mark Update
#pragma mark -

- (void)layoutSubviews {
  [super layoutSubviews];
  self.imageCellController.imageSize = [self pixelSize];

  [self updateImageView];
  [self updateLabels];
}

- (CGSize)pixelSize {
  return self.bounds.size * [self contentScaleFactor];
}

- (CGFloat)contentScaleFactor {
  return [UIScreen mainScreen].scale;
}

- (void)updateImageView {
  self.imageView.frame = CGRectFromSize(CGSizeMakeUniform(self.bounds.size.height));
}

- (void)updateLabels {
  self.labelsView.hidden = [self shouldHideText];

  [self updateTitleLabel];
  [self updateSubtitleLabel];
}

- (void)updateTitleLabel {
  CGSize viewSize = self.bounds.size;
  self.titleLabel.font = [self titleFont];
  self.titleLabel.frame = CGRectMake(viewSize.height + [self horizontalOffset],
      (viewSize.height / 2.0) - self.titleLabel.font.lineHeight,
      viewSize.width - viewSize.height - ([self horizontalOffset] * 2),
      self.titleLabel.font.lineHeight);

}

- (void)updateSubtitleLabel {
  CGSize viewSize = self.bounds.size;
  self.subtitleLabel.font = [self subtitleFont];
  self.subtitleLabel.frame = CGRectMake(viewSize.height + [self horizontalOffset],
      self.titleLabel.frame.origin.y + self.titleLabel.bounds.size.height,
      viewSize.width - viewSize.height - ([self horizontalOffset] * 2),
      self.subtitleLabel.font.lineHeight);
}

- (CGFloat)horizontalOffset {
  static const CGFloat kHorizontalOffsetFactor = 0.1;
  return self.bounds.size.height * kHorizontalOffsetFactor;
}

- (UIFont *)titleFont {
  static const CGFloat kTitleFontFactor = 0.19;
  return [UIFont italicSystemFontOfSize:self.bounds.size.height * kTitleFontFactor];
}

- (UIFont *)subtitleFont {
  static const CGFloat kSubtitleFontFactor = 0.15;
  return [UIFont italicSystemFontOfSize:self.bounds.size.height * kSubtitleFontFactor];
}

- (BOOL)shouldHideText {
  if (!CGRectGetHeight(self.frame)) {
    return NO;
  }

  return (self.frame.size.width / self.frame.size.height) < 2.0;
}

#pragma mark -
#pragma mark PTUImageCellControllerDelegate
#pragma mark -

- (void)setViewModel:(nullable id<PTUImageCellViewModel>)viewModel {
  self.imageCellController.viewModel = viewModel;
}

- (nullable id<PTUImageCellViewModel>)viewModel {
  return self.imageCellController.viewModel;
}

- (void)imageCellController:(PTUImageCellController __unused *)imageCellController
                loadedImage:(nullable UIImage *)image {
  self.imageView.image = image;
}

- (void)imageCellController:(PTUImageCellController __unused *)imageCellController
                loadedTitle:(nullable NSString *)title {
  self.titleLabel.text = title;
}

- (void)imageCellController:(PTUImageCellController __unused *)imageCellController
             loadedSubtitle:(nullable NSString *)subtitle {
  self.subtitleLabel.text = subtitle;
}

- (void)imageCellController:(PTUImageCellController __unused *)imageCellController
          errorLoadingImage:(nonnull NSError __unused *)error {
  self.imageView.image = nil;
}

- (void)imageCellController:(PTUImageCellController __unused *)imageCellController
          errorLoadingTitle:(nonnull NSError __unused *)error {
  self.titleLabel.text = nil;
}

- (void)imageCellController:(PTUImageCellController __unused *)imageCellController
       errorLoadingSubtitle:(nonnull NSError __unused *)error {
  self.subtitleLabel.text = nil;
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
