// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Alex Gershovich.

#import "WFImageViewModel.h"

NS_ASSUME_NONNULL_BEGIN

/// Fake view model that does nothing, but exposes all its properties.
@interface WFFakeImageViewModel : NSObject <WFImageViewModel>
@property (readwrite, nonatomic, nullable) UIImage *image;
@property (readwrite, nonatomic, nullable) UIImage *highlightedImage;
@property (readwrite, nonatomic) BOOL isAnimated;
@property (readwrite, nonatomic) NSTimeInterval animationDuration;
@end

NS_ASSUME_NONNULL_END
