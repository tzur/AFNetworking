// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Reuven Siman Tov.

NS_ASSUME_NONNULL_BEGIN

/// Category for getting the device's camera make & model, as it appears in EXIF of photos taken by
/// Apple's Camera app.
@interface UIDevice (CameraMake)

/// Camera Make (the manufacturer of the recording equipment), as it appears in photos taken by
/// Apple's Camera app.
@property (readonly, nonatomic) NSString *cam_cameraMake;

/// Camera Model (the model name or model number of the equipment), as it appears in photos taken by
/// Apple's Camera app. Might be \c nil if unknown.
@property (readonly, nonatomic) NSString *cam_cameraModel;

@end

NS_ASSUME_NONNULL_END
