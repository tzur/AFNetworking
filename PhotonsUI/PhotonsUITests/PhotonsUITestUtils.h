// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

@class PTUChangesetMove;

NS_ASSUME_NONNULL_BEGIN

/// Constructs a \c PTUCollectionViewChangesetMove from <tt>(from, section)</tt> to
/// <tt>(to, section)</tt>.
PTUChangesetMove *PTUCreateChangesetMove(NSUInteger from, NSUInteger to, NSUInteger section);

NS_ASSUME_NONNULL_END
