// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Dekel Avrahami.

#import "XCUIElement+CollectionView.h"

NS_ASSUME_NONNULL_BEGIN

NSDictionary * const kLTOppositeDirection = @{
  @(LTScrollDirectionUp): @(LTScrollDirectionDown),
  @(LTScrollDirectionDown): @(LTScrollDirectionUp),
  @(LTScrollDirectionLeft): @(LTScrollDirectionRight),
  @(LTScrollDirectionRight): @(LTScrollDirectionLeft)
};

/// Extension for private methods of the collection view category.
@interface XCUIElement (CollectionViewPrivate)

/// Returns the index of the visible cell with the given \c cellIdentifier. If no such cell returns
/// \c kCellNotVisibleInCollection.
- (NSInteger)lt_collectionViewIndexOfVisibleCell:(NSString *)cellIdentifier;

/// Returns \c YES if this UI Element's type is collection view.
- (BOOL)lt_isCollectionView;

/// Return a message containing the element type of this UI Element, and saying that this object
/// type is not a collection view.
- (NSString *)lt_collectionViewTypeAssertionMessage;

@end

@implementation XCUIElement (CollectionViewPrivate)

- (NSInteger)lt_collectionViewIndexOfVisibleCell:(NSString *)cellIdentifier {
  LTAssert([self lt_isCollectionView], @"%@", [self lt_collectionViewTypeAssertionMessage]);
  NSInteger result = NSNotFound;
  for (NSUInteger i = 0; i < self.cells.count; ++i) {
    XCUIElement *currentCell = [self.cells elementBoundByIndex:i];
    if ([currentCell.identifier isEqualToString:cellIdentifier]) {
      result = i;
      break;
    }
  }
  return result;
}

- (BOOL)lt_isCollectionView {
  return self.elementType == XCUIElementTypeCollectionView;
}

- (NSString *)lt_collectionViewTypeAssertionMessage {
  return [NSString stringWithFormat:@"The XCUIElement should have XCUIElementTypeCollectionView "
          "type, but it is %ld", (long)self.elementType];
}

@end

/// Returns \c YES if the given \c direction is reversed to the direction of indexes increasment in
/// a collection view (collection view cells indexes are increasing in the directions down and
/// right).
static BOOL LTIsDirectionReversedToCollectionView(LTScrollDirection direction) {
  return direction == LTScrollDirectionUp || direction == LTScrollDirectionLeft;
}

/// Object for iterating the visible cells of a collection view.
@interface LTVisibleCellsIterator : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given \c collectionView. The iteration will start with the cell after the
/// one that has the given \c cellIdentifier. If given \c cellIdentifier is nil, or no visible cell
/// with given \c cellIdentifier the iteration will include all visible cells. The iteration order
/// is the order of indexes or the reversed order according to the given direction
/// (see \c lt_isDirectionReversed).
- (instancetype)initWithCollectionView:(XCUIElement *)collectionView
                 currentCellIdentifier:(nullable NSString *)cellIdentifier
                             direction:(LTScrollDirection)direction NS_DESIGNATED_INITIALIZER;

/// Returns \c NO if calling \c next method will return nil.
- (BOOL)hasNext;

/// Returns the next visible cell. If this is the last visible cell according to iteration
/// direction, returns \c nil.
- (nullable XCUIElement *)next;

/// The collection view to iterate.
@property (weak, readonly, nonatomic) XCUIElement *collectionView;

/// YES if order of cells to iterate should be the opposite of the cells index order.
@property (readonly, nonatomic) BOOL reversed;

/// The index of the cell that \c next method will return. When iteration finishes this index will
/// be out of the range of visible cells indexes.
@property (nonatomic) NSInteger nextIndex;

@end

@implementation LTVisibleCellsIterator

- (instancetype)initWithCollectionView:(XCUIElement *)collectionView
                 currentCellIdentifier:(nullable NSString *)cellIdentifier
                             direction:(LTScrollDirection)direction {
  LTAssert([collectionView lt_isCollectionView], @"%@",
           [collectionView lt_collectionViewTypeAssertionMessage]);
  if (self = [super init]) {
    _collectionView = collectionView;
    _reversed = LTIsDirectionReversedToCollectionView(direction);
    [self setNextIndexWithCurrentCellIdentifier:cellIdentifier];
  }
  return self;
}

