// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Reuven Siman Tov.

#import "PTUAlbumViewController.h"

#import "PTUAlbumViewModel.h"
#import "PTUCollectionView.h"
#import "PTUCollectionViewConfiguration.h"
#import "PTUCollectionViewController.h"
#import "PTUErrorViewProvider.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTUAlbumViewController ()

/// Underlying collection view controller used to display images.
@property (strong, nonatomic, nullable) PTUCollectionViewController *collectionViewController;

/// Configuration used to create instances of \c PTUCollectionViewController.
@property (readonly, nonatomic) PTUCollectionViewConfiguration *configuration;

@end

@implementation PTUAlbumViewController

- (instancetype)initWithViewModel:(id<PTUAlbumViewModel>)viewModel
                    configuration:(PTUCollectionViewConfiguration *)configuration {
  if (self = [super initWithNibName:nil bundle:nil]) {
    _viewModel = viewModel;
    _configuration = configuration;
    self.emptyView = [PTUCollectionView defaultEmptyView];
    self.errorView = [PTUCollectionView defaultErrorView];

    [self bindViewController];
  }
  return self;
}

+ (instancetype)photoStripWithViewModel:(id<PTUAlbumViewModel>)viewModel {
  return [[PTUAlbumViewController alloc] initWithViewModel:viewModel
      configuration:[PTUCollectionViewConfiguration photoStrip]];
}

+ (instancetype)albumWithViewModel:(id<PTUAlbumViewModel>)viewModel {
  return [[PTUAlbumViewController alloc] initWithViewModel:viewModel
      configuration:[PTUCollectionViewConfiguration deviceAdjustableConfiguration]];
}

- (void)bindViewController {
  @weakify(self);
  RAC(self, collectionViewController) = [[RACObserve(self, viewModel.dataSourceProvider)
      switchToLatest]
      map:^PTUCollectionViewController *(id<PTUDataSourceProvider> dataSourceProvider) {
        @strongify(self);
        auto controller =
            [[PTUCollectionViewController alloc] initWithDataSourceProvider:dataSourceProvider
                                                       initialConfiguration:self.configuration];
        controller.contentInset = self.contentInset;
        return controller;
      }];

  RACSignal *collectionViewControllerTitle = RACObserve(self, collectionViewController.title);
  RAC(self, localizedTitle, self.viewModel.defaultTitle) = collectionViewControllerTitle;
  RAC(self, title, self.viewModel.defaultTitle) = collectionViewControllerTitle;
}

- (void)viewDidLoad {
  [super viewDidLoad];

  [self bindViews];
}

