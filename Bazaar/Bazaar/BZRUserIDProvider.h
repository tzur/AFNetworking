// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ben Yohay.

NS_ASSUME_NONNULL_BEGIN

/// Protocol for providing unique identifier of the user.
@protocol BZRUserIDProvider <NSObject>

/// Specifies a unique identifier of the user. The identifier should be the same across applications
/// and devices. \c nil signifies that the user ID is currently unavailable. KVO-compliant. Changes
/// may be delivered on an arbitrary thread.
@property (readonly, nonatomic, nullable) NSString *userID;

@end

NS_ASSUME_NONNULL_END
