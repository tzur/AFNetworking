// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKImageMotionLayer.h"

NS_ASSUME_NONNULL_BEGIN

/// Class for calculating displacements of a sky layer.
@interface PNKImageMotionSkyLayer : NSObject <PNKImageMotionLayer>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the size of the motion map, wind direction and wind speed. The wind velocity
/// vector is assumed to reside in the XZ plane. In other words, it has a left-right and a depth
/// component but not an up-down component.
///
/// @param imageSize Size of the displacement map that will be created.
///
/// @param angle Angle (in degrees) between wind velocity and the X axis. \c 0 denotes rightward
/// displacement. \c 90 denotes forward displacement (from the viewer to the horizon). \c 180
/// denotes leftward displacement. \c 270 denotes backward displacement (from the horizon to the
/// viewer).
///
/// @param speed Absolute value of the wind velocity.
- (instancetype)initWithImageSize:(cv::Size)imageSize angle:(CGFloat)angle speed:(CGFloat)speed
    NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
