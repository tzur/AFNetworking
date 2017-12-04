// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "SPXPagingView.h"

NS_ASSUME_NONNULL_BEGIN

/// View that represents a single page for the subscription screen with a rounded corners video,
/// title and subtitle.
/// @see SPXPagingView, SPXFocusAwarePageView.
@interface SPXSubscriptionVideoPageView : UIView <SPXFocusAwarePageView>

/// URL for the video presented on top of the page. The video will start playing when the page
/// gains focus and paused when the page loses focus . If the URL is replaced while the video is
/// playing the new video will immediately start playing. If set to \c nil no video is shown.
@property (strong, nonatomic, nullable) NSURL *videoURL;

/// Title presented below the video. If \c nil no title is shown.
@property (strong, nonatomic, nullable) NSAttributedString *title;

/// Secondary title presented below \c title. If \c nil no subtitle is shown.
@property (strong, nonatomic, nullable) NSAttributedString *subtitle;

@end

NS_ASSUME_NONNULL_END
