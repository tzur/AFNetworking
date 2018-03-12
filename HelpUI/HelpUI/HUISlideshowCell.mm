// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Daniel Hadar.

#import "HUISlideshowCell.h"

#import <Wireframes/WFSlideshowView.h>

#import "HUIBoxView.h"
#import "HUIItem.h"

NS_ASSUME_NONNULL_BEGIN

@interface HUISlideshowCell () <WFSlideshowViewDelegate>

/// View for running the slideshow.
@property (readonly, nonatomic) WFSlideshowView *slideshowView;

/// Images displayed in the slideshow.
@property (strong, nonatomic, nullable) NSArray<UIImage *> *images;

@end

@implementation HUISlideshowCell

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
  _slideshowView = [[WFSlideshowView alloc] initWithFrame:CGRectZero];
  self.slideshowView.accessibilityIdentifier = @"Slideshow";
  self.slideshowView.transition = WFSlideshowTransitionCurtain;
  self.slideshowView.delegate = self;

  [self.boxView.contentView addSubview:self.slideshowView];
  [self.slideshowView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.edges.equalTo(self.boxView.contentView);
  }];
}

#pragma mark -
#pragma mark UIView
#pragma mark -

- (void)didMoveToSuperview {
  [super didMoveToSuperview];
  if (!self.superview) {
    [self.slideshowView pause];
  }
}

#pragma mark -
#pragma mark UICollectionReusableView
#pragma mark -

- (void)prepareForReuse {
  [super prepareForReuse];
  [self.slideshowView pauseAndRemoveOngoingAnimations];
  self.item = nil;
}

#pragma mark -
#pragma mark Item
#pragma mark -

- (void)setItem:(nullable HUISlideshowItem *)item {
  if (item == _item) {
    return;
  }

  _item = item;
  self.images = nil;
  self.boxView.title = item.title;
  self.boxView.body = item.body;
  self.boxView.iconURL = item.iconURL;
  auto transition = [HUISlideshowCell transitionToWFSlideshowTransition:item.transition];
  self.slideshowView.transition = transition;
  self.slideshowView.hidden = YES;
  self.slideshowView.stillDuration = item.stillDuration;
  self.slideshowView.transitionDuration = item.transitionDuration;
  [self.slideshowView reloadSlides];

  if (!item) {
    return;
  }

  auto images = [[NSMutableArray<UIImage *> alloc] initWithCapacity:item.images.count];
  for (NSString *image in item.images) {
    [images addObject:[UIImage imageNamed:image]];
    if (!image) {
      LogWarning(@"Could not load slideshow resources: '%@'", item.images);
      return;
    }
  }
  self.images = [images copy];
  self.slideshowView.hidden = NO;
  [self.slideshowView reloadSlides];
  [self.slideshowView play];
}

+ (WFSlideshowTransition)transitionToWFSlideshowTransition:(HUISlideshowTransition)transition {
  switch (transition) {
    case HUISlideshowTransitionCurtain:
      return WFSlideshowTransitionCurtain;
    case HUISlideshowTransitionFade:
      return WFSlideshowTransitionFade;
  }
}

#pragma mark -
#pragma mark HUIAnimatableCell
#pragma mark -

- (void)animatableCellStartAnimation {
  [self.slideshowView play];
}

- (void)animatableCellStopAnimation {
  [self.slideshowView pause];
}

#pragma mark -
#pragma mark WFSlideshowViewDelegate
#pragma mark -

- (NSUInteger)numberOfSlidesInSlideshowView:(WFSlideshowView __unused *)slideshowView {
  return self.images.count;
}

- (UIView *)slideshowView:(WFSlideshowView __unused *)slideshowView
        viewForSlideIndex:(NSUInteger)index {
  LTParameterAssert(index < self.images.count);
  return [[UIImageView alloc] initWithImage:self.images[index]];
}

@end

NS_ASSUME_NONNULL_END
