// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Daniel Hadar.

#import "HUIAnimatableCell.h"
#import "HUIResourceCell+Protected.h"

NS_ASSUME_NONNULL_BEGIN

@class HUISlideshowItem;

/// Cell for showing a slideshow.
/// The slideshow is displayed using \c WFSlideshowView, which has "Slideshow" accessibility
/// identifier. The transition of the \c WFSlideshowView is set to \c WFSlideshowTransitionCurtain.
@interface HUISlideshowCell : HUIResourceCell <HUIAnimatableCell>

/// Help item presented by this cell.
@property (strong, nonatomic, nullable) HUISlideshowItem *item;

@end

NS_ASSUME_NONNULL_END
