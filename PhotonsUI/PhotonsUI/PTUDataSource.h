// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

@protocol PTNAssetManager, PTNDescriptor, PTUChangesetProvider, PTUImageCellViewModelProvider;

NS_ASSUME_NONNULL_BEGIN

/// Class for keeping a given \c UICollectionView up to date with a given \c dataSignal. Acting as
/// its \c UICollectionViewDataSource and offloading all data source requirements, including
/// maintaining up to date data and applying incremental updates.
@interface PTUDataSource : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c collectionView as the view to keep up to date with the signals of the given
/// \c changesetProvider defining the data managed, \c cellViewModelProvider as provider of
/// \c PTUImageCellViewModel objects and \c cellClass as the class to use for each cell.
///
/// @note \c cellClass must be a subclass of \c UICollectionViewCell that conforms to the
/// \c PTUImageCell.
- (instancetype)initWithCollectionView:(UICollectionView *)collectionView
                     changesetProvider:(id<PTUChangesetProvider>)changesetProvider
                 cellViewModelProvider:(id<PTUImageCellViewModelProvider>)cellViewModelProvider
                             cellClass:(Class)cellClass NS_DESIGNATED_INITIALIZER;

/// Returns the \c PTNDescriptor at \c index according to the latest bound \c dataSignal or \c nil
/// if \c index is out of bounds.
- (nullable id<PTNDescriptor>)objectAtIndexPath:(NSIndexPath *)index;

/// Returns the index path to \c object according to the latest bound \c dataSignal or \c nil if
/// \c object isn't in this data source. If \c object exists in multiple sections, the first one
/// will be returned.
- (nullable NSIndexPath *)indexPathOfObject:(id<PTNDescriptor>)object;

/// \c YES if the latest value sent by the data signal provided by \c changesetProvider indicated
/// the existance of at least one object. This property is KVO compliant.
@property (readonly, nonatomic) BOOL hasData;

/// Error sent on data signal provided by \c changesetProvider or \c nil of no such error was sent.
/// This property is KVO compliant.
@property (readonly, nonatomic, nullable) NSError *error;

@end

NS_ASSUME_NONNULL_END
