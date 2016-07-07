// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTUImageCellView.h"

#import <LTKit/LTCGExtensions.h>

#import "PTUImageCellViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTUImageCellView ()

/// Image view to display image in.
@property (readonly, nonatomic) UIImageView *imageView;

/// Label for main title.
@property (readonly, nonatomic) UILabel *titleLabel;

/// Label for supplementary subtitle.
@property (readonly, nonatomic) UILabel *subtitleLabel;

/// Grouping of both title and subtitle labels for layout purposes.
@property (readonly, nonatomic) UIView *labelsView;

/// Manual disposal handle for the image signal of the \c viewModel.
@property (strong, nonatomic) RACDisposable *imageSignalDisposable;

/// Manual disposal handle for the title signal of the \c viewModel.
@property (strong, nonatomic) RACDisposable *titleSignalDisposable;

/// Manual disposal handle for the subtitle signal of the \c viewModel.
@property (strong, nonatomic) RACDisposable *subtitleSignalDisposable;

/// Current view size in points stored to avoid unnecessary work when size did not change.
@property (nonatomic) CGSize currentSize;

@end

@implementation PTUImageCellView

- (instancetype)initWithFrame:(CGRect)frame {
  if (self = [super initWithFrame:frame]) {
    [self setup];
  }
  return self;
}

- (void)dealloc {
  [self.imageSignalDisposable dispose];
  [self.titleSignalDisposable dispose];
  [self.subtitleSignalDisposable dispose];
}

#pragma mark -
#pragma mark Setup
#pragma mark -

- (void)setup {
  [self setupImageView];
  [self setupLabels];
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

- (void)setupImageView {
  _imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
  self.imageView.contentMode = UIViewContentModeScaleAspectFill;
  self.imageView.clipsToBounds = YES;
  [self addSubview:self.imageView];
}

#pragma mark -
#pragma mark Update
#pragma mark -

- (void)layoutSubviews {
  [super layoutSubviews];
  if (self.currentSize == self.bounds.size) {
    return;
  }
  self.currentSize = self.bounds.size;

  [self updateImageView];
  [self updateLabels];
  [self replaceImageSignalBinding];
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
#pragma mark View model
#pragma mark -

- (void)setViewModel:(nullable id<PTUImageCellViewModel>)viewModel {
  _viewModel = viewModel;
  [self.titleSignalDisposable dispose];
  [self.subtitleSignalDisposable dispose];

  if (!viewModel) {
    self.titleLabel.text = nil;
    self.subtitleLabel.text = nil;
  }

  @weakify(self);
  self.titleSignalDisposable = [[viewModel.titleSignal
      deliverOnMainThread]
      subscribeNext:^(NSString *title) {
        @strongify(self);
        self.titleLabel.text = title;
      } error:^(NSError *) {
        @strongify(self);
        self.titleLabel.text = nil;
      }];

  self.subtitleSignalDisposable = [[viewModel.subtitleSignal
      deliverOnMainThread]
      subscribeNext:^(NSString *subtitle) {
        @strongify(self);
        self.subtitleLabel.text = subtitle;
      } error:^(NSError *) {
        @strongify(self);
        self.subtitleLabel.text = nil;
      }];

  
  if (!CGSizeEqualToSize(self.bounds.size, CGSizeZero)) {
    [self replaceImageSignalBindingAndClearImageView];
  }
}

- (void)replaceImageSignalBindingAndClearImageView {
  [self.imageSignalDisposable dispose];
  self.imageView.image = nil;
  [self bindImageSignal];
}

- (void)replaceImageSignalBinding {
  [self.imageSignalDisposable dispose];
  [self bindImageSignal];
}

- (void)bindImageSignal {
  @weakify(self);
  self.imageSignalDisposable = [[[self.viewModel imageSignalForCellSize:[self pixelSize]]
      deliverOnMainThread]
      subscribeNext:^(UIImage *image) {
        @strongify(self);
        self.imageView.image = image;
      } error:^(NSError *) {
        @strongify(self);
        self.imageView.image = nil;
      }];
}

- (CGSize)pixelSize {
  return self.bounds.size * [self contentScaleFactor];
}

- (CGFloat)contentScaleFactor {
  return [UIScreen mainScreen].scale;
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
