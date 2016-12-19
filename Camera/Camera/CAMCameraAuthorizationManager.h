// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Nir Bruner.

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@class CAMCameraAuthorizer;

/// Handles Camera authorization status and flow.
@interface CAMCameraAuthorizationManager : NSObject

/// Initializes with a default \c authorizer.
- (instancetype)init;

/// Initializes with the given \c authorizer.
- (instancetype)initWithCameraAuthorizer:(CAMCameraAuthorizer *)authorizer
    NS_DESIGNATED_INITIALIZER;

/// Requests Camera authorization. Calling this method may present a user interface. The returned
/// signal will send a single \c AVAuthorizationStatus corresponding to the new authorization status
/// and complete. All values are sent on an arbitrary thread.
- (RACSignal *)requestAuthorization;

/// Current Camera authorization status. This property is KVO compliant, but will only update
/// according to authorization requests made by the receiver.
@property (readonly, nonatomic) AVAuthorizationStatus authorizationStatus;

@end

NS_ASSUME_NONNULL_END
