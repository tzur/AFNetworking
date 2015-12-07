// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

NS_ASSUME_NONNULL_BEGIN

/// Descriptor that acts as a reference to a heavy object. The heavy object is either costly to
/// fetch or to store in memory. Each descriptor has an identifier, which uniquely identifies the
/// heavy object across all Photons' objects, and allows re-fetching the descriptor when needed, as
/// the descriptor itself may contain transient data and is not serializable.
@protocol PTNDescriptor <NSObject>

/// Identifier of the Photons object.
@property (readonly, nonatomic) NSURL *ptn_identifier;

@end

NS_ASSUME_NONNULL_END
