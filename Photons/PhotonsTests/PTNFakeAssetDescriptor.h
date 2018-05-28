// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import <LTKit/LTValueObject.h>

#import "PTNFakeDescriptor.h"

NS_ASSUME_NONNULL_BEGIN

/// Implementation of the \c PTNAssetDescriptor protocol as a plain value object used for testing.
@interface PTNFakeAssetDescriptor : LTValueObject <PTNAssetDescriptor>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c ptn_identifier, \c localizedTitle, \c descriptorCapabilities,
/// \c descriptorTraits, \c creationDate, \c modificationDate, \c filename, zero duration and \c
/// assetDescriptorCapabilities.
- (instancetype)initWithIdentifier:(NSURL *)ptn_identifier
                    localizedTitle:(nullable NSString *)localizedTitle
            descriptorCapabilities:(PTNDescriptorCapabilities)descriptorCapabilities
                  descriptorTraits:(NSSet<NSString *> *)descriptorTraits
                      creationDate:(nullable NSDate *)creationDate
                  modificationDate:(nullable NSDate *)modificationDate
                          filename:(nullable NSString *)filename
       assetDescriptorCapabilities:(PTNAssetDescriptorCapabilities)assetDescriptorCapabilities
                            artist:(nullable NSString *)artist;

/// Initializes with \c ptn_identifier, \c localizedTitle, \c descriptorCapabilities,
/// \c descriptorTraits, \c creationDate, \c modificationDate, \c filename, \c duration and \c
/// assetDescriptorCapabilities.
- (instancetype)initWithIdentifier:(NSURL *)ptn_identifier
                    localizedTitle:(nullable NSString *)localizedTitle
            descriptorCapabilities:(PTNDescriptorCapabilities)descriptorCapabilities
                  descriptorTraits:(NSSet<NSString *> *)descriptorTraits
                      creationDate:(nullable NSDate *)creationDate
                  modificationDate:(nullable NSDate *)modificationDate
                          filename:(nullable NSString *)filename
                          duration:(NSTimeInterval)duration
       assetDescriptorCapabilities:(PTNAssetDescriptorCapabilities)assetDescriptorCapabilities
                            artist:(nullable NSString *)artist
    NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
