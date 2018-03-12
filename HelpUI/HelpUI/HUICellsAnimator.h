// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Dekel Avrahami.

#import "HUIAnimatableCell.h"

NS_ASSUME_NONNULL_BEGIN

/// Object for controlling the animation of collection view cells that conform to
/// \c HUIAnimatableCell.
@interface HUICellsAnimator : NSObject

/// Initializes with no cells that are controlled by this animator.
- (instancetype)init;

/// Add \c cell to be controlled by this animator.
- (void)addCell:(UICollectionViewCell<HUIAnimatableCell> *)cell;

/// Remove \c cell from being controlled by this animator.
- (void)removeCell:(UICollectionViewCell<HUIAnimatableCell> *)cell;

/// Area for determining which cells should be animating. Setting the \c animationArea will cause
/// the animator to update cells animation so that cells that are intersecting the \c animationArea
/// will be animating and cells that aren't will not. The \c animationArea should be in the
/// coordinate system of the \c UICollectionView that its cells are controlled by this animator (the
/// coordinate system of frames of the cells that are controlled by this animator). Defaults to
/// \c CGRectZero.
@property (nonatomic) CGRect animationArea;

@end

NS_ASSUME_NONNULL_END
