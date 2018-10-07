// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "SPXSubscriptionVideoPageView.h"

#import <Wireframes/WFVideoView.h>

NS_ASSUME_NONNULL_BEGIN

@interface SPXSubscriptionVideoPageView () <WFVideoViewDelegate>

/// Label for the main title of the page.
@property (readonly, nonatomic) UILabel *titleLabel;

/// Label for the subtitle of the page.
@property (readonly, nonatomic) UILabel *subtitleLabel;

/// View containing the page's video.
@property (readonly, nonatomic) WFVideoView *videoView;

@end

@implementation SPXSubscriptionVideoPageView

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithFrame:(CGRect)frame {
  if (self = [super initWithFrame:frame]) {
    _videoDidFinishPlayback = [[self rac_signalForSelector:@selector(videoDidFinishPlayback:)]
                               mapReplace:[RACUnit defaultUnit]];
    [self setup];
  }
  return self;
}

- (void)setup {
  [self setupVideoView];
  [self setupTitle];
  [self setupSubtitle];
}

- (void)setupVideoView {
  _videoView = [[WFVideoView alloc] initWithFrame:CGRectZero];
  self.videoView.repeatsOnEnd = YES;
  self.videoView.delegate = self;
  self.videoView.layer.borderColor = nil;
  self.videoView.layer.cornerRadius = 7;
  self.videoView.layer.masksToBounds = YES;
  [self addSubview:self.videoView];

  [self.videoView mas_remakeConstraints:^(MASConstraintMaker *make) {
    make.width.top.centerX.equalTo(self);
    make.height.equalTo(self.videoView.mas_width).multipliedBy(0.75);
  }];
}

- (void)setupTitle {
  UIView *topPadding =
      [self addPaddingSubviewBeneathView:self.videoView heightRatio:0.04 maxHeight:20];

  _titleLabel = [[UILabel alloc] init];
  self.titleLabel.numberOfLines = 0;
  self.titleLabel.textAlignment = NSTextAlignmentCenter;
  self.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
  [self addSubview:self.titleLabel];

  [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(topPadding.mas_bottom);
    make.width.centerX.equalTo(self);
  }];
}

- (void)setupSubtitle {
  UIView *topPadding =
      [self addPaddingSubviewBeneathView:self.titleLabel heightRatio:0.01 maxHeight:10];

  _subtitleLabel = [[UILabel alloc] init];
  self.subtitleLabel.numberOfLines = 0;
  self.subtitleLabel.textAlignment = NSTextAlignmentCenter;
  self.subtitleLabel.lineBreakMode = NSLineBreakByWordWrapping;
  [self addSubview:self.subtitleLabel];

  [self.subtitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(topPadding.mas_bottom);
    make.width.centerX.equalTo(self);
  }];
}

- (UIView *)addPaddingSubviewBeneathView:(UIView *)view heightRatio:(CGFloat)heightRatio
                               maxHeight:(NSUInteger)maxHeight {
  auto paddingView = [[UIView alloc] init];
  paddingView.hidden = YES;
  [self addSubview:paddingView];

  [paddingView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.right.equalTo(self);
    make.top.equalTo(view.mas_bottom);
    make.height.equalTo(self).multipliedBy(heightRatio).priorityHigh();
    make.height.mas_lessThanOrEqualTo(maxHeight);
  }];

  return paddingView;
}

#pragma mark -
#pragma mark SPXFocusAwarePageView
#pragma mark -

- (void)pageViewWillLoseFocus {
  [self.videoView pause];
}

- (void)pageViewDidGainFocus {
  [self.videoView play];
}

#pragma mark -
#pragma mark Properties
#pragma mark -

- (void)setVideoURL:(nullable NSURL *)videoURL {
  [self.videoView loadVideoFromURL:videoURL];
}

- (nullable NSURL *)videoURL {
  return self.videoView.currentItem ? ((AVURLAsset *)(self.videoView.currentItem.asset)).URL : nil;
}

- (void)setTitle:(nullable NSAttributedString *)title {
  self.titleLabel.attributedText = title;
  [self setNeedsLayout];
}

- (nullable NSAttributedString *)title {
  return self.titleLabel.attributedText;
}

- (void)setSubtitle:(nullable NSAttributedString *)subtitle {
  self.subtitleLabel.attributedText = subtitle;
  [self setNeedsLayout];
}

- (nullable NSAttributedString *)subtitle {
  return self.subtitleLabel.attributedText;
}

- (void)setVideoBorderColor:(nullable UIColor *)videoBorderColor {
  self.videoView.layer.borderColor = videoBorderColor.CGColor;
  self.videoView.layer.borderWidth = videoBorderColor ? 1 : 0;
}

- (nullable UIColor *)videoBorderColor {
  return [UIColor colorWithCGColor:self.videoView.layer.borderColor];
}

#pragma mark -
#pragma mark WFVideoViewDelegate
#pragma mark -

- (void)videoDidFinishPlayback:(WFVideoView * __unused)videoView {
  // This method is handled using rac_signalForSelector.
}

@end

NS_ASSUME_NONNULL_END
