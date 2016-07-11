// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTUCollectionViewController.h"

#import "PTUCellSizingStrategy.h"
#import "PTUCollectionViewConfiguration.h"
#import "PTUDataSource.h"
#import "PTUDataSourceProvider.h"
#import "PTUFakeDataSource.h"
#import "UIView+Retrieval.h"

#import "PTNTestUtils.h"

static void PTUSimulateSelection(UICollectionView *collectionView, NSIndexPath *indexPath) {
  id<UICollectionViewDelegate> delegate = collectionView.delegate;

  if ([delegate respondsToSelector:@selector(collectionView:shouldSelectItemAtIndexPath:)]) {
    if (![collectionView.delegate collectionView:collectionView
                     shouldSelectItemAtIndexPath:indexPath]) {
      return;
    }
  }

  [collectionView selectItemAtIndexPath:indexPath animated:NO
                         scrollPosition:UITableViewScrollPositionNone];
  
  if ([delegate respondsToSelector:@selector(collectionView:didSelectItemAtIndexPath:)]) {
    [collectionView.delegate collectionView:collectionView didSelectItemAtIndexPath:indexPath];
  }
}

static void PTUSimulateDeselection(UICollectionView *collectionView, NSIndexPath *indexPath) {
  id<UICollectionViewDelegate> delegate = collectionView.delegate;

  if ([delegate respondsToSelector:@selector(collectionView:shouldDeselectItemAtIndexPath:)]) {
    if (![collectionView.delegate collectionView:collectionView
                   shouldDeselectItemAtIndexPath:indexPath]) {
      return;
    }
  }
  
  [collectionView deselectItemAtIndexPath:indexPath animated:NO];

  if ([delegate respondsToSelector:@selector(collectionView:didDeselectItemAtIndexPath:)]) {
    [collectionView.delegate collectionView:collectionView didDeselectItemAtIndexPath:indexPath];
  }
}

SpecBegin(PTUCollectionViewController)

__block PTUFakeDataSource *dataSource;
__block id<PTUDataSourceProvider> dataSourceProvider;
__block PTUCollectionViewConfiguration *configuration;

__block PTUCollectionViewController *viewController;

__block id<PTNAssetDescriptor> asset;

beforeEach(^{
  dataSource = [[PTUFakeDataSource alloc] init];
  dataSourceProvider = OCMProtocolMock(@protocol(PTUDataSourceProvider));
  configuration = [PTUCollectionViewConfiguration defaultConfiguration];
  OCMStub([dataSourceProvider dataSourceForCollectionView:OCMOCK_ANY]).andReturn(dataSource);
  viewController =
      [[PTUCollectionViewController alloc] initWithDataSourceProvider:dataSourceProvider
                                                 initialConfiguration:configuration];
  asset = PTNCreateAssetDescriptor(nil, @"foo", 0, nil, nil, 0);
});

context(@"initialization", ^{
  it(@"should request data source on initialization", ^{
    OCMVerify([dataSourceProvider dataSourceForCollectionView:OCMOCK_ANY]);
  });

  it(@"should add subviews on initialization", ^{
    expect([viewController.view wf_viewForAccessibilityIdentifier:@"CollectionView"]).toNot.beNil();
    expect([viewController.view wf_viewForAccessibilityIdentifier:@"Empty"]).toNot.beNil();
    expect([viewController.view wf_viewForAccessibilityIdentifier:@"Error"]).toNot.beNil();
  });

  it(@"should correctly initialize with manager and URL", ^{
    id<PTNAssetManager> manager = OCMProtocolMock(@protocol(PTNAssetManager));
    NSURL *url = [NSURL URLWithString:@"http://www.foo.com"];

    expect([[PTUCollectionViewController alloc] initWithAssetManager:manager
                                                            albumURL:url]).toNot.beNil();
  });
});

it(@"should keep localizedTitle and title up to date with data source", ^{
  expect(viewController.title).to.beNil();
  expect(viewController.localizedTitle).to.beNil();
  
  dataSource.title = @"foo";
  expect(viewController.title).to.equal(@"foo");
  expect(viewController.localizedTitle).to.equal(@"foo");
});