- (void)setNextIndexWithCurrentCellIdentifier:(nullable NSString *)cellIdentifier {
  NSInteger cellIndex;
  if (cellIdentifier) {
    cellIndex = [self.collectionView lt_collectionViewIndexOfVisibleCell:(lt::nn(cellIdentifier))];
  } else {
    cellIndex = NSNotFound;
  }
  if (cellIndex == NSNotFound) {
    self.nextIndex = self.reversed ? self.collectionView.cells.count - 1 : 0;
  } else {
    self.nextIndex = self.reversed ? cellIndex - 1 : cellIndex + 1;
  }
}

- (BOOL)hasNext {
  if (self.reversed) {
    return self.nextIndex >= 0;
  } else {
    return self.nextIndex < (NSInteger)self.collectionView.cells.count;
  }
}

- (nullable XCUIElement *)next {
  if (![self hasNext]) {
    return nil;
  }
  NSInteger currentIndex = self.nextIndex;
  if (self.reversed) {
    --self.nextIndex;
  } else {
    ++self.nextIndex;
  }
  return [self.collectionView.cells elementBoundByIndex:currentIndex];
}

@end

@implementation XCUIElement (CollectionView)

- (void)lt_collectionViewIterateFromCurrentPositionInDirection:(LTScrollDirection)direction
                                                       withBlock:(LTCellIterationBlock)block {
  LTAssert([self lt_isCollectionView], @"%@", [self lt_collectionViewTypeAssertionMessage]);
  NSString * _Nullable lastCellVisitedIdentifier = nil;
  NSString * _Nullable lastVisibleCellIdentifier = nil;
  while (![lastCellVisitedIdentifier isEqual:lastVisibleCellIdentifier]) {
    LTVisibleCellsIterator *it = [[LTVisibleCellsIterator alloc]
                                  initWithCollectionView:self
                                  currentCellIdentifier:lastCellVisitedIdentifier
                                  direction:direction];
    while ([it hasNext]) {
      XCUIElement *cell = [it next];
      if (!CGRectContainsPoint(self.frame, cell.frame.origin)) {
        continue;
      }
      lastCellVisitedIdentifier = cell.identifier;
      if (block(cell) == LTIterationStepResultStopIterating) {
        return;
      }
    }
    [self lt_collectionViewScrollInDirection:direction];
    NSUInteger lastVisibleCellIndex;
    if (LTIsDirectionReversedToCollectionView(direction)) {
      lastVisibleCellIndex = 0;
    } else {
      lastVisibleCellIndex = self.cells.count - 1;
    }
    lastVisibleCellIdentifier = [self.cells elementBoundByIndex:lastVisibleCellIndex].identifier;
  }
}

- (void)lt_collectionViewScrollInDirection:(LTScrollDirection)direction {
  LTAssert([self lt_isCollectionView], @"%@", [self lt_collectionViewTypeAssertionMessage]);
  auto rightMiddle = [self coordinateWithNormalizedOffset:CGVectorMake(1.0, 0.5)];
  auto leftMiddle = [self coordinateWithNormalizedOffset:CGVectorMake(0.0 ,0.5)];
  auto buttomMiddle = [self coordinateWithNormalizedOffset:CGVectorMake(0.5, 1.0)];
  auto topMiddle = [self coordinateWithNormalizedOffset:CGVectorMake(0.5, 0.0)];
  auto center = [self coordinateWithNormalizedOffset:CGVectorMake(0.5, 0.5)];
  NSTimeInterval pressDuration = 0.1;
  switch (direction) {
    case LTScrollDirectionUp:
      [center pressForDuration:pressDuration thenDragToCoordinate:buttomMiddle];
      break;
    case LTScrollDirectionDown:
      [center pressForDuration:pressDuration thenDragToCoordinate:topMiddle];
      break;
    case LTScrollDirectionLeft:
      [center pressForDuration:pressDuration thenDragToCoordinate:rightMiddle];
      break;
    case LTScrollDirectionRight:
      [center pressForDuration:pressDuration thenDragToCoordinate:leftMiddle];
      break;
  }
}

