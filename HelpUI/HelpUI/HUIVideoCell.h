// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Daniel Hadar.

#import "HUIAnimatableCell.h"
#import "HUIResourceCell+Protected.h"

NS_ASSUME_NONNULL_BEGIN

@class HUIVideoItem;

/// Cell for showing a video. The video is streached to fill the cell's content view bounds. When
/// \c animatableCellStartAnimation of \c HUIAnimatableCell is called on an \c HUIVideoItem object,
/// the playback of the video starts in repeate mode. The video is displayed using \c WFVideoView,
/// which has "Video" accessibility identifier.
@interface HUIVideoCell : HUIResourceCell <HUIAnimatableCell>

/// Help item presented by this cell.
@property (strong, nonatomic, nullable) HUIVideoItem *item;

@end

NS_ASSUME_NONNULL_END
