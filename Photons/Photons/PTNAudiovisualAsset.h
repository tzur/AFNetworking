// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Reuven Siman Tov.

#import "PTNImageAsset.h"

NS_ASSUME_NONNULL_BEGIN

@class AVAsset;

/// Protocol for a video or audio asset, enabling fetching of the asset's \c AVAsset.
@protocol PTNAudiovisualAsset <NSObject>

/// Fetches the \c AVAsset backed by this asset. The returned signal sends a single \c AVAsset
/// object on an arbitrary thread, and completes. If the \c AVAsset cannot be fetched the signal
/// errs instead.
- (RACSignal<AVAsset *> *)fetchAVAsset;

@end

/// Audio or video asset backed by an \c AVAsset.
@interface PTNAudiovisualAsset : NSObject <PTNAudiovisualAsset>

- (instancetype)init NS_UNAVAILABLE;

/// Initialize with the underlying \c asset of the receiver.
- (instancetype)initWithAVAsset:(AVAsset *)asset NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
