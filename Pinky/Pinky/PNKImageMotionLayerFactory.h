// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKImageMotionLayerType.h"

NS_ASSUME_NONNULL_BEGIN

@protocol PNKImageMotionLayer;

/// Factory creating layer objects from their corresponding layer type.
@interface PNKImageMotionLayerFactory : NSObject

/// Creates a layer object of the corresponding \c type. Returns \c nil when
/// <tt>type == pnk::ImageMotionLayerTypeNone</tt> or <tt>type >= pnk::ImageMotionLayerTypeMax</tt>.
+ (nullable id<PNKImageMotionLayer>)layerWithType:(pnk::ImageMotionLayerType)type
                                        imageSize:(cv::Size)imageSize;

@end

NS_ASSUME_NONNULL_END
