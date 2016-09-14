// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import <LTKit/LTValueObject.h>

#import "PTNDescriptor.h"

NS_ASSUME_NONNULL_BEGIN

/// Implementation of the \c PTNDescriptor protocol as a plain value object used for testing.
@interface PTNFakeDescriptor : LTValueObject <PTNDescriptor>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c ptn_identifier, \c localizedTitle, \c descriptorCapabilities and
/// \c descriptorTraits.
- (instancetype)initWithIdentifier:(NSURL *)ptn_identifier localizedTitle:(NSString *)localizedTitle
            descriptorCapabilities:(PTNDescriptorCapabilities)descriptorCapabilities
                  descriptorTraits:(NSSet<NSString *> *)descriptorTraits
    NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
