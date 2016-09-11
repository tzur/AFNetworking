// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import <LTKit/LTValueObject.h>

#import "PTNFakeDescriptor.h"

NS_ASSUME_NONNULL_BEGIN

/// Implementation of the \c PTNAssetDescriptor protocol as a plain value object used for testing.
@interface PTNFakeAssetDescriptor : LTValueObject <PTNAssetDescriptor>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c ptn_identifier, \c localizedTitle, \c descriptorCapabilities,
/// \c descriptorTraits, \c creationDate, \c modificationDate and \c assetDescriptorCapabilities.
- (instancetype)initWithIdentifier:(NSURL *)ptn_identifier localizedTitle:(NSString *)localizedTitle
            descriptorCapabilities:(PTNDescriptorCapabilities)descriptorCapabilities
                  descriptorTraits:(NSSet<NSString *> *)descriptorTraits
                      creationDate:(nullable NSDate *)creationDate
                  modificationDate:(nullable NSDate *)modificationDate
       assetDescriptorCapabilities:(PTNAssetDescriptorCapabilities)assetDescriptorCapabilities
    NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
