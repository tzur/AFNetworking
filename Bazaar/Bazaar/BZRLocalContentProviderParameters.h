// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRContentProviderParameters.h"

NS_ASSUME_NONNULL_BEGIN

/// Additional parameters required for fetching content with \c BZRLocalContentProvider.
@interface BZRLocalContentProviderParameters : BZRContentProviderParameters

/// Local path to the content file.
@property (readonly, nonatomic) NSURL *URL;

@end

NS_ASSUME_NONNULL_END
