// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

NS_ASSUME_NONNULL_BEGIN

/// Implemented by Photons objects such as albums and assets.
@protocol PTNObject <NSObject>

/// Identifier of the Photons object.
@property (readonly, nonatomic) NSURL *ptn_identifier;

@end

NS_ASSUME_NONNULL_END
