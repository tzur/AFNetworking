// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

NS_ASSUME_NONNULL_BEGIN

/// View that represents a single page for the subscription screen with a rounded corners video,
/// title and subtitle.
@interface SPXSubscriptionVideoPageView : UIView

/// URL for the video presented on top of the page. The video will start right after \c URL is set
/// and the video is loaded. If \c nil no video is shown.
@property (strong, nonatomic, nullable) NSURL *videoURL;

/// Title presented below the video. If \c nil no title is shown.
@property (strong, nonatomic, nullable) NSAttributedString *title;

/// Secondery title presented below \c title. If \c nil no subtitle is shown.
@property (strong, nonatomic, nullable) NSAttributedString *subtitle;

@end

NS_ASSUME_NONNULL_END