it(@"should keep localizedTitle and title up to date with new data sources", ^{
  PTUFakeDataSource *otherDataSource = [[PTUFakeDataSource alloc] init];
  dataSourceProvider = OCMProtocolMock(@protocol(PTUDataSourceProvider));
  configuration = [PTUCollectionViewConfiguration defaultConfiguration];
  OCMExpect([dataSourceProvider dataSourceForCollectionView:OCMOCK_ANY]).andReturn(dataSource);
  OCMExpect([dataSourceProvider dataSourceForCollectionView:OCMOCK_ANY]).andReturn(otherDataSource);

  viewController =
      [[PTUCollectionViewController alloc] initWithDataSourceProvider:dataSourceProvider
                                                 initialConfiguration:configuration];
  
  expect(viewController.title).to.beNil();
  expect(viewController.localizedTitle).to.beNil();
  
  dataSource.title = @"foo";
  expect(viewController.title).to.equal(@"foo");
  expect(viewController.localizedTitle).to.equal(@"foo");
  
  [viewController reloadData];
  
  expect(viewController.title).to.beNil();
  expect(viewController.localizedTitle).to.beNil();
  
  dataSource.title = @"bar";
  otherDataSource.title = @"baz";

  expect(viewController.title).to.equal(@"baz");
  expect(viewController.localizedTitle).to.equal(@"baz");
});

