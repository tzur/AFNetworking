// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTUCollectionViewController.h"

#import <LTKit/LTCGExtensions.h>
#import <LTKit/NSArray+Functional.h>
#import <Photons/NSError+Photons.h>
#import <Photons/PTNDescriptor.h>

#import "PTUAlbumChangesetProvider.h"
#import "PTUCellSizingStrategy.h"
#import "PTUChangesetMetadata.h"
#import "PTUChangesetProvider.h"
#import "PTUCollectionView.h"
#import "PTUCollectionViewConfiguration.h"
#import "PTUDataSource.h"
#import "PTUDataSourceProvider.h"
#import "PTUErrorViewProvider.h"
#import "PTUHeaderCell.h"
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
@property (readonly, nonatomic, nullable) UICollectionView *collectionView;

/// Current data source keeping internal collection view up to date with signals from
/// \c changesetProvider.
@property (strong, nonatomic) id<PTUDataSource> dataSource;

/// Current cached cell size to use for albums.
@property (nonatomic) CGSize albumCellSize;

/// Current cached cell size to use for assets.
@property (nonatomic) CGSize assetCellSize;

/// Current cached cell size to use for headers.
@property (nonatomic) CGSize headerCellSize;

/// Cache for cell sizes, assuming each section has homogenous cell types and omitting the need for
/// executing costly data source queries for each item. The need for this comes for the fact that
/// flow layout creates all the \c UICollectionViewLayoutAttribute objects in advance, rather than
/// only those presented. Causing extremely large albums to take very long to load.
@property (readonly, nonatomic) NSMutableDictionary *sectionItemSizeCache;

/// View of this controller.
@property (readonly, nonatomic) PTUCollectionView *view;

@end

@implementation PTUCollectionViewController

@synthesize itemSelected = _itemSelected;
@synthesize itemDeselected = _itemDeselected;
@synthesize localizedTitle = _localizedTitle;
@synthesize contentInset = _contentInset;

@dynamic view;

- (instancetype)initWithDataSourceProvider:(id<PTUDataSourceProvider>)dataSourceProvider
                      initialConfiguration:(PTUCollectionViewConfiguration *)initialConfiguration {
  if (self = [super initWithNibName:nil bundle:nil]) {
    _dataSourceProvider = dataSourceProvider;
    _configuration = initialConfiguration;
    [self setup];
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
                                                     cellClass:[PTUImageCell class]
                                               headerCellClass:[PTUHeaderCell class]];
  PTUCollectionViewConfiguration *configuration =
      [PTUCollectionViewConfiguration defaultConfiguration];

  return [self initWithDataSourceProvider:dataSourceProvider initialConfiguration:configuration];
}

- (void)setup {
  [self setupTitleBinding];
  [self setupSectionItemSizeCache];
  [self setupSelectionSignals];
  [self setupControlSignals];
  [self setupInfoViewBinding];
}

- (void)loadView {
  self.view = [[PTUCollectionView alloc] initWithFrame:CGRectZero];
}

- (void)setupTitleBinding {
  RACSignal *dataSourceTitle = RACObserve(self, dataSource.title);
  RAC(self, localizedTitle) = dataSourceTitle;
  RAC(self, title) = dataSourceTitle;
}

- (void)setupSectionItemSizeCache {
  _sectionItemSizeCache = [NSMutableDictionary dictionary];
  @weakify(self);
  [[RACSignal
      merge:@[
        [RACObserve(self, dataSource.didUpdateCollectionView) switchToLatest],
        [self rac_signalForSelector:@selector(viewDidLayoutSubviews)]
      ]]
      subscribeNext:^(id) {
        @strongify(self);
        [self.sectionItemSizeCache removeAllObjects];
      }];
}

