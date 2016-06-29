// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNDescriptor.h"

NS_ASSUME_NONNULL_BEGIN

/// Implementation of the \c PTNAlbumDescriptor protocol as a plain value object used for testing.
@interface PTNFakeAlbumDescriptor : NSObject <PTNAlbumDescriptor>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c ptn_identifier, \c localizedTitle, \c descriptorCapabilities
/// \c assetCount and \c albumDescriptorCapabilities.
- (instancetype)initWithIdentifier:(NSURL *)ptn_identifier localizedTitle:(NSString *)localizedTitle
            descriptorCapabilities:(PTNDescriptorCapabilities)descriptorCapabilities
                        assetCount:(NSUInteger)assetCount
       albumDescriptorCapabilities:(PTNAlbumDescriptorCapabilities)albumDescriptorCapabilities
    NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
