// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Daniel Hadar.

#import "HUIResourceCell.h"

NS_ASSUME_NONNULL_BEGIN

@class HUIBoxView;

/// Cell for showing a visual resource inside the help view.
@interface HUIResourceCell ()

/// View for the help content box. Has "Box" as its accessibility identifier.
@property (readonly, nonatomic) HUIBoxView *boxView;

@end

NS_ASSUME_NONNULL_END