#pragma mark -
#pragma mark Selection and scrolling
#pragma mark -

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
  // To support deferred controls we try the operation once initially, and then retry again on every
  // new data being loaded, or whenever the view appears.
  // The view appearance cue is necessary since successful scrolling requires valid contentSize in
  // the collection view, which is guaranteed only on appearance. This isn't a requirement for
  // selection but its added to it as well for good measure, as reselecting an already selected
  // asset has no effect.
  RACSignal *sampleDeferred = [RACSignal merge:@[
    [RACObserve(self, dataSource.didUpdateCollectionView) switchToLatest],
    [self rac_signalForSelector:@selector(viewDidAppear:)]
  ]];

  RACSignal *stopDeferring = [[self rac_signalForSelector:@selector(deselectItem:)]
      mapReplace:[RACUnit defaultUnit]];

  [[[[[[[self rac_signalForSelector:@selector(selectItem:)]
      reduceEach:(id)^RACStream *(id<PTNDescriptor> descriptor) {
        return [[[sampleDeferred
            mapReplace:descriptor]
            startWith:descriptor]
            takeUntil:stopDeferring];
      }]
      switchToLatest]
      map:^NSIndexPath * _Nullable(id<PTNDescriptor> descriptor) {
        @strongify(self);
        return [self.dataSource indexPathOfDescriptor:descriptor];
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
        // Deferred scrolling retries are made only until another scroll is made either
        // programmatically or via user interaction.
        return [[RACSignal
            combineLatest:@[
              [RACSignal return:value],
              [[RACObserve(self, dataSource.didUpdateCollectionView)
                  switchToLatest]
                  startWith:[RACUnit defaultUnit]],
              [[[self rac_signalForSelector:@selector(viewDidAppear:)]
                  mapReplace:[RACUnit defaultUnit]]
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

#pragma mark -
#pragma mark Info views
#pragma mark -

- (void)setupInfoViewBinding {
  @weakify(self);
  RACSignal *hideEmptyView = [[[[[RACObserve(self, emptyView)
      map:^RACStream *(id) {
        @strongify(self);
        return RACObserve(self, dataSource.hasData);
      }]
      switchToLatest]
      combineLatestWith:RACObserve(self, dataSource.error)]
      reduceEach:(id)^NSNumber *(NSNumber * _Nullable hasData, NSError * _Nullable error) {
        return @(hasData.boolValue || error != nil);
      }]
      deliverOnMainThread];

  RACSignal *hideErrorView = [[[[RACObserve(self, errorView)
      map:^RACStream *(id) {
        @strongify(self);
        return RACObserve(self, dataSource.error);
      }]
      switchToLatest]
      map:^NSNumber *(NSError * _Nullable error) {
        return @(error == nil);
      }]
      deliverOnMainThread];

  RAC(self, view.emptyView.hidden) = hideEmptyView;
  RAC(self, view.errorView.hidden) = hideErrorView;
  RAC(self, view.collectionViewContainer.hidden) = [RACSignal
    combineLatest:@[hideEmptyView, hideErrorView]
    reduce:(id)^NSNumber *(NSNumber *hideEmpty, NSNumber *hideError) {
      return @(!hideEmpty.boolValue || !hideError.boolValue);
    }];

  RAC(self, view.errorView) = [[[[[RACObserve(self, errorViewProvider)
      ignore:nil]
      map:^RACSignal *(id<PTUErrorViewProvider> errorViewProvider) {
        @strongify(self);
        return [RACSignal combineLatest:@[
          [RACSignal return:errorViewProvider],
          [RACObserve(self, dataSource.error) ignore:nil]
        ]];
      }]
      switchToLatest]
      deliverOnMainThread]
      reduceEach:(id)^UIView *(id<PTUErrorViewProvider> errorViewProvider, NSError *error) {
        return [errorViewProvider errorViewForError:error
                                      associatedURL:PTUExtractAssociatedURL(error)];
      }];
}

static NSURL * _Nullable PTUExtractAssociatedURL(NSError *error) {
  if (error.lt_url) {
    return error.lt_url;
  } else if (error.ptn_associatedDescriptor) {
    return error.ptn_associatedDescriptor.ptn_identifier;
  } else if (error.ptn_associatedDescriptors) {
    NSSet *urlSet = [NSSet setWithArray:[error.ptn_associatedDescriptors
        lt_map:^NSURL *(id<PTNDescriptor> descriptor) {
          return descriptor.ptn_identifier;
        }]];
    return urlSet.count == 1 ? urlSet.anyObject : nil;
  } else {
    return nil;
  }
}

- (void)viewDidLayoutSubviews {
  [super viewDidLayoutSubviews];
  auto contentSize = [self sizeAfterInset];
  self.albumCellSize = [self.configuration.albumCellSizingStrategy
      cellSizeForViewSize:contentSize itemSpacing:self.configuration.minimumItemSpacing
              lineSpacing:self.configuration.minimumLineSpacing];
  self.assetCellSize = [self.configuration.assetCellSizingStrategy
      cellSizeForViewSize:contentSize itemSpacing:self.configuration.minimumItemSpacing
              lineSpacing:self.configuration.minimumLineSpacing];
  self.headerCellSize = [self.configuration.headerCellSizingStrategy
      cellSizeForViewSize:contentSize itemSpacing:self.configuration.minimumItemSpacing
              lineSpacing:self.configuration.minimumLineSpacing];

  /// Collection view setup is deferred to this stage to avoid premature update queries. These
  /// queries are both unnecessary and potentially destructive if sent before valid cell sizes were
  /// set, possibly causing the collection view to attempt to load all cells of an album at once,
  /// when fetching visible cells, resulting in a lack of memory termination.
  if (!self.collectionView) {
    [self setupCollectionView];
    [self.view.collectionViewContainer addSubview:self.collectionView];
    [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
      make.edges.equalTo(self.view.collectionViewContainer);
    }];
  }
}

- (CGSize)sizeAfterInset {
  if ([self scrollsVertically]) {
    return CGSizeMake(
      self.view.frame.size.width - (self.contentInset.left + self.contentInset.right),
      self.view.frame.size.height
    );
  }
  return CGSizeMake(
    self.view.frame.size.width,
    self.view.frame.size.height - (self.contentInset.top + self.contentInset.bottom)
  );
}

- (void)setupCollectionView {
  UICollectionViewFlowLayout *layout = [self layoutFromCurrentConfiguration];
  _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
  self.collectionView.accessibilityIdentifier = @"CollectionView";
  self.collectionView.delegate = self;
  self.collectionView.allowsMultipleSelection = YES;
  self.collectionView.backgroundColor = [UIColor clearColor];
  self.collectionView.contentInset = self.contentInset;
  [self setConfiguration:self.configuration animated:NO];
  [self configureDataSource];
}

- (void)configureDataSource {
  self.dataSource = [self.dataSourceProvider dataSourceForCollectionView:self.collectionView];
}

#pragma mark -
#pragma mark Public interface
#pragma mark -

- (void)setEmptyView:(UIView *)emptyView {
  self.view.emptyView = emptyView;
}

- (UIView *)emptyView {
  return self.view.emptyView;
}

- (void)setErrorView:(UIView *)errorView {
  self.view.errorView = errorView;
}

- (UIView *)errorView {
  return self.view.errorView;
}

- (void)setBackgroundView:(nullable UIView *)backgroundView {
  self.view.backgroundView = backgroundView;
}

- (nullable UIView *)backgroundView {
  return self.view.backgroundView;
}

- (void)setBackgroundColor:(UIColor *)color {
  self.view.backgroundColor = color;
}

- (UIColor *)backgroundColor {
  return self.view.backgroundColor;
}

- (nullable UICollectionViewCell<PTUImageCell> *)cellAtPoint:(CGPoint)point {
  auto convertedPoint = [self.view convertPoint:point toView:self.collectionView];
  auto _Nullable index = [self.collectionView indexPathForItemAtPoint:convertedPoint];
  if (!index) {
    return nil;
  }

  return (UICollectionViewCell<PTUImageCell> *)[self.collectionView cellForItemAtIndexPath:index];
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
  self.collectionView.keyboardDismissMode = configuration.keyboardDismissMode;

  [self.view setNeedsLayout];
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
  [self configureDataSource];
}

- (void)setContentInset:(UIEdgeInsets)contentInset {
  _contentInset = contentInset;
  self.collectionView.contentInset = contentInset;

  [self.view setNeedsLayout];
}

#pragma mark -
#pragma mark UICollectionViewDelegateFlowLayout
#pragma mark -

- (void)collectionView:(UICollectionView *)collectionView
       willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
  // With prefetching enabled in iOS 10, deselecting doesn't work for cells that are already loaded
  // but not visible. These cells' selection status is not updated when they are not visible, much
  // like before, but now they are not being reused either before displayed since they remain in the
  // pre-fetch area ready to be shown again. Thus these cells remain selected until they are reused.
  // To avoid this we make sure deselected cells are updated when displayed.
  //
  // Opened radar 29400223.
  if (!cell.isSelected) {
    return;
  }

  if ([[collectionView indexPathsForSelectedItems] containsObject:indexPath]) {
    return;
  }

  cell.selected = NO;
}

- (CGSize)collectionView:(UICollectionView __unused *)collectionView
                  layout:(UICollectionViewLayout __unused *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
  NSValue * _Nullable cachedSize = self.sectionItemSizeCache[@(indexPath.section)];
  if (cachedSize) {
    return cachedSize.CGSizeValue;
  }

  CGSize size = [self sizeForItemAtIndexPath:indexPath];
  self.sectionItemSizeCache[@(indexPath.section)] = $(size);
  return size;
}

- (CGSize)sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
  id<PTNDescriptor> descriptor = [self.dataSource descriptorAtIndexPath:indexPath];
  if ([descriptor conformsToProtocol:@protocol(PTNAlbumDescriptor)]) {
    return self.albumCellSize;
  }
  return self.assetCellSize;
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout __unused *)collectionViewLayout
    referenceSizeForHeaderInSection:(NSInteger)section {
  if ([self numberOfActiveSectionsInCollectionView:collectionView startingAt:0] < 2 ||
      ![collectionView numberOfItemsInSection:section] ||
      ![self.dataSource titleForSection:section]) {
    return CGSizeZero;
  }

  return self.headerCellSize;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView
                        layout:(UICollectionViewLayout __unused *)collectionViewLayout
        insetForSectionAtIndex:(NSInteger)section {
  if (![self.collectionView numberOfItemsInSection:section] ||
      self.collectionView.numberOfSections <= section ||
      [self numberOfActiveSectionsInCollectionView:collectionView startingAt:section] == 1) {
    return UIEdgeInsetsZero;
  }

  return UIEdgeInsetsMake(0, 0, self.configuration.minimumLineSpacing, 0);
}

- (NSInteger)numberOfActiveSectionsInCollectionView:(UICollectionView *)collectionView
                                         startingAt:(NSInteger)section {
  NSInteger numberOfActiveSections = 0;
  for (NSInteger i = section; i < collectionView.numberOfSections; ++i) {
    numberOfActiveSections += [collectionView numberOfItemsInSection:i] ? 1 : 0;
  }
  return numberOfActiveSections;
}

@end

NS_ASSUME_NONNULL_END
