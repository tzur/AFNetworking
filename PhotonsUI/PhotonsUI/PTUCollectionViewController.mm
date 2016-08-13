// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTUCollectionViewController.h"

#import <LTKit/LTCGExtensions.h>
#import <Photons/PTNDescriptor.h>

#import "PTUAlbumChangesetProvider.h"
#import "PTUCellSizingStrategy.h"
#import "PTUChangesetMetadata.h"
#import "PTUChangesetProvider.h"
#import "PTUCollectionViewConfiguration.h"
#import "PTUDataSource.h"
#import "PTUDataSourceProvider.h"
#import "PTUImageCell.h"
#import "PTUImageCellViewModelProvider.h"

NS_ASSUME_NONNULL_BEGIN

/// Subclass of \c UICollectionViewFlowLayout enabling auto-invalidation on size change.
@interface PTUCollectionViewFlowLayout : UICollectionViewFlowLayout
@end

@implementation PTUCollectionViewFlowLayout

- (UICollectionViewLayoutInvalidationContext *)invalidationContextForBoundsChange:
    (CGRect)newBounds {
  UICollectionViewFlowLayoutInvalidationContext *context =
      (UICollectionViewFlowLayoutInvalidationContext *)
      [super invalidationContextForBoundsChange:newBounds];

  context.invalidateFlowLayoutDelegateMetrics = newBounds.size != self.collectionView.bounds.size;

  return context;
}

@end

@interface PTUCollectionViewController () <UICollectionViewDelegateFlowLayout, UIScrollViewDelegate>

/// Provider of \c PTUDataSource conforming objects.
@property (readonly, nonatomic) id<PTUDataSourceProvider> dataSourceProvider;

/// Currently used configuration as a readwrite variable.
@property (strong, nonatomic) PTUCollectionViewConfiguration *configuration;

/// Collection view used to display data.
@property (readonly, nonatomic) UICollectionView *collectionView;

/// Current data source keeping internal collection view up to date with signals from
/// \c changesetProvider.
@property (strong, nonatomic) id<PTUDataSource> dataSource;

/// Current cached cell size to use for albums.
@property (nonatomic) CGSize albumCellSize;

/// Current cached cell size to use for assets.
@property (nonatomic) CGSize assetCellSize;

@end

@implementation PTUCollectionViewController

@synthesize itemSelected = _itemSelected;
@synthesize itemDeselected = _itemDeselected;
@synthesize emptyView = _emptyView;
@synthesize errorView = _errorView;
@synthesize localizedTitle = _localizedTitle;
@synthesize backgroundView = _backgroundView;

- (instancetype)initWithDataSourceProvider:(id<PTUDataSourceProvider>)dataSourceProvider
                      initialConfiguration:(PTUCollectionViewConfiguration *)initialConfiguration {
  if (self = [super initWithNibName:nil bundle:nil]) {
    _dataSourceProvider = dataSourceProvider;
    [self setup];
    [self setConfiguration:initialConfiguration animated:NO];
  }
  return self;
}

- (instancetype)initWithAssetManager:(id<PTNAssetManager>)assetManager albumURL:(NSURL *)url {
  PTUAlbumChangesetProvider *changesetProvider =
      [[PTUAlbumChangesetProvider alloc] initWithManager:assetManager albumURL:url];
  id<PTUImageCellViewModelProvider> cellViewModelProvider =
      [[PTUImageCellViewModelProvider alloc] initWithAssetManager:assetManager];
  id<PTUDataSourceProvider> dataSourceProvider =
      [[PTUDataSourceProvider alloc] initWithChangesetProvider:changesetProvider
                                         cellViewModelProvider:cellViewModelProvider
                                                     cellClass:[PTUImageCell class]];
  PTUCollectionViewConfiguration *configuration =
      [PTUCollectionViewConfiguration defaultConfiguration];

  return [self initWithDataSourceProvider:dataSourceProvider initialConfiguration:configuration];
}

- (void)setup {
  [self setupCollectionView];
  [self setupSelectionSignals];
  [self setupControlSignals];
  [self setupTitleBinding];
  [self setupInfoViews];
  [self buildDefaultEmptyView];
  [self buildDefaultErrorView];
  [self reloadData];
}

