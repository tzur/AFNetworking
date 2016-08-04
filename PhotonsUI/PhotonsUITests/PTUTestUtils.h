// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

NS_ASSUME_NONNULL_BEGIN

@class PTUChangeset, PTUChangesetMove;

/// Constructs a \c PTUCollectionViewChangesetMove from <tt>(from, section)</tt> to
/// <tt>(to, section)</tt>.
PTUChangesetMove *PTUCreateChangesetMove(NSUInteger from, NSUInteger to, NSUInteger section);

/// \c YES if \c lhs and \c rhs are equal, have equal contents, or have contents that contain the
/// same objects when iterated.
BOOL PTUChangesetSemanticallyEqual(PTUChangeset *lhs, PTUChangeset *rhs);

NS_ASSUME_NONNULL_END
