// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Nir Bruner.

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Callback of requests for Camera authorization.
typedef void (^CAMAuthorizationStatusHandler)(BOOL authorized);

/// Encapsulation of the Camera authorization process, enabling to inject it to dependent objects,
/// by converting class methods in \c AVCaptureDevice to instance methods.
@interface CAMCameraAuthorizer : NSObject

/// Requests the user's permission, if needed, for accessing the Camera. \c handler is called upon
/// determining the app's Camera authorization.
///
/// Accessing the Camera always requires explicit permission from the user. The first time the app
/// uses \c AVFoundation methods to access the camera, iOS automatically and asynchronously prompts
/// the user to request authorization. Alternatively, you can call this method to prompt the user at
/// a time of choosing.
- (void)requestAuthorization:(CAMAuthorizationStatusHandler)handler;

/// Current authorization status.
@property (readonly, nonatomic) AVAuthorizationStatus authorizationStatus;

@end

NS_ASSUME_NONNULL_END