context(@"collection view", ^{
  __block UICollectionView * _Nullable collectionView;

  beforeEach(^{
    collectionView = (UICollectionView *)
        [viewController.view wf_viewForAccessibilityIdentifier:@"CollectionView"];
    expect(collectionView).toNot.beNil();
    dataSource.collectionView = collectionView;

    viewController.view.frame = CGRectMake(0, 0, 200, 300);
    [viewController.view layoutIfNeeded];
  });

  it(@"should size asset cells according to strategy", ^{
    dataSource.data = @[@[asset]];
    [collectionView reloadData];
    [collectionView layoutIfNeeded];

    expect(collectionView.numberOfSections).to.equal(1);
    expect([collectionView numberOfItemsInSection:0]).to.equal(1);
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:0];
    expect([collectionView cellForItemAtIndexPath:indexPath].frame.size)
        .to.equal(CGSizeMake(100, 100));
  });

  it(@"should size album cells according to strategy", ^{
    dataSource.data = @[@[OCMProtocolMock(@protocol(PTNAlbumDescriptor))]];
    [collectionView reloadData];
    [collectionView layoutIfNeeded];

    expect(collectionView.numberOfSections).to.equal(1);
    expect([collectionView numberOfItemsInSection:0]).to.equal(1);
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:0];
    expect([collectionView cellForItemAtIndexPath:indexPath].frame.size)
        .to.equal(CGSizeMake(200, 100));
  });

  it(@"should resize cells on size change", ^{
    dataSource.data = @[
      @[asset],
      @[OCMProtocolMock(@protocol(PTNAlbumDescriptor))]
    ];
    [collectionView reloadData];
    [collectionView layoutIfNeeded];

    expect(collectionView.numberOfSections).to.equal(2);
    expect([collectionView numberOfItemsInSection:0]).to.equal(1);
    expect([collectionView numberOfItemsInSection:1]).to.equal(1);

    NSIndexPath *assetIndexPath = [NSIndexPath indexPathForItem:0 inSection:0];
    NSIndexPath *albumIndexPath = [NSIndexPath indexPathForItem:0 inSection:1];
    expect([collectionView cellForItemAtIndexPath:assetIndexPath].frame.size)
        .to.equal(CGSizeMake(100, 100));
    expect([collectionView cellForItemAtIndexPath:albumIndexPath].frame.size)
        .to.equal(CGSizeMake(200, 100));

    viewController.view.frame = CGRectMake(0, 0, 332, 200);
    [viewController.view layoutIfNeeded];
    expect([collectionView cellForItemAtIndexPath:assetIndexPath].frame.size)
        .to.beCloseToPointWithin(CGSizeMake(110, 110), FLT_EPSILON);
    expect([collectionView cellForItemAtIndexPath:albumIndexPath].frame.size)
        .to.equal(CGSizeMake(332, 100));
  });

  context(@"selection", ^{
    it(@"should correctly select items", ^{
      dataSource.data = @[@[asset]];
      [collectionView reloadData];
      [collectionView layoutIfNeeded];
      
      NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:0];
      expect([collectionView cellForItemAtIndexPath:indexPath].isSelected).to.beFalsy();
      [viewController selectItem:asset];
      expect([collectionView cellForItemAtIndexPath:indexPath].isSelected).to.beTruthy();
    });
    
    it(@"should send values correctly when selecting items", ^{
      id<PTNDescriptor> otherAsset = PTNCreateAssetDescriptor(nil, @"foo", 0, nil, nil, 0);
      dataSource.data = @[@[asset, otherAsset]];
      [collectionView reloadData];
      [collectionView layoutIfNeeded];

      LLSignalTestRecorder *values = [[viewController itemSelected] testRecorder];

      PTUSimulateSelection(collectionView, [NSIndexPath indexPathForItem:0 inSection:0]);
      PTUSimulateSelection(collectionView, [NSIndexPath indexPathForItem:1 inSection:0]);
      PTUSimulateSelection(collectionView, [NSIndexPath indexPathForItem:0 inSection:0]);

      expect(values).to.sendValues(@[asset, otherAsset, asset]);
    });

    it(@"should send values correctly when deselecting items", ^{
      id<PTNDescriptor> otherAsset = PTNCreateAssetDescriptor(nil, @"foo", 0, nil, nil, 0);
      dataSource.data = @[@[asset, otherAsset]];
      [collectionView reloadData];
      [collectionView layoutIfNeeded];

      LLSignalTestRecorder *values = [[viewController itemDeselected] testRecorder];

      PTUSimulateDeselection(collectionView, [NSIndexPath indexPathForItem:0 inSection:0]);
      PTUSimulateDeselection(collectionView, [NSIndexPath indexPathForItem:1 inSection:0]);
      PTUSimulateDeselection(collectionView, [NSIndexPath indexPathForItem:0 inSection:0]);

      expect(values).to.sendValues(@[asset, otherAsset, asset]);
    });
    
    it(@"should correctly send all selected items", ^{
      id<PTNDescriptor> otherAsset = PTNCreateAssetDescriptor(nil, @"foo", 0, nil, nil, 0);
      dataSource.data = @[@[asset, otherAsset]];
      [collectionView reloadData];
      [collectionView layoutIfNeeded];
      
      viewController.allowsMultipleSelection = YES;
      
      LLSignalTestRecorder *values = [[viewController selectedItems] testRecorder];
      
      PTUSimulateSelection(collectionView, [NSIndexPath indexPathForItem:0 inSection:0]);
      PTUSimulateSelection(collectionView, [NSIndexPath indexPathForItem:1 inSection:0]);
      PTUSimulateDeselection(collectionView, [NSIndexPath indexPathForItem:0 inSection:0]);
      PTUSimulateDeselection(collectionView, [NSIndexPath indexPathForItem:1 inSection:0]);
      
      expect(values).to.sendValues(@[@[asset], @[asset, otherAsset], @[otherAsset], @[]]);
    });

    it(@"should complete selection and deselection signals when deallocated", ^{
      LLSignalTestRecorder *selectedRecorder;
      LLSignalTestRecorder *deselectedRecorder;
      LLSignalTestRecorder *allSelectedRecorder;
      __weak PTUCollectionViewController *weakController;

      @autoreleasepool {
        PTUCollectionViewController *controller =
            [[PTUCollectionViewController alloc] initWithDataSourceProvider:dataSourceProvider
            initialConfiguration:[PTUCollectionViewConfiguration defaultConfiguration]];
        weakController = controller;

        selectedRecorder = [[controller itemSelected] testRecorder];
        deselectedRecorder = [[controller itemDeselected] testRecorder];
        allSelectedRecorder = [[controller selectedItems] testRecorder];
      }

      expect(weakController).to.beNil();
      expect(selectedRecorder).will.complete();
      expect(deselectedRecorder).will.complete();
      expect(allSelectedRecorder).will.complete();
    });
  });

  context(@"scrolling", ^{
    beforeEach(^{
      id<PTNDescriptor> otherAsset = PTNCreateAssetDescriptor(nil, @"bar", 0, nil, nil, 0);
      dataSource.data = @[@[
        otherAsset,
        otherAsset,
        otherAsset,
        asset,
        otherAsset,
        otherAsset,
        otherAsset
      ]];

      [collectionView reloadData];
      [collectionView layoutIfNeeded];
    });

    context(@"vertical", ^{
      beforeEach(^{
        viewController.view.frame = CGRectMake(0, 0, 100, 302);
        [viewController.view layoutIfNeeded];
      });

      it(@"should correctly scroll to top", ^{
        collectionView.contentOffset = CGPointMake(0, 200);
        expect(collectionView.contentOffset).to.equal(CGPointMake(0, 200));
        [viewController scrollToTopAnimated:NO];
        expect(collectionView.contentOffset).to.equal(CGPointMake(0, 0));
      });

      it(@"should correctly scroll at top position", ^{
        expect(collectionView.contentOffset).to.equal(CGPointMake(0, 0));
        [viewController scrollToItem:asset
                    atScrollPosition:PTUCollectionViewScrollPositionTopLeft animated:NO];
        expect(collectionView.contentOffset).to.equal(CGPointMake(0, 303));
      });

      it(@"should correctly scroll at center position", ^{
        expect(collectionView.contentOffset).to.equal(CGPointMake(0, 0));
        [viewController scrollToItem:asset atScrollPosition:PTUCollectionViewScrollPositionCenter
                            animated:NO];
        expect(collectionView.contentOffset).to.equal(CGPointMake(0, 202));
      });

      it(@"should correctly scroll at bottom position", ^{
        expect(collectionView.contentOffset).to.equal(CGPointMake(0, 0));
        [viewController scrollToItem:asset
                    atScrollPosition:PTUCollectionViewScrollPositionBottomRight animated:NO];
        expect(collectionView.contentOffset).to.equal(CGPointMake(0, 101));
      });
    });

    context(@"horizontal", ^{
      beforeEach(^{
        id<PTUCellSizingStrategy> assetSizingStrategy =
            [PTUCellSizingStrategy adaptiveFitColumn:CGSizeMake(100, 100) maximumScale:1.2];
        id<PTUCellSizingStrategy> albumSizingStrategy = [PTUCellSizingStrategy rowWithHeight:100];
        PTUCollectionViewConfiguration *configuration =
            [[PTUCollectionViewConfiguration alloc]
            initWithAssetCellSizingStrategy:assetSizingStrategy
            albumCellSizingStrategy:albumSizingStrategy minimumItemSpacing:1 minimumLineSpacing:1
            scrollDirection:UICollectionViewScrollDirectionHorizontal
            showVerticalScrollIndicator:YES showHorizontalScrollIndicator:NO enablePaging:NO];

        [viewController setConfiguration:configuration animated:NO];
        viewController.view.frame = CGRectMake(0, 0, 302, 100);
        [viewController.view layoutIfNeeded];
      });

      it(@"should correctly scroll to top", ^{
        collectionView.contentOffset = CGPointMake(200, 0);
        expect(collectionView.contentOffset).to.equal(CGPointMake(200, 0));
        [viewController scrollToTopAnimated:NO];
        expect(collectionView.contentOffset).to.equal(CGPointMake(0, 0));
      });

      it(@"should correctly scroll at left position", ^{
        expect(collectionView.contentOffset).to.equal(CGPointMake(0, 0));
        [viewController scrollToItem:asset atScrollPosition:PTUCollectionViewScrollPositionTopLeft
                            animated:NO];
        expect(collectionView.contentOffset).to.equal(CGPointMake(303, 0));
      });

      it(@"should correctly scroll at center position", ^{
        expect(collectionView.contentOffset).to.equal(CGPointMake(0, 0));
        [viewController scrollToItem:asset atScrollPosition:PTUCollectionViewScrollPositionCenter
                            animated:NO];
        expect(collectionView.contentOffset).to.equal(CGPointMake(202, 0));
      });

      it(@"should correctly scroll at right position", ^{
        expect(collectionView.contentOffset).to.equal(CGPointMake(0, 0));
        [viewController scrollToItem:asset
                    atScrollPosition:PTUCollectionViewScrollPositionBottomRight animated:NO];
        expect(collectionView.contentOffset).to.equal(CGPointMake(101, 0));
      });
    });
  });

  it(@"should fetch a new data source on reload", ^{
    PTUDataSourceProvider *provider = OCMProtocolMock(@protocol(PTUDataSourceProvider));
    OCMExpect([provider dataSourceForCollectionView:OCMOCK_ANY]).andReturn(dataSource);
    OCMExpect([provider dataSourceForCollectionView:OCMOCK_ANY]).andReturn(dataSource);
    OCMExpect([provider dataSourceForCollectionView:OCMOCK_ANY]).andReturn(dataSource);

    PTUCollectionViewController *controller =
        [[PTUCollectionViewController alloc] initWithDataSourceProvider:provider
        initialConfiguration:[PTUCollectionViewConfiguration defaultConfiguration]];

    [controller reloadData];
    [controller reloadData];

    OCMVerify(provider);
  });

  it(@"should allow multiple selection", ^{
    viewController.allowsMultipleSelection = YES;
    expect(collectionView.allowsMultipleSelection).to.beTruthy();
  });

  it(@"should correctly set background color", ^{
    viewController.backgroundColor = [UIColor redColor];
    expect(collectionView.backgroundColor).to.equal([UIColor redColor]);
  });

  it(@"should correctly get background color", ^{
    collectionView.backgroundColor = [UIColor redColor];
    expect(viewController.backgroundColor).to.equal([UIColor redColor]);
  });

  it(@"should correctly set background view", ^{
    UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
    viewController.backgroundView = view;
    expect(collectionView.backgroundView).to.equal(view);
  });

  it(@"should correctly get background view", ^{
    UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
    collectionView.backgroundView = view;
    expect(viewController.backgroundView).to.equal(view);
  });
});

