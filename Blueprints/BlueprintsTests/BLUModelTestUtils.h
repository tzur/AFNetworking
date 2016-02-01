// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "BLUProvider.h"
#import "BLUProviderDescriptor.h"

@class BLUFakeProvider, BLUNodeData;

NS_ASSUME_NONNULL_BEGIN

/// Fake provider descriptor.
@interface BLUFakeProviderDescriptor : NSObject <BLUProviderDescriptor>

/// Provider that this descriptor returns.
@property (readonly, nonatomic) BLUFakeProvider *fakeProvider;

@end

/// Fake provider allowing manual sending of \c nodeData.
@interface BLUFakeProvider : NSObject <BLUProvider>

/// Send the give \c nodeData over the \c nodeData signal.
- (void)sendNodeData:(BLUNodeData *)nodeData;

@end

NS_ASSUME_NONNULL_END
