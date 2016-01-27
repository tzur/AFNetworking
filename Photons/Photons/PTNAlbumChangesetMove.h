// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

NS_ASSUME_NONNULL_BEGIN

/// Value class representing a move of object from one index to another.
@interface PTNAlbumChangesetMove : NSObject

/// Constructs a new \c PTNAlbumChangesetMove with the given from and to indices.
+ (instancetype)changesetMoveFrom:(NSUInteger)fromIndex to:(NSUInteger)toIndex;

/// Index of object in \c beforeAlbum.
@property (readonly, nonatomic) NSUInteger fromIndex;

/// Index to which the object moved to in \c afterAlbum.
@property (readonly, nonatomic) NSUInteger toIndex;

@end

NS_ASSUME_NONNULL_END
