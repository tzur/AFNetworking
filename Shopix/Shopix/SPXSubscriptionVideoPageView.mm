// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "SPXSubscriptionVideoPageView.h"

#import <Wireframes/WFVideoView.h>

NS_ASSUME_NONNULL_BEGIN

@interface SPXSubscriptionVideoPageView ()

/// View that contains the video, until the video is set this view defines the bounds of the video.
@property (readonly, nonatomic) UIView *mediaContainerView;

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
    [self setup];
  }
  return self;
}

- (void)setup {
  [self setupMediaContainerView];
  [self setupVideoView];
  [self setupTitle];
  [self setupSubtitle];
}

- (void)setupMediaContainerView {
  _mediaContainerView = [[UIView alloc] init];
  [self addSubview:self.mediaContainerView];

  [self.mediaContainerView mas_remakeConstraints:^(MASConstraintMaker *make) {
    make.width.top.centerX.equalTo(self);
    make.height.equalTo(self.mediaContainerView.mas_width).multipliedBy(0.75);
  }];
}

- (void)setupVideoView {
  _videoView = [[WFVideoView alloc] initWithVideoProgressIntervalTime:1 playInLoop:YES];
  self.videoView.layer.cornerRadius = 7;
  self.videoView.layer.masksToBounds = YES;
  [self.mediaContainerView addSubview:self.videoView];

  [self.videoView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.edges.equalTo(self.mediaContainerView);
  }];
}

- (void)setupTitle {
  UIView *topPadding =
      [self addPaddingSubviewBeneathView:self.mediaContainerView heightRatio:0.04 maxHeight:20];

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
  BOOL isPlaying = self.videoView.isPlaying;
  self.videoView.videoURL = videoURL;
  if (isPlaying) {
    [self.videoView play];
  }
}

- (nullable NSURL *)videoURL {
  return self.videoView.videoURL;
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

@end

NS_ASSUME_NONNULL_END