- (void)lt_collectionViewScrollToContentEdgeInDirection:(LTScrollDirection)direction {
  LTAssert([self lt_isCollectionView], @"%@", [self lt_collectionViewTypeAssertionMessage]);
  [self lt_collectionViewIterateFromCurrentPositionInDirection:direction
                                                     withBlock:^(XCUIElement __unused *cell) {
    return LTIterationStepResultKeepIterating;
  }];
}

- (void)lt_collectionViewIterateFromContentEdgeInDirection:(LTScrollDirection)direction
                                                 withBlock:(LTCellIterationBlock)block {
  LTAssert([self lt_isCollectionView], @"%@", [self lt_collectionViewTypeAssertionMessage]);
  LTScrollDirection oppositeDirection = [XCUIElement lt_getOppositeDirection:direction];
  [self lt_collectionViewScrollToContentEdgeInDirection:oppositeDirection];
  [self lt_collectionViewIterateFromCurrentPositionInDirection:direction withBlock:block];
}

- (void)lt_collectionViewPressAllCellsInDirection:(LTScrollDirection)direction {
  LTAssert([self lt_isCollectionView], @"%@", [self lt_collectionViewTypeAssertionMessage]);
  [self lt_collectionViewIterateFromContentEdgeInDirection:direction
                                                 withBlock:^(XCUIElement *cell) {
    [self lt_collectionViewPressCellCoordinate:cell];
    return LTIterationStepResultKeepIterating;
  }];
}

+ (LTScrollDirection)lt_getOppositeDirection:(LTScrollDirection)direction {
  NSNumber *oppositeDirectionNSNumber = (NSNumber *)[kLTOppositeDirection
                                                     objectForKey:@(direction)];
  return (LTScrollDirection)(oppositeDirectionNSNumber.unsignedIntegerValue);
}

- (BOOL)lt_collectionViewScrollTo:(NSString *)cellIdentifier
                      inDirection:(LTScrollDirection)direction press:(BOOL)shouldPress {
  LTAssert([self lt_isCollectionView], @"%@", [self lt_collectionViewTypeAssertionMessage]);
  __block BOOL cellFound = NO;
  [self lt_collectionViewIterateFromContentEdgeInDirection:direction
                                                 withBlock:^(XCUIElement *cell) {
    if ([cell.identifier isEqualToString:cellIdentifier]) {
      if (shouldPress) {
        [self lt_collectionViewPressCellCoordinate:cell];
      }
      cellFound = YES;
      return LTIterationStepResultStopIterating;
    }
    return LTIterationStepResultKeepIterating;
  }];
  return cellFound;
}

- (XCUICoordinate *)lt_collectionViewGetCellCoordinate:(XCUIElement *)cell {
  LTAssert([self lt_isCollectionView], @"%@", [self lt_collectionViewTypeAssertionMessage]);
  auto cellCenterX = cell.frame.origin.x + cell.frame.size.width * 0.5;
  auto cellCenterY = cell.frame.origin.y + cell.frame.size.height * 0.5;
  auto normalizedXOffset = (cellCenterX - self.frame.origin.x) / self.frame.size.width;
  auto normalizedYOffset = (cellCenterY - self.frame.origin.y) / self.frame.size.height;
  return [self coordinateWithNormalizedOffset:CGVectorMake(normalizedXOffset, normalizedYOffset)];
}

- (void)lt_collectionViewPressCellCoordinate:(XCUIElement *)cell {
  LTAssert([self lt_isCollectionView], @"%@", [self lt_collectionViewTypeAssertionMessage]);
  [[self lt_collectionViewGetCellCoordinate:cell] pressForDuration:0.1];
}

@end

NS_ASSUME_NONNULL_END
