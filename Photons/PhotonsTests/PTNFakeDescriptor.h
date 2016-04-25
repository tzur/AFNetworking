// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNDescriptor.h"

NS_ASSUME_NONNULL_BEGIN

/// Implementation of the \c PTNDescriptor protocol as a plain value object used for testing.
/// Protocol mocks have no support in internal methods used by iOS such as \c _isString or
/// \c _isNumber, causing test failures to raise exceptions instead of printing the objects involved
/// in the failure.
@interface PTNFakeDescriptor : NSObject <PTNDescriptor>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c ptn_identifier, \c localizedTitle and \c descriptorCapabilities.
- (instancetype)initWithIdentifier:(NSURL *)ptn_identifier localizedTitle:(NSString *)localizedTitle
            descriptorCapabilities:(PTNDescriptorCapabilities)descriptorCapabilities
    NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
