// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRProductContentProvider.h"

NS_ASSUME_NONNULL_BEGIN

/// Provides multiple ways to fetch content for products. This class is initialized with a
/// dictionary that specifies the possible \c BZRProductContentProvider to fetch with.
/// A given \c BZRProduct should specify which \c BZRProductContentProvider is requested by
/// providing an key in the dictionary, and the parameters to that content provider. These are
/// given in \c BZRProductContentMultiProviderParameters class.
@interface BZRProductContentMultiProvider : NSObject <BZRProductContentProvider>

/// Initializes with the default collection of content providers. 
- (instancetype)init;

/// Initializes with \c contentProviders, a dictionary mapping content provider's names to actual
/// content providers.
- (instancetype)initWithContentProviders:
    (NSDictionary<NSString *, id<BZRProductContentProvider>> *)contentProviders
    NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
