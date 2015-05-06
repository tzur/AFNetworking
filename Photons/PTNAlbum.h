// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

NS_ASSUME_NONNULL_BEGIN

@protocol PTNCollection;

/// Represents a collection of assets and subalbums. Classes implementing this protocol are advised
/// to be immutable value objects.
@protocol PTNAlbum <NSObject>

/// Asset implementing the \c PTNObject protocol contained in this album. If there are no assets, an
/// empty collection will be returned.
@property (readonly, nonatomic) id<PTNCollection> assets;

/// Sub albums contained in this album implementing the \c PTNObject protocol. If there are no
/// subalbums, no items will be returned.
@property (readonly, nonatomic) id<PTNCollection> subalbums;

@end

NS_ASSUME_NONNULL_END