- (void)setupCollectionView {
  UICollectionViewFlowLayout *layout = [self layoutFromCurrentConfiguration];
  _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
  self.collectionView.accessibilityIdentifier = @"CollectionView";
  self.collectionView.delegate = self;
  self.collectionView.allowsMultipleSelection = YES;
  self.collectionView.backgroundColor = [UIColor clearColor];

  [self.view addSubview:self.collectionView];
  [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.edges.equalTo(self.view);
  }];
}

- (void)setupSelectionSignals {
  @weakify(self);
  _itemSelected =
      [[self rac_signalForSelector:@selector(collectionView:shouldSelectItemAtIndexPath:)]
      reduceEach:(id)^id<PTNDescriptor>(UICollectionView *, NSIndexPath *index) {
        @strongify(self);
        return [self.dataSource descriptorAtIndexPath:index];
      }];
  _itemDeselected =
      [[self rac_signalForSelector:@selector(collectionView:shouldDeselectItemAtIndexPath:)]
      reduceEach:(id)^id<PTNDescriptor>(UICollectionView *, NSIndexPath *index) {
        @strongify(self);
        return [self.dataSource descriptorAtIndexPath:index];
      }];
}

- (BOOL)collectionView:(UICollectionView __unused *)collectionView
    shouldSelectItemAtIndexPath:(nonnull NSIndexPath __unused *)indexPath {
  return NO;
}

- (BOOL)collectionView:(UICollectionView __unused *)collectionView
    shouldDeselectItemAtIndexPath:(nonnull NSIndexPath __unused *)indexPath {
  return NO;
}

- (void)setupControlSignals {
  @weakify(self);
  [[[[[RACSignal
      combineLatest:@[
        [self rac_signalForSelector:@selector(selectItem:)],
        [RACObserve(self, dataSource.didUpdateCollectionView) switchToLatest]
      ]]
      reduceEach:(id)^NSIndexPath * _Nullable (RACTuple *selectedItem, NSNumber *) {
        @strongify(self);
        return [self.dataSource indexPathOfDescriptor:selectedItem.first];
      }]
      ignore:nil]
      takeUntil:self.rac_willDeallocSignal]
      subscribeNext:^(NSIndexPath *indexPath) {
        @strongify(self);
        [self.collectionView selectItemAtIndexPath:indexPath animated:NO
                                    scrollPosition:UICollectionViewScrollPositionNone];
      }];
  
  [[[[[[[self rac_signalForSelector:@selector(scrollToItem:atScrollPosition:animated:)
                       fromProtocol:@protocol(PTUCollectionViewController)]
      map:^RACSignal *(RACTuple *value) {
        @strongify(self);
        return [[RACSignal
            combineLatest:@[
              [RACSignal return:value],
              [[RACObserve(self, dataSource.didUpdateCollectionView)
                  switchToLatest]
                  startWith:[RACUnit defaultUnit]]
            ]]
            takeUntil:[self rac_signalForSelector:@selector(scrollViewDidScroll:)]];
      }]
      switchToLatest]
      reduceEach:(id)^RACTuple *(RACTuple *scrollToItem, NSNumber *) {
        @strongify(self);
        RACTupleUnpack(id<PTNDescriptor> item, NSNumber *position, NSNumber *animated) =
            scrollToItem;
        NSIndexPath * _Nullable indexPath = [self.dataSource indexPathOfDescriptor:item];
        PTUCollectionViewScrollPosition scrollPosition =
            (PTUCollectionViewScrollPosition)position.unsignedIntegerValue;
        UICollectionViewScrollPosition nativeScrollPosition =
            [self collectionViewScrollPosition:scrollPosition];
        
        return RACTuplePack(indexPath, @(nativeScrollPosition), animated);
      }]
      filter:^BOOL(RACTuple *scrollToItem) {
        return scrollToItem.first != nil;
      }]
      takeUntil:self.rac_willDeallocSignal]
      subscribeNext:^(RACTuple *scrollToItem) {
        @strongify(self);
        RACTupleUnpack(NSIndexPath *indexPath, NSNumber *position, NSNumber *animated) =
            scrollToItem;
        PTUCollectionViewScrollPosition scrollPosition =
            (PTUCollectionViewScrollPosition)position.unsignedIntegerValue;
        
        [self.collectionView scrollToItemAtIndexPath:indexPath
                                    atScrollPosition:scrollPosition
                                            animated:animated.boolValue];
      }];
}

- (void)scrollViewDidScroll:(UIScrollView __unused *)scrollView {
  // Required for signal.
}

