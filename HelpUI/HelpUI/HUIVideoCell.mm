// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Daniel Hadar.

#import "HUIVideoCell.h"

#import <Wireframes/WFVideoView.h>

#import "HUIBoxView.h"
#import "HUIItem.h"

NS_ASSUME_NONNULL_BEGIN

@interface HUIVideoCell ()

/// View that plays the video.
@property (readonly, nonatomic) WFVideoView *videoView;

@end

@implementation HUIVideoCell

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
  _videoView = [[WFVideoView alloc] init];
  self.videoView.repeatsOnEnd = YES;
  self.videoView.videoGravity = AVLayerVideoGravityResize;
  self.videoView.accessibilityIdentifier = @"Video";

  [self.boxView.contentView addSubview:self.videoView];
  [self.videoView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.edges.equalTo(self.boxView.contentView);
  }];
}

#pragma mark -
#pragma mark UICollectionReusableView
#pragma mark -

- (void)prepareForReuse {
  [super prepareForReuse];
  self.item = nil;
}

#pragma mark -
#pragma mark Item
#pragma mark -

- (void)setItem:(nullable HUIVideoItem *)item {
  if (item == _item) {
    return;
  }

  _item = item;
  self.boxView.title = item.title;
  self.boxView.body = item.body;
  self.boxView.iconURL = item.iconURL;
  self.videoView.hidden = YES;

  if (!item) {
    [self.videoView loadVideoFromURL:nil];
    return;
  }

  if (!item.video) {
    LogWarning(@"Could not load video resource '%@'", item.video);
    return;
  }

  auto localURL = [NSURL fileURLWithPath:[[[NSBundle mainBundle] bundlePath]
                                          stringByAppendingPathComponent:item.video]];
  if (!localURL) {
    return;
  }

  self.videoView.hidden = NO;
  [self.videoView loadVideoFromURL:localURL];
  [self.videoView play];
}

#pragma mark -
#pragma mark HUIAnimatableCell
#pragma mark -

- (void)startAnimation {
  [self.videoView play];
}

- (void)stopAnimation {
  [self.videoView pause];
}

@end

NS_ASSUME_NONNULL_END
