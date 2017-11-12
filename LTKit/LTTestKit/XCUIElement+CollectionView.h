// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Dekel Avrahami.

NS_ASSUME_NONNULL_BEGIN

/// Possible scrolling directions of the collection view.
typedef NS_ENUM(NSUInteger, LTScrollDirection) {
  LTUp,
  LTDown,
  LTLeft,
  LTRight
};

/// Map between a direction to its oposite direction.
NSDictionary * const kOpositeDirection = @{
  @(LTUp): @(LTDown),
  @(LTDown): @(LTUp),
  @(LTLeft): @(LTRight),
  @(LTRight): @(LTLeft)
};

/// For expressing index of cell that is not visible in the collection view.
extern const NSInteger kLTCellNotVisibleInCollection;

/// Category for handling collectionView operations in UI tests. Each cell in this collection view
/// should have a unique accessibility identifier otherwise scrolls and iterations that are
/// implemented in this category might be partial.
@interface XCUIElement (CollectionView)

/// Possible results of handling an iteration step.
typedef NS_ENUM(NSUInteger, LTIterationStepResult) {
  LTKeepIterating,
  LTStopIterating
};

/// Block to be invoked for each cell while iterating the collection view. The
/// \c LTIterationStepResult return value of the block is used to decide if the iteration should
/// stop or continue.
typedef LTIterationStepResult (^LTCellIterationBlock)(XCUIElement *cell);

/// Iterates over the visible cells in the given \c direction, and invokes the given \c block for
/// the current cell at each iteration step, then scrolls in the given \c direction and continues
/// the iteration with the visible cells after scrolling, and so on until the end of the collection
/// or until LTStopIterating is returned from \c block.
- (void)lt_collectionViewIterateFromCurrentPositionInDirection:(LTScrollDirection)direction
                                                     withBlock:(LTCellIterationBlock)block;

/// Scrolls until content edge in the oposite of the given \c direction, and then iterate as
/// described in \c lt_collectionViewIterateFromCurrentPositionInDirection.
- (void)lt_collectionViewIterateFromContentEdgeInDirection:(LTScrollDirection)direction
                                                 withBlock:(LTCellIterationBlock)block;

/// Scrolls this collectionView in the given \c direction until content edge.
- (void)lt_collectionViewScrollToContentEdgeInDirection:(LTScrollDirection)direction;

/// Iterates over all the cells in this collectionView in the given \c direction and presses on
/// each cell.
- (void)lt_collectionViewPressAllCellsInDirection:(LTScrollDirection)direction;

/// Scrolls in the oposite of the given \c direction to content edge, and then scrolls in the given
/// direction until the given \c cellIdentifier is visible (or until reaching the end of the
/// content). If \c shouldPress is \c YES, presses on this cell after scrolling to it. Returns
/// \c YES if the cell with the given \c cellIdentifier is visible when this method returns, \c NO
/// otherwise.
- (BOOL)lt_collectionViewScrollTo:(NSString *)cellIdentifier
                      inDirection:(LTScrollDirection)direction press:(BOOL)shouldPress;

/// Presses on the UICollectionView in the coordinate of the center of the given \c cell.
/// @note The press is done on the \c UICollectionView and not on the \c cell.
- (void)lt_collectionViewPressCellCoordinate:(XCUIElement *)cell;

@end

NS_ASSUME_NONNULL_END
