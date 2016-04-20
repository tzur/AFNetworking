// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

NS_ASSUME_NONNULL_BEGIN

@protocol PTNAlbumDescriptor, PTNAssetDescriptor, PTNCollection;

/// Represents a collection of assets and subalbums. Classes implementing this protocol are advised
/// to be immutable value objects.
@protocol PTNAlbum <NSObject>

/// URL uniquely identifying the album.
@property (readonly, nonatomic) NSURL *url;

/// Asset implementing the \c PTNAssetDescriptor protocol contained in this album. If there are no
/// assets, an empty collection will be returned.
@property (readonly, nonatomic) id<PTNCollection> assets;

/// Sub albums contained in this album implementing the \c PTNAlbumDescriptor protocol. If there are
/// no subalbums, an empty collection will be returned.
@property (readonly, nonatomic) id<PTNCollection> subalbums;

@end

/// Implementation of \c PTNAlbum backed by an \c NSURL, an \c NSArray of \c PTNAlbumDescriptor
/// objects and an \c NSArray of \c PTNAssetDescriptor objects.
@interface PTNAlbum : NSObject <PTNAlbum>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c url, subalbums and assets.
- (instancetype)initWithURL:(NSURL *)url
                  subalbums:(NSArray<id<PTNAlbumDescriptor>> *)subalbums
                     assets:(NSArray<id<PTNAssetDescriptor>> *)assets NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
