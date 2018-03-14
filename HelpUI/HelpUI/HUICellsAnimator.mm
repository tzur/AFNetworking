// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Dekel Avrahami.

#import "HUICellsAnimator.h"

NS_ASSUME_NONNULL_BEGIN

@interface HUICellsAnimator ()

/// Type for collection view cell that shows an animatable resource.
typedef UICollectionViewCell<HUIAnimatableCell> HUICollectionViewAnimatableCell;

/// Type for mutable array that holds collection view cells that shows an animatable resource.
typedef NSMutableArray<HUICollectionViewAnimatableCell *> HUIMutableAnimatableCellsArray;

/// Array that holds all displayed animatable cells.
@property (readonly, nonatomic) HUIMutableAnimatableCellsArray *displayedAnimatableCells;

/// Array that holds all displayed and currently animating cells.
@property (readonly, nonatomic) HUIMutableAnimatableCellsArray *displayedAnimatingCells;

@end

@implementation HUICellsAnimator

- (instancetype)init {
  if (self = [super init]) {
    _displayedAnimatableCells = [NSMutableArray array];
    _displayedAnimatingCells = [NSMutableArray array];
    self.animationArea = CGRectZero;
  }
  return self;
}

- (void)addCell:(HUICollectionViewAnimatableCell *)cell {
  [self.displayedAnimatableCells addObject:cell];
  [self updateAnimation];
}

- (void)updateAnimation {
  for (HUICollectionViewAnimatableCell *cell in self.displayedAnimatableCells) {
    BOOL isCellInsideAnimationArea = CGRectIntersectsRect(cell.frame, self.animationArea);
    if (isCellInsideAnimationArea && ![self.displayedAnimatingCells containsObject:cell]) {
      [cell startAnimation];
      [self.displayedAnimatingCells addObject:cell];
    } else if (!isCellInsideAnimationArea && [self.displayedAnimatingCells containsObject:cell]) {
      [cell stopAnimation];
      [self.displayedAnimatingCells removeObject:cell];
    }
  }
}

- (void)removeCell:(HUICollectionViewAnimatableCell *)cell {
  [self updateAnimation];
  [self.displayedAnimatableCells removeObject:cell];

  if ([self.displayedAnimatingCells containsObject:cell]) {
    [cell stopAnimation];
    [self.displayedAnimatingCells removeObject:cell];
  }
}

- (void)setAnimationArea:(CGRect)animationArea {
  if (_animationArea != animationArea) {
    _animationArea = animationArea;
    [self updateAnimation];
  }
}

@end

NS_ASSUME_NONNULL_END
