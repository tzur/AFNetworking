// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

@protocol PTNAssetManager, PTNDescriptor, PTUChangesetProvider, PTUImageCellViewModelProvider;

NS_ASSUME_NONNULL_BEGIN

/// Protocol for objects keeping a given \c UICollectionView up to date with some data. Acting as
/// its \c UICollectionViewDataSource and offloading all data source requirements, including
/// maintaining up to date data and applying incremental updates.
@protocol PTUDataSource <NSObject>

/// Returns the \c PTNDescriptor at \c index according to the current data of the receiver or \c nil
/// if \c index is out of bounds of the receiver's data.
- (nullable id<PTNDescriptor>)descriptorAtIndexPath:(NSIndexPath *)index;

/// Returns the index path to \c object according to the current data represented by the receiver or
/// \c nil if cannot be found. If \c object exists in multiple sections, the first occurrence will
/// be returned.
- (nullable NSIndexPath *)indexPathOfDescriptor:(id<PTNDescriptor>)descriptor;

/// Returns the \c NSString section title at \c section according to the current data of the
/// receiver or \c nil if \c section is out of bounds of the receiver's data, or if the
/// corresponding section has no title.
- (nullable NSString *)titleForSection:(NSInteger)section;

/// Hot signal sending a \c RACUnit every time the receiver's collection view is updated and
/// completes when the receiver is deallocated.
@property (readonly, nonatomic) RACSignal *didUpdateCollectionView;

/// Title associated with the data provided in this data source, or \c nil if no such title exists.
/// This property is KVO compliant.
@property (readonly, nonatomic, nullable) NSString *title;

/// \c YES if the data source currently represents data of at least one section with at least one
/// item. This property is KVO compliant.
@property (readonly, nonatomic) BOOL hasData;

/// Error that occurred while fetching data, fetching metadata or applying updates to the collection
/// view, or \c nil if no such error occurred. This property is KVO compliant.
@property (readonly, nonatomic, nullable) NSError *error;

@end

/// \c PTUDataSource implementation for keeping a given \c UICollectionView up to date with a given
/// \c changesetProvider. The receiver subscribes to the \c fetchChangeset signal of
/// \c changesetProvider and uses that signal to maintain the latest data and deliver appropriate
/// updates as they arrive as well as the \c fetchChangesetMetadata signal to update the latest
/// \c title property. \c cellViewModelProvder, \c cellClass and \c headerCellClass are used when
/// configuring the given \c collectionView content. The receiver applies incremental changes by
/// first mapping them all to insert and remove operations, and then applying them all in a single
/// batch operation.
@interface PTUDataSource : NSObject <PTUDataSource>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c collectionView as the view to keep up to date with the signals of the given
/// \c changesetProvider, \c cellViewModelProvider as provider of \c PTUImageCellViewModel objects
/// and \c cellClass as the class to use for each cell.
///
/// @note The reciever sets the \c collectionView's \c dataSource property. Setting its
/// \c dataSource after the initialization of this object is considered undefined behavior.
///
/// @note \c cellClass must be a subclass of \c UICollectionViewCell that conforms to the
/// \c PTUImageCell.
///
/// @note \c headerCellClass must be a subclass of \c UICollectionReusableView that conforms to the
/// \c PTUHeaderCell.
- (instancetype)initWithCollectionView:(UICollectionView *)collectionView
                     changesetProvider:(id<PTUChangesetProvider>)changesetProvider
                 cellViewModelProvider:(id<PTUImageCellViewModelProvider>)cellViewModelProvider
                             cellClass:(Class)cellClass headerCellClass:(Class)headerCellClass
    NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