context(@"empty view", ^{
  __block UIView *emptyView;

  beforeEach(^{
    emptyView = [viewController.view wf_viewForAccessibilityIdentifier:@"Empty"];
  });

  it(@"should hide the view when the collection isn't empty", ^{
    dataSource.data = @[@[asset]];
    expect(emptyView.isHidden || emptyView.alpha == 0).to.beTruthy();
  });

  it(@"should hide the view when the collection is empty but had errored", ^{
    dataSource.error = [NSError lt_errorWithCode:1337];
    expect(emptyView.isHidden || emptyView.alpha == 0).to.beTruthy();
  });

  it(@"should show the view when the collection is empty and data source did not err", ^{
    expect(!emptyView.isHidden || emptyView.alpha == 1).to.beTruthy();
    
    dataSource.data = @[@[], @[]];
    expect(!emptyView.isHidden || emptyView.alpha == 1).to.beTruthy();
  });
  
  it(@"should bind new empty views and set them according to the current value", ^{
    UIView *newEmptyView = [[UIView alloc] init];
    
    viewController.emptyView = newEmptyView;
    expect(!newEmptyView.isHidden || newEmptyView.alpha == 1).to.beTruthy();
    
    dataSource.data = @[@[asset]];
    expect(newEmptyView.isHidden || newEmptyView.alpha == 0).to.beTruthy();
    
    UIView *newerEmptyView = [[UIView alloc] init];
    viewController.emptyView = newerEmptyView;
    expect(newerEmptyView.isHidden || newerEmptyView.alpha == 0).to.beTruthy();
    
    dataSource.data = @[@[]];
    expect(!newerEmptyView.isHidden || newerEmptyView.alpha == 1).to.beTruthy();
  });
});

