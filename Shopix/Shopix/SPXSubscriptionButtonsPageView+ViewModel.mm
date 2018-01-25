// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "SPXSubscriptionButtonsPageView+ViewModel.h"

#import <LTKit/NSArray+Functional.h>
#import <Wireframes/WFVideoView.h>

#import "SPXSubscriptionButtonsFactory.h"
#import "SPXSubscriptionButtonsPageView.h"
#import "SPXSubscriptionButtonsPageViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@implementation SPXSubscriptionButtonsPageView (ViewModel)

+ (instancetype)buttonsPageViewWithViewModel:(id<SPXSubscriptionButtonsPageViewModel>)pageViewModel
                              buttonsFactory:(id<SPXSubscriptionButtonsFactory>)buttonsFactory {
  auto pageView = [[SPXSubscriptionButtonsPageView alloc] init];

  pageView.backgroundVideoView.videoURL = pageViewModel.backgroundVideoURL;
  pageView.buttonsContainer.title = pageViewModel.title;
  pageView.buttonsContainer.subtitle = pageViewModel.subtitle;
  [pageView createButtonsWithViewModel:pageViewModel buttonsFactory:buttonsFactory];
  [pageView bindVideoPlaybackControl:pageViewModel];

  return pageView;
}

- (void)createButtonsWithViewModel:(id<SPXSubscriptionButtonsPageViewModel>)pageViewModel
                    buttonsFactory:(id<SPXSubscriptionButtonsFactory>)buttonsFactory {
  self.buttonsContainer.buttons = [pageViewModel.subscriptionDescriptors
                                   lt_map:^UIControl *(SPXSubscriptionDescriptor *descriptor) {
    auto buttonIndex = [pageViewModel.subscriptionDescriptors indexOfObject:descriptor];
    auto isHighlighted = pageViewModel.preferredSubscriptionIndex &&
        buttonIndex == pageViewModel.preferredSubscriptionIndex.unsignedIntegerValue;
    return [buttonsFactory
            createSubscriptionButtonWithDescriptor:descriptor
            atIndex:buttonIndex outOf:pageViewModel.subscriptionDescriptors.count
            isHighlighted:isHighlighted];
  }];
}

- (void)bindVideoPlaybackControl:(id<SPXSubscriptionButtonsPageViewModel>)pageViewModel {
  @weakify(self);
  [[RACObserve(pageViewModel, shouldPlayVideo)
    distinctUntilChanged]
    subscribeNext:^(NSNumber *shouldPlayVideo) {
      @strongify(self);
      shouldPlayVideo.boolValue ? [self startVideoPlaybackWithAnimation] :
          [self stopVideoPlaybackWithAnimation];
    }];
}

- (void)startVideoPlaybackWithAnimation {
  [self.backgroundVideoView play];
  [UIView animateWithDuration:0.5f delay:0 options:UIViewAnimationOptionAllowUserInteraction
                   animations:^{
    [self.backgroundVideoView setAlpha:1.0f];
  } completion:nil];
}

- (void)stopVideoPlaybackWithAnimation {
  [UIView animateWithDuration:0.5f delay:0 options:UIViewAnimationOptionAllowUserInteraction
                   animations:^{
    [self.backgroundVideoView setAlpha:0.25f];
  } completion:^(BOOL finished) {
    if (finished) {
      [self.backgroundVideoView stop];
    }
  }];
}

@end

NS_ASSUME_NONNULL_END