- (void)selectItem:(id<PTNDescriptor> __unused)item {
  // Required by protocol.
}

- (void)scrollToItem:(id<PTNDescriptor> __unused)item
    atScrollPosition:(PTUCollectionViewScrollPosition __unused)position
            animated:(BOOL __unused)animated {
  // Required by protocol.
}

- (UICollectionViewScrollPosition)collectionViewScrollPosition:
    (PTUCollectionViewScrollPosition)position {
  switch (position) {
    case PTUCollectionViewScrollPositionTopLeft:
      return [self scrollsVertically] ?
          UICollectionViewScrollPositionTop :
          UICollectionViewScrollPositionLeft;
    case PTUCollectionViewScrollPositionCenter:
      return [self scrollsVertically] ?
          UICollectionViewScrollPositionCenteredVertically :
          UICollectionViewScrollPositionCenteredHorizontally;
    case PTUCollectionViewScrollPositionBottomRight:
      return [self scrollsVertically] ?
          UICollectionViewScrollPositionBottom :
          UICollectionViewScrollPositionRight;
    default:
      LTAssert(NO, @"PTUCollectionViewScrollPosition %lu can not be translated to "
               "UICollectionViewScrollPosition", (unsigned long)position);
  }
}

- (void)setupTitleBinding {
  RACSignal *datasourceTitle = RACObserve(self, dataSource.title);
  RAC(self, localizedTitle) = datasourceTitle;
  RAC(self, title) = datasourceTitle;
}

- (void)setupInfoViews {
  @weakify(self);
  RACSignal *hideEmptyView = [[[[RACObserve(self, emptyView)
      map:^RACStream *(id) {
        @strongify(self);
        return RACObserve(self, dataSource.hasData);
      }]
      switchToLatest]
      combineLatestWith:RACObserve(self, dataSource.error)]
      map:^NSNumber *(RACTuple *tuple) {
        RACTupleUnpack(NSNumber * _Nullable hasData, NSError * _Nullable error) = tuple;
        return @(hasData.boolValue || error != nil);
      }];

  RACSignal *hideErrorView = [[[RACObserve(self, errorView)
      map:^RACStream *(id) {
        @strongify(self);
        return RACObserve(self, dataSource.error);
      }]
      switchToLatest]
      map:^NSNumber *(NSError * _Nullable error) {
        return @(error == nil);
      }];
  
  RAC(self, emptyView.hidden) = hideEmptyView;
  RAC(self, errorView.hidden) = hideErrorView;
  RAC(self, collectionView.hidden) = [RACSignal
    combineLatest:@[hideEmptyView, hideErrorView]
    reduce:(id)^NSNumber *(NSNumber *hideEmpty, NSNumber *hideError) {
      return @(!hideEmpty.boolValue || !hideError.boolValue);
    }];

  [self buildDefaultEmptyView];
  [self buildDefaultErrorView];
}

- (void)buildDefaultEmptyView {
  self.emptyView = [[UIView alloc] initWithFrame:CGRectZero];

  UILabel *noPhotosLabel = [[UILabel alloc] initWithFrame:CGRectZero];
  noPhotosLabel.text = @"No photos";
  noPhotosLabel.textAlignment = NSTextAlignmentCenter;
  noPhotosLabel.font = [UIFont italicSystemFontOfSize:15];
  noPhotosLabel.textColor = [UIColor lightGrayColor];

  [self.emptyView addSubview:noPhotosLabel];
  [noPhotosLabel mas_makeConstraints:^(MASConstraintMaker *make) {
    make.bottom.equalTo(self.mas_topLayoutGuide).with.offset(44);
    make.centerX.equalTo(self.emptyView);
  }];
}

- (void)buildDefaultErrorView {
  self.errorView = [[UIView alloc] initWithFrame:CGRectZero];

  UILabel *errorLabel = [[UILabel alloc] initWithFrame:CGRectZero];
  errorLabel.text = @"Error fetching data";
  errorLabel.textAlignment = NSTextAlignmentCenter;
  errorLabel.font = [UIFont italicSystemFontOfSize:15];
  errorLabel.textColor = [UIColor lightGrayColor];

  [self.errorView addSubview:errorLabel];
  [errorLabel mas_makeConstraints:^(MASConstraintMaker *make) {
    make.bottom.equalTo(self.mas_topLayoutGuide).with.offset(44);
    make.centerX.equalTo(self.errorView);
  }];
}

