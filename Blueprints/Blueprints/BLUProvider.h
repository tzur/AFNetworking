// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

NS_ASSUME_NONNULL_BEGIN

@protocol BLUProviderDescriptor;

@class RACSignal;

/// Provider of stream of values and childNodes of a \c BLUNode.
@protocol BLUProvider <NSObject>

/// Returns a cold signal containing the data of the provided node including its value and child
/// nodes, changing over time. This signal may be infinite or may complete, indicating that no
/// further changes will be sent. Depending on the provider, this signal may also err to indicate
/// there was an error fetching the next data object.
- (RACSignal *)provideNodeData;

@end

NS_ASSUME_NONNULL_END
