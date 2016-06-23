// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

NS_ASSUME_NONNULL_BEGIN

@class PTUChangesetMove;

/// Constructs a \c PTUCollectionViewChangesetMove from <tt>(from, section)</tt> to
/// <tt>(to, section)</tt>.
PTUChangesetMove *PTUCreateChangesetMove(NSUInteger from, NSUInteger to, NSUInteger section);

NS_ASSUME_NONNULL_END
