// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

NS_ASSUME_NONNULL_BEGIN

/// Represents a single move in a \c PTUChangeset.
@interface PTUChangesetMove : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Constructs a new \c PTUChangesetMove with the given \c from and \c to index paths.
+ (instancetype)changesetMoveFrom:(NSIndexPath *)fromIndex to:(NSIndexPath *)toIndex;

/// Index of object before move.
@property (readonly, nonatomic) NSIndexPath *fromIndex;

/// Index of object after move.
@property (readonly, nonatomic) NSIndexPath *toIndex;

@end

NS_ASSUME_NONNULL_END
