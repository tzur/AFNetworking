// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

NS_ASSUME_NONNULL_BEGIN

@protocol PTUCellSizingStrategy;

/// Value class defining the layout properties of a collection view within a
/// \c PTUCollectionViewController.
@interface PTUCollectionViewConfiguration : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with configuration parameters.
- (instancetype)initWithAssetCellSizingStrategy:(id<PTUCellSizingStrategy>)assetSizingStrategy
                        albumCellSizingStrategy:(id<PTUCellSizingStrategy>)albumSizingStrategy
                       headerCellSizingStrategy:(id<PTUCellSizingStrategy>)headerCellSizingStrategy
                             minimumItemSpacing:(CGFloat)minimumItemSpacing
                             minimumLineSpacing:(CGFloat)minimumLineSpacing
                                scrollDirection:(UICollectionViewScrollDirection)scrollDirection
                    showVerticalScrollIndicator:(BOOL)showVerticalScrollIndicator
                  showHorizontalScrollIndicator:(BOOL)showHorizontalScrollIndicator
                                   enablePaging:(BOOL)enablePaging
    NS_DESIGNATED_INITIALIZER;

/// Creates and returns a \c PTUCollectionViewConfiguration resembling that of the Photos app.
///   - \c assetSizingStrategy is set to
///     \c [PTUCellSizingStrategy adaptiveFitRow:(92, 92) maximumScale:1.2 preserveAspectRatio:YES].
///   - \c albumSizingStrategy of \c [PTUCellSizingStrategy rowWithHeight:100].
///   - \c headerSizingStrategy of \c [PTUCellSizingStrategy rowWithHeight:25].
///   - \c itemSpacing of \c 1.
///   - \c lineSpacing of \c 1.
///   - \c scrollDirection set to \c UICollectionViewScrollDirectionVertical.
///   - \c showVerticalScrollIndicator set to \c YES.
///   - \c showHorizontalScrollIndicator set to \c NO.
///   - \c enablePaging set to \c NO.
+ (instancetype)defaultConfiguration;

/// Creates and returns a \c PTUCollectionViewConfiguration suitable for a Photo selection strip.
///   - \c assetSizingStrategy is set to \c [PTUCellSizingStrategy gridWithItemsPerColumn:1].
///   - \c albumSizingStrategy of \c [PTUCellSizingStrategy gridWithItemsPerColumn:1].
///   - \c headerSizingStrategy of \c [PTUCellSizingStrategy constant:(0, 0)].
///   - \c itemSpacing of \c 0.
///   - \c lineSpacing of \c 1.
///   - \c scrollDirection set to \c UICollectionViewScrollDirectionHorizontal.
///   - \c showVerticalScrollIndicator set to \c NO.
///   - \c showHorizontalScrollIndicator set to \c NO.
///   - \c enablePaging set to \c NO.
+ (instancetype)photoStrip;

/// Creates and returns a \c PTUCollectionViewConfiguration adjusted for iPad devices.
///   - \c assetSizingStrategy is set to
///     \c [PTUCellSizingStrategy adaptiveFitRow:(140, 140) maximumScale:1.6 preserveAspectRatio:YES
///   - \c albumSizingStrategy of \c adaptiveFitRow:CGSizeMake(683, 150) maximumScale:0.3
///     preserveAspectRatio:NO].
///   - \c headerSizingStrategy of \c [PTUCellSizingStrategy rowWithHeight:25].
///   - \c itemSpacing of \c 1.
///   - \c lineSpacing of \c 1.
///   - \c scrollDirection set to \c UICollectionViewScrollDirectionVertical.
///   - \c showVerticalScrollIndicator set to \c YES.
///   - \c showHorizontalScrollIndicator set to \c NO.
///   - \c enablePaging set to \c NO.
+ (instancetype)defaultIPadConfiguration;

/// Creates and returns a \c PTUCollectionViewConfiguration based on the device idiom at runtime -
/// if the device is an iPad the \c defaultIPadConfiguration is returned, otherwise the
/// \c defaultConfiguration will be returned.
+ (instancetype)deviceAdjustableConfiguration;

/// Cell sizing strategy to determine the size of cells representing descriptors conforming to
/// \c PTNAssetDescriptor.
@property (readonly, nonatomic) id<PTUCellSizingStrategy> assetCellSizingStrategy;

/// Cell sizing strategy to determine the size of cells representing descriptors conforming to
/// \c PTNAlbumDescriptor.
@property (readonly, nonatomic) id<PTUCellSizingStrategy> albumCellSizingStrategy;

/// Cell sizing strategy to determine the size of header supplementary views.
@property (readonly, nonatomic) id<PTUCellSizingStrategy> headerCellSizingStrategy;

/// Minimum inter-item spacing in points.
@property (readonly, nonatomic) CGFloat minimumItemSpacing;

/// Minimum inter-line spacing in points.
@property (readonly, nonatomic) CGFloat minimumLineSpacing;

/// Scroll direction.
@property (readonly, nonatomic) UICollectionViewScrollDirection scrollDirection;

/// \c YES if the vertical scroll position indicator should be displayed.
@property (readonly, nonatomic) BOOL showsVerticalScrollIndicator;

/// \c YES if the horizontal scroll position indicator should be displayed.
@property (readonly, nonatomic) BOOL showsHorizontalScrollIndicator;

/// \c YES if paging should be enabled.
@property (readonly, nonatomic) BOOL enablePaging;

@end

NS_ASSUME_NONNULL_END
