// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Michael Kimyagarov.

#import "PTNDescriptor.h"

NS_ASSUME_NONNULL_BEGIN

@class MPMediaItemCollection;

/// Value class implementing \c PTNAlbumDescriptor, which holds \c MPMediaItemCollection and a URL,
/// which represents the \c MPMediaItemCollection.
@interface PTNMediaLibraryCollectionDescriptor : NSObject <PTNAlbumDescriptor>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given \c collection and the given \c url;
- (instancetype)initWithCollection:(MPMediaItemCollection *)collection url:(NSURL *)url
    NS_DESIGNATED_INITIALIZER;

/// Returns \c MPMediaItemCollection represented by this instance.
@property (readonly, nonatomic) MPMediaItemCollection *collection;

/// Returns \c NSURL represented by this instance.
@property (readonly, nonatomic) NSURL *url;

@end

NS_ASSUME_NONNULL_END
