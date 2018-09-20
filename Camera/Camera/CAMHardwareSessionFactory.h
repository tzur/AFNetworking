// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Gershon Hochman.

NS_ASSUME_NONNULL_BEGIN

@class CAMDevicePreset;

/// Factory for creating and configuring \c CAMHardwareSession instances.
@interface CAMHardwareSessionFactory : NSObject

/// Creates a session according to the given \c preset. This includes creating and attaching video
/// input and output, photo output, and according to the preset, may also include audio input and
/// output.
///
/// Returned signal sends the created \c CAMHardwareSession and completes, or sends an appropriate
/// error if an error occurred at any stage. All events are sent on an arbitrary thread.
- (RACSignal *)sessionWithPreset:(CAMDevicePreset *)preset;

@end

NS_ASSUME_NONNULL_END
