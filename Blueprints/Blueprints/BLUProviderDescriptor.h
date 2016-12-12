// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

NS_ASSUME_NONNULL_BEGIN

@protocol BLUProvider;

/// Implemented by objects that are values of \c BLUNode to indicate they need to be provided with
/// an external data. The protocol allows for creation of a new provider that will provide the data,
/// with configuration that is contained in the object implementing this protocol.
@protocol BLUProviderDescriptor <NSObject, NSCopying>

/// Initializes a new provider associated with this descriptor with the descriptor data.
- (id<BLUProvider>)provider;

@end

NS_ASSUME_NONNULL_END
