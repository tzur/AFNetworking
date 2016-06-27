// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTUChangesetProvider.h"

@protocol PTNAssetManager;

NS_ASSUME_NONNULL_BEGIN

/// Implementation of \c PTUChangesetProvider protocol, mapping album changesets to \c PTUChangeset.
/// The mapped changeset has two sections - the first for subalbums and the second for assets.
/// Metadata title is defined as the \c localizedTitle of the corresponding descriptor, and section
/// titles are set to "Albums" and "Photos" respectively.
@interface PTUAlbumChangesetProvider : NSObject <PTUChangesetProvider>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes this album changeset provider with \c manager as the asset manager to use when
/// fetching the album and descriptor identified by \c url.
- (instancetype)initWithManager:(id<PTNAssetManager>)manager
                       albumURL:(NSURL *)url NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
