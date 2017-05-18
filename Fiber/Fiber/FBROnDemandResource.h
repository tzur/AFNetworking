// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

NS_ASSUME_NONNULL_BEGIN

/// Protocol for providing access to On Demand Resources, as long as the resource instance is not
/// deallocated, the requested resources are marked as in-use and are promised not to be purged.
@protocol FBROnDemandResource <NSObject>

/// Bundle that provides access to the requested resources.
@property (readonly, nonatomic) NSBundle *bundle;

@end

NS_ASSUME_NONNULL_END
