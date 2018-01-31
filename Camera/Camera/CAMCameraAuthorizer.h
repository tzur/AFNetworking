// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Nir Bruner.

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Callback of requests for Camera authorization.
typedef void (^CAMAuthorizationStatusHandler)(BOOL authorized);

/// Encapsulation of the \c mediaType authorization process, enabling to inject it to dependent
/// objects, by converting class methods in \c AVCaptureDevice to instance methods.
@interface CAMCameraAuthorizer : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given \c mediaType.
- (instancetype)initWithMediaType:(AVMediaType)mediaType;

/// Requests the user's permission, if needed, for accessing the \c mediaType. \c handler is called
/// upon determining the app's \c mediaType authorization.
///
/// Accessing the \c mediaType always requires explicit permission from the user. The first time the
/// app uses \c AVFoundation methods to access the \c mediaType, iOS automatically and
/// asynchronously prompts the user to request authorization. Alternatively, you can call this
/// method to prompt the user at a time of choosing.
- (void)requestAuthorization:(CAMAuthorizationStatusHandler)handler;

/// Current authorization status.
@property (readonly, nonatomic) AVAuthorizationStatus authorizationStatus;

@end

NS_ASSUME_NONNULL_END