context(@"error view", ^{
  __block UIView *errorView;

  beforeEach(^{
    errorView = [viewController.view wf_viewForAccessibilityIdentifier:@"Error"];
  });
  
  it(@"should hide the view when the data source did no err", ^{
    expect(errorView.isHidden || errorView.alpha == 0).to.beTruthy();
  });
  
  it(@"should show the view when the data source did err", ^{
    dataSource.error = [NSError lt_errorWithCode:1337];
    expect(!errorView.isHidden || errorView.alpha == 1).to.beTruthy();
  });
  
  it(@"should bind new error views and set them according to the current value", ^{
    UIView *newErrorView = [[UIView alloc] init];
    
    viewController.emptyView = newErrorView;
    expect(!newErrorView.isHidden || newErrorView.alpha == 1).to.beTruthy();
    
    dataSource.error = [NSError lt_errorWithCode:1337];
    expect(newErrorView.isHidden || newErrorView.alpha == 0).to.beTruthy();
    
    UIView *newerErrorView = [[UIView alloc] init];
    viewController.emptyView = newerErrorView;
    expect(newerErrorView.isHidden || newerErrorView.alpha == 0).to.beTruthy();
    
    dataSource.error = nil;
    expect(!newerErrorView.isHidden || newerErrorView.alpha == 1).to.beTruthy();
  });
});

SpecEnd
