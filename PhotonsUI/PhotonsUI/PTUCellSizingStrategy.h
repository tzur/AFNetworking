// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

NS_ASSUME_NONNULL_BEGIN

/// Protocol for cell sizing strategies to adhere to. Used by a \c PTUCollectionViewController, this
/// protocol helps determine how to size cells given the current view size, inter item spacing and
/// line spacing for them to properly displayed.
@protocol PTUCellSizingStrategy <NSObject>

/// The size of cell to use within a view of size \c viewSize with \c itemSpacing and
/// \c lineSpacing.
- (CGSize)cellSizeForViewSize:(CGSize)viewSize itemSpacing:(CGFloat)itemSpacing
                  lineSpacing:(CGFloat)lineSpacing;

@end

/// Factory class for cell sizing strategies.
@interface PTUCellSizingStrategy : NSObject

/// Returns a cell sizing strategy that always returns \c size.
+ (id<PTUCellSizingStrategy>)constant:(CGSize)size;

/// Returns a cell sizing strategy that returns the size closest to \c size by scaling up to or down
/// to \c size * \c maximumScale such that there exists a natural number of cells that will fill
/// the width of the containing view exactly, or \c size if no such width exists without scaling
/// beyond \c maximumScale. \c If \c preserveAspectRatio is \c YES both dimensions of \c size will
/// be scaled, otherwise just the width will be altered.
///
/// @note The strategy thrives for the size closest to the given \c size. As such a strategy with
/// a size of <tt>(100, 100)</tt> and a scaling of \c 1.5 and a strategy with a size of
/// <tt>(150, 150)</tt> and a scaling of \c 0.66 will both return sizes in the range
/// <tt>[100, 150]</tt>, but the first will choose the smallest value that fits perfectly within the
/// content view, while the latter will choose the largest.
+ (id<PTUCellSizingStrategy>)adaptiveFitRow:(CGSize)size maximumScale:(CGFloat)maximumScale
                        preserveAspectRatio:(BOOL)preserveAspectRatio;

/// Returns a cell sizing strategy that returns the size closest to \c size by scaling up to or down
/// to \c size * \c maximumScale  such that there exists a natural number of cells that will fill
/// the height of the containing view exactly, or \c size if no such height exists without scaling
/// beyond \c maximumScale. \c If \c preserveAspectRatio is \c YES both dimensions of \c size will
/// be scaled, otherwise just the height will be altered.
///
/// @note The strategy thrives for the size closest to the given \c size. As such a strategy with
/// a size of <tt>(100, 100)</tt> and a scaling of \c 1.5 and a strategy with a size of
/// <tt>(150, 150)</tt> and a scaling of \c 0.66 will both return sizes in the range
/// <tt>[100, 150]</tt>, but the first will choose the smallest value that fits perfectly within the
/// content view, while the latter will choose the largest.
+ (id<PTUCellSizingStrategy>)adaptiveFitColumn:(CGSize)size maximumScale:(CGFloat)maximumScale
                           preserveAspectRatio:(BOOL)preserveAspectRatio;

/// Returns a cell sizing strategy that returns cells as wide as the containing view size and as
/// high as \c height.
+ (id<PTUCellSizingStrategy>)rowWithHeight:(CGFloat)height;

/// Returns a cell sizing strategy that returns cells as wide as the view size and as high as
/// the containing view's width multiplied by \c ratio.
+ (id<PTUCellSizingStrategy>)rowWithWidthRatio:(CGFloat)ratio;

/// Returns a cell sizing strategy that returns square cells such that \c itemsPerRow of them
/// will exactly fill the width of the containing view.
+ (id<PTUCellSizingStrategy>)gridWithItemsPerRow:(NSUInteger)itemsPerRow;

/// Returns a cell sizing strategy that returns square cells such that \c itemsPerRow of them
/// will exactly fill the height of the containing view.
+ (id<PTUCellSizingStrategy>)gridWithItemsPerColumn:(NSUInteger)itemsPerColumn;

@end

/// Cell sizing strategy that returns a constant size.
@interface PTUConstantCellSizingStrategy : NSObject <PTUCellSizingStrategy>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c size.
- (instancetype)initWithSize:(CGSize)size NS_DESIGNATED_INITIALIZER;

@end

/// Cell sizing strategy that returns a constant size with limited adaptations for perfect fitting.
@interface PTUAdaptiveCellSizingStrategy : NSObject <PTUCellSizingStrategy>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c size as the original size, \c maximumScale as the maximum scaling to apply
/// in order for a natural number of cells to perfectly fit the width or height of the containing
/// view based on whether \c matchWidth is \c YES or \c NO respectively, and \c preserveAspectRatio
/// determining whether to apply any scaling to both dimensions or just the fitted one.
- (instancetype)initWithSize:(CGSize)size maximumScale:(CGFloat)maximumScale
                  matchWidth:(BOOL)matchWidth preserveAspectRatio:(BOOL)preserveAspectRatio
    NS_DESIGNATED_INITIALIZER;

@end

/// Cell sizing strategy that returns rows as wide as the given view and with given height.
@interface PTURowSizingStrategy : NSObject <PTUCellSizingStrategy>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c height to determine the height of each cell size returned by this strategy,
/// the width of each cell is the width of the containing view.
- (instancetype)initWithHeight:(CGFloat)height NS_DESIGNATED_INITIALIZER;


@end

/// Cell sizing strategy that returns rows as wide as the given view and high as the width of that
/// view multiplied by a given ratio.
@interface PTUDynamicRowSizingStrategy : NSObject <PTUCellSizingStrategy>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c ratio to determine the height of each cell size returned by this strategy,
/// the height is determined to be the width of the containing view multiplied by \c ratio, the
/// width of each cell is the width of the containing view.
- (instancetype)initWithWidthRatio:(CGFloat)ratio NS_DESIGNATED_INITIALIZER;

@end

/// Cell sizing strategy that returns a squares perfectly sized to fit a given amount of items per
/// row or column.
@interface PTUGridSizingStrategy : NSObject <PTUCellSizingStrategy>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c itemsPerRow.
- (instancetype)initWithItemsPerRow:(NSUInteger)itemsPerRow NS_DESIGNATED_INITIALIZER;

/// Initializes with \c itemsPerColumn.
- (instancetype)initWithItemsPerColumn:(NSUInteger)itemsPerColumn NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