- (void)viewDidLayoutSubviews {
  [super viewDidLayoutSubviews];
  self.albumCellSize = [self.configuration.albumCellSizingStrategy
      cellSizeForViewSize:self.view.frame.size itemSpacing:self.configuration.minimumItemSpacing
              lineSpacing:self.configuration.minimumLineSpacing];
  self.assetCellSize = [self.configuration.assetCellSizingStrategy
      cellSizeForViewSize:self.view.frame.size itemSpacing:self.configuration.minimumItemSpacing
              lineSpacing:self.configuration.minimumLineSpacing];
}

#pragma mark -
#pragma mark Public interface
#pragma mark -

- (void)setEmptyView:(UIView *)emptyView {
  [self.emptyView removeFromSuperview];

  _emptyView = emptyView;
  self.emptyView.accessibilityIdentifier = @"Empty";
  [self.view insertSubview:self.emptyView aboveSubview:self.collectionView];
  [self.emptyView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.edges.equalTo(self.view);
  }];
}

- (void)setErrorView:(UIView *)errorView {
  [self.errorView removeFromSuperview];

  _errorView = errorView;
  self.errorView.accessibilityIdentifier = @"Error";
  [self.view insertSubview:self.errorView aboveSubview:self.collectionView];
  [self.errorView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.edges.equalTo(self.view);
  }];
}

- (void)setBackgroundColor:(UIColor *)color {
  self.collectionView.backgroundColor = color;
}

- (UIColor *)backgroundColor {
  return self.collectionView.backgroundColor;
}

- (void)setBackgroundView:(nullable UIView *)backgroundView {
  [_backgroundView removeFromSuperview];

  if (backgroundView) {
    [self.view insertSubview:backgroundView belowSubview:self.collectionView];
    [backgroundView mas_makeConstraints:^(MASConstraintMaker *make) {
      make.edges.equalTo(self.view);
    }];
  }
  _backgroundView = backgroundView;
}

#pragma mark -
#pragma mark PTUCollectionViewController
#pragma mark -

- (void)setConfiguration:(PTUCollectionViewConfiguration *)configuration animated:(BOOL)animated {
  _configuration = configuration;
  PTUCollectionViewFlowLayout *layout = [self layoutFromCurrentConfiguration];
  
  self.collectionView.showsHorizontalScrollIndicator = configuration.showsHorizontalScrollIndicator;
  self.collectionView.showsVerticalScrollIndicator = configuration.showsVerticalScrollIndicator;
  self.collectionView.pagingEnabled = configuration.enablePaging;

  [self.collectionView setCollectionViewLayout:layout animated:animated];
}

- (PTUCollectionViewFlowLayout *)layoutFromCurrentConfiguration {
  PTUCollectionViewFlowLayout *layout = [[PTUCollectionViewFlowLayout alloc] init];
  layout.minimumLineSpacing = self.configuration.minimumLineSpacing;
  layout.minimumInteritemSpacing = self.configuration.minimumItemSpacing;
  layout.scrollDirection = self.configuration.scrollDirection;
  return layout;
}

- (BOOL)scrollsVertically {
  return self.configuration.scrollDirection == UICollectionViewScrollDirectionVertical;
}

- (void)scrollToTopAnimated:(BOOL)animated {
  [self.collectionView setContentOffset:CGPointZero animated:animated];
}

- (void)deselectItem:(id<PTNDescriptor>)item {
  NSIndexPath *indexPath = [self.dataSource indexPathOfDescriptor:item];
  if (!indexPath) {
    return;
  }
  
  [self.collectionView deselectItemAtIndexPath:indexPath animated:NO];
}

- (void)reloadData {
  self.dataSource = [self.dataSourceProvider dataSourceForCollectionView:self.collectionView];
}

#pragma mark -
#pragma mark UICollectionViewDelegateFlowLayout
#pragma mark -

- (CGSize)collectionView:(UICollectionView __unused *)collectionView
                  layout:(UICollectionViewLayout __unused *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
  id<PTNDescriptor> descriptor = [self.dataSource descriptorAtIndexPath:indexPath];
  if ([descriptor conformsToProtocol:@protocol(PTNAlbumDescriptor)]) {
    return self.albumCellSize;
  }
  return self.assetCellSize;
}

@end

NS_ASSUME_NONNULL_END