- (void)bindViews {
  @weakify(self);
  [[RACObserve(self, collectionViewController)
      combinePreviousWithStart:nil reduce:^RACTuple *(PTUCollectionViewController *previous,
                                                      PTUCollectionViewController *current) {
        return RACTuplePack(previous, current);
      }]
      subscribeNext:^(RACTuple *controllers) {
        @strongify(self);
        RACTupleUnpack(PTUCollectionViewController *previous,
                       PTUCollectionViewController *current) = controllers;
        [previous.view removeFromSuperview];

        if (!current) {
          return;
        }

        current.backgroundView = self.backgroundView;
        current.emptyView = self.emptyView;
        current.errorView = self.errorView;
        current.errorViewProvider = self.errorViewProvider;
        [self addChildViewController:current];
        [self.view addSubview:current.view];
        [current didMoveToParentViewController:self];
        [current.view mas_makeConstraints:^(MASConstraintMaker *make) {
          make.edges.equalTo(self.view);
        }];
      }];

  self.viewModel.assetSelected = [RACObserve(self, collectionViewController.itemSelected)
      switchToLatest];

  self.viewModel.assetDeselected = [RACObserve(self, collectionViewController.itemDeselected)
      switchToLatest];

  RACSignal *selectedAssets = [RACObserve(self, viewModel.selectedAssets) switchToLatest];
  [[[[RACObserve(self, collectionViewController)
      map:^RACSignal *(PTUCollectionViewController *viewController) {
        // Start new previous retention for each collectionViewController, as its replacement
        // already deselects all assets. Previous selected assets are used to deselect the
        // previously selected assets, prior to selecting the new - avoiding aggregation of
        // selection.
        RACSignal *selectedAssetsWithPrevious = [selectedAssets
            combinePreviousWithStart:@[]
            reduce:^RACTuple *(NSArray<id<PTNDescriptor>> *previous,
                               NSArray<id<PTNDescriptor>> *current) {
              return RACTuplePack(previous, current);
            }];

        return [RACSignal combineLatest:@[
          [RACSignal return:viewController],
          selectedAssetsWithPrevious
        ]];
      }]
      switchToLatest]
      takeUntil:[self rac_willDeallocSignal]]
      subscribeNext:^(RACTuple *controllerAndSelectedAssets) {
        RACTupleUnpack(PTUCollectionViewController *collectionViewController,
                       RACTuple *selectedAssets) = controllerAndSelectedAssets;
        RACTupleUnpack(NSArray<id<PTNDescriptor>> *previousSelectedAssets,
                       NSArray<id<PTNDescriptor>> *currentSelectedAssets) = selectedAssets;

        for (id<PTNDescriptor> asset in previousSelectedAssets) {
          [collectionViewController deselectItem:asset];
        }

        for (id<PTNDescriptor> asset in currentSelectedAssets) {
          [collectionViewController selectItem:asset];
        }
      }];

  RACSignal *scrollToAsset = [[RACObserve(self, viewModel.scrollToAsset)
      switchToLatest]
      replayLast];
  [[[[RACObserve(self, collectionViewController)
      map:^RACSignal *(PTUCollectionViewConfiguration *viewController) {
        return [RACSignal combineLatest:@[[RACSignal return:viewController], scrollToAsset]];
      }]
      switchToLatest]
      takeUntil:[self rac_willDeallocSignal]]
      subscribeNext:^(RACTuple *controllerAndScrollInstruction) {
        RACTupleUnpack(PTUCollectionViewController *collectionViewController,
                       RACTuple *scrollInstruction) = controllerAndScrollInstruction;
        RACTupleUnpack(id<PTNDescriptor> asset, NSNumber *position) = scrollInstruction;
        PTUCollectionViewScrollPosition scrollPosition =
            (PTUCollectionViewScrollPosition)position.unsignedIntegerValue;
        [collectionViewController scrollToItem:asset atScrollPosition:scrollPosition animated:NO];
      }];
}

- (void)setBackgroundView:(nullable UIView *)backgroundView {
  _backgroundView = backgroundView;
  self.collectionViewController.backgroundView = backgroundView;
}

- (void)setEmptyView:(UIView *)emptyView {
  _emptyView = emptyView;
  self.collectionViewController.emptyView = emptyView;
}

- (void)setErrorView:(UIView *)errorView {
  _errorView = errorView;
  self.collectionViewController.errorView = errorView;
}

- (void)setErrorViewProvider:(nullable id<PTUErrorViewProvider>)errorViewProvider {
  _errorViewProvider = errorViewProvider;
  self.collectionViewController.errorViewProvider = errorViewProvider;
}

- (void)setConfiguration:(PTUCollectionViewConfiguration *)configuration animated:(BOOL)animated {
  if (self.configuration == configuration) {
    return;
  }
  _configuration = configuration;
  [self.collectionViewController setConfiguration:configuration animated:animated];
}

- (void)setContentInset:(UIEdgeInsets)contentInset {
  _contentInset = contentInset;
  self.collectionViewController.contentInset = contentInset;
}

- (void)reloadData {
  [self.collectionViewController reloadData];
}

- (nullable UICollectionViewCell<PTUImageCell> *)cellAtPoint:(CGPoint)point {
  return [self.collectionViewController cellAtPoint:point];
}

@end

NS_ASSUME_NONNULL_END
