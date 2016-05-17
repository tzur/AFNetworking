// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Alex Gershovich.

NS_ASSUME_NONNULL_BEGIN

@protocol WFImageProvider;

/// View model for image presentation. All properties are KVO compliant, and modified on the main
/// thread only.
@protocol WFImageViewModel <NSObject>

/// Image to display. If \c nil, no image is displayed.
@property (readonly, nonatomic, nullable) UIImage *image;

/// Image to display when in highlighted state. If \c nil, \c image is used instead.
@property (readonly, nonatomic, nullable) UIImage *highlightedImage;

@end

NS_ASSUME_NONNULL_END
