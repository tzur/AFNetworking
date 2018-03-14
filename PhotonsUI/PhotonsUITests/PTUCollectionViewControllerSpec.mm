// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTUCollectionViewController.h"

#import <Photons/NSError+Photons.h>
#import <Photons/PTNAssetManager.h>

#import "PTNTestUtils.h"
#import "PTUCellSizingStrategy.h"
#import "PTUCollectionViewConfiguration.h"
#import "PTUDataSource.h"
#import "PTUDataSourceProvider.h"
#import "PTUErrorViewProvider.h"
#import "PTUFakeDataSource.h"
#import "UIView+Retrieval.h"

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
__block id<PTUCellSizingStrategy> assetCellSizingStrategy;
__block id<PTUCellSizingStrategy> albumCellSizingStrategy;
__block id<PTUCellSizingStrategy> headerCellSizingStrategy;

__block PTUCollectionViewController *viewController;

__block id<PTNAssetDescriptor> asset;

beforeEach(^{
  dataSource = [[PTUFakeDataSource alloc] init];
  dataSourceProvider = OCMProtocolMock(@protocol(PTUDataSourceProvider));
  assetCellSizingStrategy = [PTUCellSizingStrategy constant:CGSizeMake(100, 100)];
  albumCellSizingStrategy = [PTUCellSizingStrategy rowWithHeight:100];
  headerCellSizingStrategy = [PTUCellSizingStrategy rowWithHeight:25];
  configuration = [[PTUCollectionViewConfiguration alloc]
      initWithAssetCellSizingStrategy:assetCellSizingStrategy
      albumCellSizingStrategy:albumCellSizingStrategy
      headerCellSizingStrategy:headerCellSizingStrategy minimumItemSpacing:0
      minimumLineSpacing:0 scrollDirection:UICollectionViewScrollDirectionVertical
      showVerticalScrollIndicator:NO showHorizontalScrollIndicator:NO enablePaging:NO
      keyboardDismissMode:UIScrollViewKeyboardDismissModeOnDrag];
  OCMStub([dataSourceProvider dataSourceForCollectionView:OCMOCK_ANY]).andReturn(dataSource);
  viewController =
      [[PTUCollectionViewController alloc] initWithDataSourceProvider:dataSourceProvider
                                                 initialConfiguration:configuration];
  asset = PTNCreateAssetDescriptor(@"foo");
  [viewController.view layoutIfNeeded];
});

context(@"initialization", ^{
  it(@"should request data source on initialization", ^{
    OCMVerify([dataSourceProvider dataSourceForCollectionView:OCMOCK_ANY]);
  });

  it(@"should add subviews on initialization", ^{
    expect([viewController.view wf_viewForAccessibilityIdentifier:@"CollectionView"]).toNot.beNil();
    expect([viewController.view wf_viewForAccessibilityIdentifier:@"Empty"]).toNot.beNil();
  });

  it(@"should correctly initialize with manager and URL", ^{
    id<PTNAssetManager> manager = OCMProtocolMock(@protocol(PTNAssetManager));
    NSURL *url = [NSURL URLWithString:@"http://www.foo.com"];

    expect([[PTUCollectionViewController alloc] initWithAssetManager:manager
                                                            albumURL:url]).toNot.beNil();
  });

  it(@"should not setup the collection view before the view was layed out", ^{
    PTUCollectionViewController *controller =
    [[PTUCollectionViewController alloc] initWithDataSourceProvider:dataSourceProvider
                                               initialConfiguration:configuration];
    expect([controller.view wf_viewForAccessibilityIdentifier:@"CollectionView"]).to.beNil();

    [controller.view layoutIfNeeded];
    expect([controller.view wf_viewForAccessibilityIdentifier:@"CollectionView"]).toNot.beNil();
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
  [viewController.view layoutIfNeeded];

  expect(viewController.title).to.beNil();
  expect(viewController.localizedTitle).to.beNil();

  dataSource.title = @"foo";
  expect(viewController.title).will.equal(@"foo");
  expect(viewController.localizedTitle).will.equal(@"foo");

  [viewController reloadData];

  expect(viewController.title).will.beNil();
  expect(viewController.localizedTitle).will.beNil();

  dataSource.title = @"bar";
  otherDataSource.title = @"baz";

  expect(viewController.title).will.equal(@"baz");
  expect(viewController.localizedTitle).will.equal(@"baz");
});

context(@"collection view", ^{
  __block UICollectionView * _Nullable collectionView;
  __block UIView *collectionViewContainer;

  beforeEach(^{
    collectionView = (UICollectionView *)
        [viewController.view wf_viewForAccessibilityIdentifier:@"CollectionView"];
    expect(collectionView).toNot.beNil();
    collectionViewContainer =
        [viewController.view wf_viewForAccessibilityIdentifier:@"CollectionViewContainer"];
    dataSource.collectionView = collectionView;

    viewController.view.frame = CGRectMake(0, 0, 200, 300);
    [viewController.view layoutIfNeeded];
  });

  it(@"should correctly apply initial configuration", ^{
    UICollectionViewFlowLayout *layout =
        (UICollectionViewFlowLayout *)collectionView.collectionViewLayout;

    expect(layout.scrollDirection).to.equal(UICollectionViewScrollDirectionVertical);
    expect(layout.minimumInteritemSpacing).to.equal(@0);
    expect(layout.minimumLineSpacing).to.equal(@0);

    expect(collectionView.showsHorizontalScrollIndicator).to.beFalsy();
    expect(collectionView.showsVerticalScrollIndicator).to.beFalsy();
    expect(collectionView.pagingEnabled).to.beFalsy();
    expect(collectionView.keyboardDismissMode).to.equal(UIScrollViewKeyboardDismissModeOnDrag);
  });

  it(@"should correctly apply new configuration", ^{
    PTUCollectionViewConfiguration *configuration =
        [[PTUCollectionViewConfiguration alloc]
        initWithAssetCellSizingStrategy:OCMProtocolMock(@protocol(PTUCellSizingStrategy))
        albumCellSizingStrategy:OCMProtocolMock(@protocol(PTUCellSizingStrategy))
        headerCellSizingStrategy:OCMProtocolMock(@protocol(PTUCellSizingStrategy))
        minimumItemSpacing:3 minimumLineSpacing:4
        scrollDirection:UICollectionViewScrollDirectionHorizontal
        showVerticalScrollIndicator:NO showHorizontalScrollIndicator:YES enablePaging:YES
        keyboardDismissMode:UIScrollViewKeyboardDismissModeInteractive];

    [viewController setConfiguration:configuration animated:NO];

    UICollectionViewFlowLayout *layout =
        (UICollectionViewFlowLayout *)collectionView.collectionViewLayout;

    expect(layout.scrollDirection).to.equal(UICollectionViewScrollDirectionHorizontal);
    expect(layout.minimumInteritemSpacing).to.equal(@3);
    expect(layout.minimumLineSpacing).to.equal(@4);

    expect(collectionView.showsHorizontalScrollIndicator).to.beTruthy();
    expect(collectionView.showsVerticalScrollIndicator).to.beFalsy();
    expect(collectionView.pagingEnabled).to.beTruthy();
    expect(collectionView.keyboardDismissMode).to.equal(UIScrollViewKeyboardDismissModeInteractive);
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

  context(@"size with contentInset", ^{
    __block id<PTUCellSizingStrategy> assetCellSizingStrategy;
    __block id<PTUCellSizingStrategy> albumCellSizingStrategy;
    __block id<PTUCellSizingStrategy> headerCellSizingStrategy;

    beforeEach(^{
      assetCellSizingStrategy = OCMProtocolMock(@protocol(PTUCellSizingStrategy));
      albumCellSizingStrategy = OCMProtocolMock(@protocol(PTUCellSizingStrategy));
      headerCellSizingStrategy = OCMProtocolMock(@protocol(PTUCellSizingStrategy));

      configuration = [[PTUCollectionViewConfiguration alloc]
        initWithAssetCellSizingStrategy:assetCellSizingStrategy
        albumCellSizingStrategy:albumCellSizingStrategy
        headerCellSizingStrategy:headerCellSizingStrategy minimumItemSpacing:3
        minimumLineSpacing:7 scrollDirection:UICollectionViewScrollDirectionVertical
        showVerticalScrollIndicator:NO showHorizontalScrollIndicator:NO enablePaging:NO
        keyboardDismissMode:UIScrollViewKeyboardDismissModeOnDrag];
      viewController =
          [[PTUCollectionViewController alloc] initWithDataSourceProvider:dataSourceProvider
                                                     initialConfiguration:configuration];
      viewController.view.frame = CGRectMake(0, 0, 200, 300);
      viewController.contentInset = UIEdgeInsetsMake(20, 10, 20, 10);
      [viewController.view layoutIfNeeded];
    });

    it(@"should consider contentInset and scroll direction when sizing cells", ^{
      OCMVerify([assetCellSizingStrategy cellSizeForViewSize:CGSizeMake(180, 300) itemSpacing:3
                                                 lineSpacing:7]);
      OCMVerify([albumCellSizingStrategy cellSizeForViewSize:CGSizeMake(180, 300) itemSpacing:3
                                                 lineSpacing:7]);
      OCMVerify([headerCellSizingStrategy cellSizeForViewSize:CGSizeMake(180, 300) itemSpacing:3
                                                 lineSpacing:7]);
    });

    it(@"should consider new configuration when configuration is set", ^{
      configuration = [[PTUCollectionViewConfiguration alloc]
          initWithAssetCellSizingStrategy:assetCellSizingStrategy
          albumCellSizingStrategy:albumCellSizingStrategy
          headerCellSizingStrategy:headerCellSizingStrategy minimumItemSpacing:2
          minimumLineSpacing:4 scrollDirection:UICollectionViewScrollDirectionHorizontal
          showVerticalScrollIndicator:NO showHorizontalScrollIndicator:NO enablePaging:NO
          keyboardDismissMode:UIScrollViewKeyboardDismissModeOnDrag];
      [viewController setConfiguration:configuration animated:NO];
      [viewController.view layoutIfNeeded];

      OCMVerify([assetCellSizingStrategy cellSizeForViewSize:CGSizeMake(200, 260) itemSpacing:2
                                                 lineSpacing:4]);
      OCMVerify([albumCellSizingStrategy cellSizeForViewSize:CGSizeMake(200, 260) itemSpacing:2
                                                 lineSpacing:4]);
      OCMVerify([headerCellSizingStrategy cellSizeForViewSize:CGSizeMake(200, 260) itemSpacing:2
                                                  lineSpacing:4]);
    });

    it(@"should consider contentInset changes", ^{
      viewController.contentInset = UIEdgeInsetsMake(20, 30, 20, 20);
      [viewController.view layoutIfNeeded];

      OCMVerify([assetCellSizingStrategy cellSizeForViewSize:CGSizeMake(150, 300) itemSpacing:3
                                                 lineSpacing:7]);
      OCMVerify([albumCellSizingStrategy cellSizeForViewSize:CGSizeMake(150, 300) itemSpacing:3
                                                 lineSpacing:7]);
      OCMVerify([headerCellSizingStrategy cellSizeForViewSize:CGSizeMake(150, 300) itemSpacing:3
                                                  lineSpacing:7]);
    });
  });

  it(@"should size header cells according to strategy", ^{
    dataSource.data = @[@[asset], @[asset]];
    dataSource.sectionTitles = @{@0: @"", @1: @""};
    [collectionView reloadData];
    [collectionView layoutIfNeeded];

    expect(collectionView.numberOfSections).to.equal(2);
    expect([collectionView numberOfItemsInSection:0]).to.equal(1);
    expect([collectionView numberOfItemsInSection:1]).to.equal(1);
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:0];
    expect([collectionView
            layoutAttributesForSupplementaryElementOfKind:UICollectionElementKindSectionHeader
            atIndexPath:indexPath].frame.size).to.equal(CGSizeMake(200, 25));
  });

  it(@"should resize cells on size change", ^{
    dataSource.data = @[
      @[asset],
      @[OCMProtocolMock(@protocol(PTNAlbumDescriptor))]
    ];
    dataSource.sectionTitles = @{@0: @"", @1: @""};
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
    expect([collectionView
            layoutAttributesForSupplementaryElementOfKind:UICollectionElementKindSectionHeader
            atIndexPath:assetIndexPath].frame.size).to.equal(CGSizeMake(200, 25));

    viewController.view.frame = CGRectMake(0, 0, 314, 200);
    [viewController.view layoutIfNeeded];
    expect([collectionView cellForItemAtIndexPath:assetIndexPath].frame.size)
        .to.beCloseToPointWithin(CGSizeMake(100, 100), FLT_EPSILON);
    expect([collectionView cellForItemAtIndexPath:albumIndexPath].frame.size)
        .to.equal(CGSizeMake(314, 100));
    expect([collectionView
            layoutAttributesForSupplementaryElementOfKind:UICollectionElementKindSectionHeader
            atIndexPath:assetIndexPath].frame.size).to.equal(CGSizeMake(314, 25));
  });

  context(@"section headers", ^{
    beforeEach(^{
      dataSource.sectionTitles = @{@0: @"foo", @1: @"bar", @2: @"baz"};
    });

    it(@"should not show headers when there is no data", ^{
      dataSource.data = @[@[]];
      [collectionView reloadData];
      [collectionView layoutIfNeeded];

      NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:0];
      expect([collectionView numberOfSections]).to.equal(1);
      expect([collectionView supplementaryViewForElementKind:UICollectionElementKindSectionHeader
                                                 atIndexPath:indexPath]).to.beNil();
    });

    it(@"should not show headers when there is a single section", ^{
      dataSource.data = @[@[asset]];
      [collectionView reloadData];
      [collectionView layoutIfNeeded];

      NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:0];
      expect([collectionView supplementaryViewForElementKind:UICollectionElementKindSectionHeader
                                                 atIndexPath:indexPath]).to.beNil();
    });

    it(@"should not show headers when there is a single active section", ^{
      dataSource.data = @[@[asset], @[], @[]];
      [collectionView reloadData];
      [collectionView layoutIfNeeded];

      NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:0];
      expect([collectionView supplementaryViewForElementKind:UICollectionElementKindSectionHeader
                                                 atIndexPath:indexPath]).to.beNil();
    });

    it(@"should not show headers if they have no title", ^{
      dataSource.data = @[@[], @[asset], @[asset]];
      dataSource.sectionTitles = @{@1: @"foo"};
      [collectionView reloadData];
      [collectionView layoutIfNeeded];

      NSIndexPath *firstIndexPath = [NSIndexPath indexPathForItem:0 inSection:0];
      NSIndexPath *secondIndexPath = [NSIndexPath indexPathForItem:0 inSection:1];
      NSIndexPath *thirdIndexPath = [NSIndexPath indexPathForItem:0 inSection:2];
      expect([collectionView supplementaryViewForElementKind:UICollectionElementKindSectionHeader
                                                 atIndexPath:firstIndexPath]).to.beNil();
      expect([collectionView
              layoutAttributesForSupplementaryElementOfKind:UICollectionElementKindSectionHeader
              atIndexPath:secondIndexPath].frame.size).to.equal(CGSizeMake(200, 25));
      expect([collectionView
              layoutAttributesForSupplementaryElementOfKind:UICollectionElementKindSectionHeader
              atIndexPath:thirdIndexPath].frame.size).to.equal(CGSizeMake(0, 0));
    });

    it(@"should show headers only for active sections", ^{
      dataSource.data = @[@[], @[asset], @[asset]];
      [collectionView reloadData];
      [collectionView layoutIfNeeded];

      NSIndexPath *firstIndexPath = [NSIndexPath indexPathForItem:0 inSection:0];
      NSIndexPath *secondIndexPath = [NSIndexPath indexPathForItem:0 inSection:1];
      NSIndexPath *thirdIndexPath = [NSIndexPath indexPathForItem:0 inSection:2];
      expect([collectionView supplementaryViewForElementKind:UICollectionElementKindSectionHeader
                                                 atIndexPath:firstIndexPath]).to.beNil();
      expect([collectionView
              layoutAttributesForSupplementaryElementOfKind:UICollectionElementKindSectionHeader
              atIndexPath:secondIndexPath].frame.size).to.equal(CGSizeMake(200, 25));
      expect([collectionView
              layoutAttributesForSupplementaryElementOfKind:UICollectionElementKindSectionHeader
              atIndexPath:thirdIndexPath].frame.size).to.equal(CGSizeMake(200, 25));
    });
  });

  context(@"cell at location", ^{
    beforeEach(^{
      dataSource.data = @[
        @[OCMProtocolMock(@protocol(PTNAlbumDescriptor))],
        @[asset, asset, asset]
      ];
      dataSource.sectionTitles = @{@0: @"foo", @1: @"bar", @2: @"baz"};
      [collectionView reloadData];
      [collectionView layoutIfNeeded];
    });

    it(@"should return cell at location", ^{
      auto albumCell = [viewController cellAtPoint:CGPointMake(150, 75)];
      auto albumCellIndex = [NSIndexPath indexPathForItem:0 inSection:0];
      expect(albumCell).to.equal([collectionView cellForItemAtIndexPath:albumCellIndex]);

      auto imageCell = [viewController cellAtPoint:CGPointMake(150, 200)];
      auto imageCellIndex = [NSIndexPath indexPathForItem:1 inSection:1];
      expect(imageCell).to.equal([collectionView cellForItemAtIndexPath:imageCellIndex]);
    });

    it(@"should return nil for locations without visible cells", ^{
      expect([viewController cellAtPoint:CGPointMake(-20, 75)]).to.beNil();
      expect([viewController cellAtPoint:CGPointMake(100, 12)]).to.beNil();
      expect([viewController cellAtPoint:CGPointMake(150, 251)]).to.beNil();
    });

    it(@"should consider current scrolling", ^{
      collectionView.contentOffset = CGPointMake(0, 50);

      auto cell = [viewController cellAtPoint:CGPointMake(50, 200)];
      auto cellIndex = [NSIndexPath indexPathForItem:2 inSection:1];
      expect(cell).to.equal([collectionView cellForItemAtIndexPath:cellIndex]);
      expect([viewController cellAtPoint:CGPointMake(150, 201)]).to.beNil();
    });
  });

  context(@"selection", ^{
    it(@"should correctly select items", ^{
      dataSource.data = @[@[asset]];
      [collectionView reloadData];
      [dataSource.didUpdateCollectionView sendNext:[RACUnit defaultUnit]];
      [collectionView layoutIfNeeded];

      NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:0];
      expect([collectionView cellForItemAtIndexPath:indexPath].isSelected).to.beFalsy();
      [viewController selectItem:asset];
      expect([collectionView cellForItemAtIndexPath:indexPath].isSelected).to.beTruthy();
    });

    context(@"deferring", ^{
      __block id<PTNDescriptor> otherAsset;
      __block id<PTNDescriptor> anotherAsset;
      __block NSIndexPath *indexPath;
      __block NSIndexPath *otherIndexPath;

      beforeEach(^{
        otherAsset = PTNCreateAssetDescriptor(@"bar");
        anotherAsset = PTNCreateAssetDescriptor(@"baz");
        indexPath = [NSIndexPath indexPathForItem:0 inSection:0];
        otherIndexPath = [NSIndexPath indexPathForItem:1 inSection:0];
        dataSource.data = @[@[asset]];
        [dataSource.didUpdateCollectionView sendNext:[RACUnit defaultUnit]];
        [collectionView reloadData];
        [collectionView layoutIfNeeded];
      });

      it(@"should defer selection when collection doesn't contain item", ^{
        [viewController selectItem:otherAsset];

        expect([collectionView cellForItemAtIndexPath:indexPath].isSelected).to.beFalsy();

        dataSource.data = @[@[asset, otherAsset]];
        [collectionView reloadData];
        [collectionView layoutIfNeeded];
        [dataSource.didUpdateCollectionView sendNext:[RACUnit defaultUnit]];
        expect([collectionView cellForItemAtIndexPath:otherIndexPath].isSelected).to.beTruthy();
      });

      it(@"should defer only the latest selection", ^{
        [viewController selectItem:otherAsset];
        [viewController selectItem:anotherAsset];

        expect([collectionView cellForItemAtIndexPath:indexPath].isSelected).to.beFalsy();

        dataSource.data = @[@[otherAsset, asset]];
        [dataSource.didUpdateCollectionView sendNext:[RACUnit defaultUnit]];
        expect([collectionView cellForItemAtIndexPath:indexPath].isSelected).to.beFalsy();
        expect([collectionView cellForItemAtIndexPath:otherIndexPath].isSelected).to.beFalsy();

        dataSource.data = @[@[anotherAsset, otherAsset]];
        [dataSource.didUpdateCollectionView sendNext:[RACUnit defaultUnit]];
        expect([collectionView cellForItemAtIndexPath:indexPath].isSelected).to.beTruthy();
        expect([collectionView cellForItemAtIndexPath:otherIndexPath].isSelected).to.beFalsy();
      });

      it(@"should stop deferring when another asset was selected", ^{
        [viewController selectItem:otherAsset];
        [viewController selectItem:asset];

        expect([collectionView cellForItemAtIndexPath:indexPath].isSelected).to.beTruthy();

        dataSource.data = @[@[otherAsset, asset]];
        [collectionView reloadData];
        [collectionView layoutIfNeeded];
        [dataSource.didUpdateCollectionView sendNext:[RACUnit defaultUnit]];
        expect([collectionView cellForItemAtIndexPath:indexPath].isSelected).to.beFalsy();
        expect([collectionView cellForItemAtIndexPath:otherIndexPath].isSelected).to.beTruthy();
      });

      it(@"should stop deferring when an asset is deselected", ^{
        [viewController selectItem:otherAsset];
        [viewController deselectItem:asset];

        expect([collectionView cellForItemAtIndexPath:otherIndexPath].isSelected).to.beFalsy();

        dataSource.data = @[@[asset, otherAsset]];
        [collectionView reloadData];
        [collectionView layoutIfNeeded];
        [dataSource.didUpdateCollectionView sendNext:[RACUnit defaultUnit]];
        expect([collectionView cellForItemAtIndexPath:otherIndexPath].isSelected).to.beFalsy();
      });

      it(@"should defer until selected", ^{
        [viewController selectItem:otherAsset];

        dataSource.data = @[@[anotherAsset, asset]];
        [collectionView reloadData];
        [collectionView layoutIfNeeded];
        [dataSource.didUpdateCollectionView sendNext:[RACUnit defaultUnit]];

        expect([collectionView cellForItemAtIndexPath:indexPath].isSelected).to.beFalsy();
        expect([collectionView cellForItemAtIndexPath:otherIndexPath].isSelected).to.beFalsy();

        dataSource.data = @[@[otherAsset, asset]];
        [collectionView reloadData];
        [collectionView layoutIfNeeded];
        [dataSource.didUpdateCollectionView sendNext:[RACUnit defaultUnit]];

        expect([collectionView cellForItemAtIndexPath:indexPath].isSelected).to.beTruthy();
        expect([collectionView cellForItemAtIndexPath:otherIndexPath].isSelected).to.beFalsy();
      });
    });

    it(@"should correctly deselect items", ^{
      dataSource.data = @[@[asset]];
      [collectionView reloadData];
      [collectionView layoutIfNeeded];

      NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:0];
      [collectionView selectItemAtIndexPath:indexPath animated:NO
                             scrollPosition:UICollectionViewScrollPositionNone];
      expect([collectionView cellForItemAtIndexPath:indexPath].isSelected).to.beTruthy();
      [viewController deselectItem:asset];
      expect([collectionView cellForItemAtIndexPath:indexPath].isSelected).to.beFalsy();
    });

    it(@"should send values correctly when selecting items", ^{
      id<PTNDescriptor> otherAsset = PTNCreateAssetDescriptor(@"foo");
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
      id<PTNDescriptor> otherAsset = PTNCreateAssetDescriptor(@"foo");
      dataSource.data = @[@[asset, otherAsset]];
      [collectionView reloadData];
      [collectionView layoutIfNeeded];

      LLSignalTestRecorder *values = [[viewController itemDeselected] testRecorder];

      PTUSimulateDeselection(collectionView, [NSIndexPath indexPathForItem:0 inSection:0]);
      PTUSimulateDeselection(collectionView, [NSIndexPath indexPathForItem:1 inSection:0]);
      PTUSimulateDeselection(collectionView, [NSIndexPath indexPathForItem:0 inSection:0]);

      expect(values).to.sendValues(@[asset, otherAsset, asset]);
    });

    it(@"should complete selection and deselection signals when deallocated", ^{
      LLSignalTestRecorder *selectedRecorder;
      LLSignalTestRecorder *deselectedRecorder;
      __weak PTUCollectionViewController *weakController;

      @autoreleasepool {
        PTUCollectionViewController *controller =
            [[PTUCollectionViewController alloc] initWithDataSourceProvider:dataSourceProvider
            initialConfiguration:[PTUCollectionViewConfiguration defaultConfiguration]];
        weakController = controller;

        selectedRecorder = [[controller itemSelected] testRecorder];
        deselectedRecorder = [[controller itemDeselected] testRecorder];
      }

      expect(weakController).to.beNil();
      expect(selectedRecorder).will.complete();
      expect(deselectedRecorder).will.complete();
    });
  });

  context(@"scrolling", ^{
    __block id<PTNDescriptor> otherAsset;

    beforeEach(^{
      otherAsset = PTNCreateAssetDescriptor(@"bar");
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
        viewController.view.frame = CGRectMake(0, 0, 100, 300);
        [viewController.view layoutIfNeeded];
        [dataSource.didUpdateCollectionView sendNext:[RACUnit defaultUnit]];
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
        expect(collectionView.contentOffset).to.equal(CGPointMake(0, 300));
      });

      it(@"should correctly scroll at center position", ^{
        expect(collectionView.contentOffset).to.equal(CGPointMake(0, 0));
        [viewController scrollToItem:asset atScrollPosition:PTUCollectionViewScrollPositionCenter
                            animated:NO];
        expect(collectionView.contentOffset).to.equal(CGPointMake(0, 200));
      });

      it(@"should correctly scroll at bottom position", ^{
        expect(collectionView.contentOffset).to.equal(CGPointMake(0, 0));
        [viewController scrollToItem:asset
                    atScrollPosition:PTUCollectionViewScrollPositionBottomRight animated:NO];
        expect(collectionView.contentOffset).to.equal(CGPointMake(0, 100));
      });
    });

    context(@"horizontal", ^{
      beforeEach(^{
        PTUCollectionViewConfiguration *configuration =
            [[PTUCollectionViewConfiguration alloc]
            initWithAssetCellSizingStrategy:assetCellSizingStrategy
            albumCellSizingStrategy:albumCellSizingStrategy
            headerCellSizingStrategy:headerCellSizingStrategy minimumItemSpacing:0
            minimumLineSpacing:0 scrollDirection:UICollectionViewScrollDirectionHorizontal
            showVerticalScrollIndicator:YES showHorizontalScrollIndicator:NO enablePaging:NO
            keyboardDismissMode:UIScrollViewKeyboardDismissModeOnDrag];

        [viewController setConfiguration:configuration animated:NO];
        viewController.view.frame = CGRectMake(0, 0, 300, 100);
        [viewController.view layoutIfNeeded];
        [dataSource.didUpdateCollectionView sendNext:[RACUnit defaultUnit]];
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
        expect(collectionView.contentOffset).to.equal(CGPointMake(300, 0));
      });

      it(@"should correctly scroll at center position", ^{
        expect(collectionView.contentOffset).to.equal(CGPointMake(0, 0));
        [viewController scrollToItem:asset atScrollPosition:PTUCollectionViewScrollPositionCenter
                            animated:NO];
        expect(collectionView.contentOffset).to.equal(CGPointMake(200, 0));
      });

      it(@"should correctly scroll at right position", ^{
        expect(collectionView.contentOffset).to.equal(CGPointMake(0, 0));
        [viewController scrollToItem:asset
                    atScrollPosition:PTUCollectionViewScrollPositionBottomRight animated:NO];
        expect(collectionView.contentOffset).to.equal(CGPointMake(100, 0));
      });
    });

    context(@"deferring", ^{
      __block id<PTNDescriptor> bazAsset;
      __block id<PTNDescriptor> gazAsset;

      beforeEach(^{
        viewController.view.frame = CGRectMake(0, 0, 100, 300);
        [viewController.view layoutIfNeeded];
        bazAsset = PTNCreateDescriptor(@"baz");
        gazAsset = PTNCreateDescriptor(@"gaz");
      });

      it(@"should defer scrolling when item isn't in the collection", ^{
        [viewController scrollToItem:bazAsset
                    atScrollPosition:PTUCollectionViewScrollPositionCenter
                            animated:NO];
        expect(collectionView.contentOffset).to.equal(CGPointMake(0, 0));

        dataSource.data = @[@[
          otherAsset,
          otherAsset,
          otherAsset,
          bazAsset,
          otherAsset,
          otherAsset,
          otherAsset
        ]];
        [dataSource.didUpdateCollectionView sendNext:[RACUnit defaultUnit]];

        expect(collectionView.contentOffset).to.equal(CGPointMake(0, 200));
      });

      it(@"should defer only the latest scroll", ^{
        [viewController scrollToItem:bazAsset
                    atScrollPosition:PTUCollectionViewScrollPositionCenter
                            animated:NO];
        expect(collectionView.contentOffset).to.equal(CGPointMake(0, 0));

        [viewController scrollToItem:gazAsset
                    atScrollPosition:PTUCollectionViewScrollPositionCenter
                            animated:NO];
        expect(collectionView.contentOffset).to.equal(CGPointMake(0, 0));

        dataSource.data = @[@[
          otherAsset,
          bazAsset,
          otherAsset,
          gazAsset,
          otherAsset,
          otherAsset,
          otherAsset
        ]];
        [dataSource.didUpdateCollectionView sendNext:[RACUnit defaultUnit]];
        expect(collectionView.contentOffset).to.equal(CGPointMake(0, 200));
      });

      it(@"should stop deferring when a new asset is scrolled to", ^{
        [viewController scrollToItem:bazAsset
                    atScrollPosition:PTUCollectionViewScrollPositionCenter
                            animated:NO];
        expect(collectionView.contentOffset).to.equal(CGPointMake(0, 0));

        [viewController scrollToItem:asset
                    atScrollPosition:PTUCollectionViewScrollPositionCenter
                            animated:NO];
        expect(collectionView.contentOffset).to.equal(CGPointMake(0, 200));

        dataSource.data = @[@[
          bazAsset,
          otherAsset,
          otherAsset,
          otherAsset,
          otherAsset,
          otherAsset,
          otherAsset
        ]];
        [dataSource.didUpdateCollectionView sendNext:[RACUnit defaultUnit]];

        expect(collectionView.contentOffset).to.equal(CGPointMake(0, 200));
      });

      it(@"should stop deferring when scrolling is manually applied", ^{
        [viewController scrollToItem:bazAsset
                    atScrollPosition:PTUCollectionViewScrollPositionCenter
                            animated:NO];

        collectionView.contentOffset = CGPointMake(0, 1);

        dataSource.data = @[@[
          otherAsset,
          otherAsset,
          otherAsset,
          otherAsset,
          otherAsset,
          otherAsset,
          bazAsset
        ]];
        [dataSource.didUpdateCollectionView sendNext:[RACUnit defaultUnit]];

        expect(collectionView.contentOffset).to.equal(CGPointMake(0, 1));
      });

      it(@"should defer scrolling until applied", ^{
        [viewController scrollToItem:gazAsset
                    atScrollPosition:PTUCollectionViewScrollPositionCenter
                            animated:NO];
        expect(collectionView.contentOffset).to.equal(CGPointMake(0, 0));

        dataSource.data = @[@[
          otherAsset,
          otherAsset
        ]];
        [dataSource.didUpdateCollectionView sendNext:[RACUnit defaultUnit]];
        expect(collectionView.contentOffset).to.equal(CGPointMake(0, 0));

        dataSource.data = @[@[
          otherAsset,
          otherAsset,
          otherAsset,
          gazAsset,
          otherAsset,
          otherAsset
        ]];
        [dataSource.didUpdateCollectionView sendNext:[RACUnit defaultUnit]];
        expect(collectionView.contentOffset).to.equal(CGPointMake(0, 200));
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
    [controller.view layoutIfNeeded];

    [controller reloadData];

    OCMVerify(provider);
  });

  it(@"should correctly set background color", ^{
    expect(collectionViewContainer.backgroundColor).to.equal([UIColor clearColor]);
    viewController.backgroundColor = [UIColor redColor];
    expect(collectionViewContainer.backgroundColor).to.equal([UIColor redColor]);
  });

  it(@"should correctly get background color", ^{
    collectionViewContainer.backgroundColor = [UIColor redColor];
    expect(viewController.backgroundColor).to.equal([UIColor redColor]);
  });

  it(@"should correctly set background view", ^{
    UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
    viewController.backgroundView = view;
    expect([view isDescendantOfView:viewController.view]).to.beTruthy();

    [viewController.view layoutIfNeeded];
    expect(view.frame).to.equal(viewController.view.frame);

    viewController.view.frame = CGRectMake(0, 0, 25, 25);
    [viewController.view layoutIfNeeded];
    expect(view.frame).to.equal(viewController.view.frame);
  });

  it(@"should correctly get background view", ^{
    UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
    viewController.backgroundView = view;
    expect(viewController.backgroundView).to.equal(view);
  });

  it(@"should show the view when the data source has data and did not err", ^{
    dataSource.data = @[@[asset]];
    expect(collectionViewContainer.isHidden || collectionViewContainer.alpha == 0).to.beFalsy();
  });

  it(@"should hide the view when the data source has no data", ^{
    expect(collectionViewContainer.isHidden || collectionViewContainer.alpha == 0).to.beTruthy();
  });

  it(@"should hide the view when the data source has data but erred", ^{
    dataSource.data = @[@[asset]];
    dataSource.error = [NSError lt_errorWithCode:1337];
    expect(collectionViewContainer.isHidden || collectionViewContainer.alpha == 0).to.beTruthy();
  });

  it(@"should hide the view when the data source has no data and erred", ^{
    dataSource.error = [NSError lt_errorWithCode:1337];
    expect(collectionViewContainer.isHidden || collectionViewContainer.alpha == 0).to.beTruthy();
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
    expect(!emptyView.isHidden && emptyView.alpha == 1).to.beTruthy();

    dataSource.data = @[@[], @[]];
    expect(!emptyView.isHidden && emptyView.alpha == 1).to.beTruthy();
  });

  it(@"should not update empty view visibility outside the main thread", ^{
    LLSignalTestRecorder *recorder = [RACObserve(viewController, emptyView.hidden) testRecorder];

      dispatch_async(dispatch_queue_create(NULL, NULL), ^{
        dataSource.data = @[@[], @[]];
      });

    expect(recorder).will.sendValuesWithCount(2);
    expect(recorder.operatingThreads).to.equal([NSSet setWithObject:[NSThread mainThread]]);
  });

  it(@"should bind new empty views and set them according to the current value", ^{
    UIView *newEmptyView = [[UIView alloc] init];

    viewController.emptyView = newEmptyView;
    expect(!newEmptyView.isHidden && newEmptyView.alpha == 1).to.beTruthy();

    dataSource.data = @[@[asset]];
    expect(newEmptyView.isHidden || newEmptyView.alpha == 0).to.beTruthy();

    UIView *newerEmptyView = [[UIView alloc] init];
    viewController.emptyView = newerEmptyView;
    expect(newerEmptyView.isHidden || newerEmptyView.alpha == 0).to.beTruthy();

    dataSource.data = @[@[]];
    expect(!newerEmptyView.isHidden && newerEmptyView.alpha == 1).to.beTruthy();
  });
});

context(@"error view", ^{
  it(@"should hide the view when the data source did not err", ^{
    expect(viewController.errorView.isHidden || viewController.errorView.alpha == 0).to.beTruthy();
  });

  it(@"should show the view when the data source did err", ^{
    dataSource.error = [NSError lt_errorWithCode:1337];
    expect(!viewController.errorView.isHidden && viewController.errorView.alpha == 1).to.beTruthy();
  });

  it(@"should not update error view visibility outside the main thread", ^{
    LLSignalTestRecorder *recorder = [RACObserve(viewController, errorView.hidden) testRecorder];

      dispatch_async(dispatch_queue_create(NULL, NULL), ^{
        dataSource.error = [NSError lt_errorWithCode:1337];
      });

    expect(recorder).will.sendValuesWithCount(2);
    expect(recorder.operatingThreads).to.equal([NSSet setWithObject:[NSThread mainThread]]);
  });

  context(@"error view provider", ^{
    __block UIView *errorView;
    __block id<PTUErrorViewProvider> errorViewProvider;

    beforeEach(^{
      errorView = [[UIView alloc] init];
      errorViewProvider = OCMProtocolMock(@protocol(PTUErrorViewProvider));
      OCMStub([errorViewProvider errorViewForError:OCMOCK_ANY associatedURL:OCMOCK_ANY])
          .andReturn(errorView);
    });

    it(@"should use provided error view provider", ^{
      viewController.errorViewProvider = errorViewProvider;

      dataSource.error = [NSError lt_errorWithCode:1337];
      OCMVerify([errorViewProvider errorViewForError:dataSource.error associatedURL:OCMOCK_ANY]);
      expect([errorView isDescendantOfView:viewController.view]).to.beTruthy();
      expect(!errorView.isHidden && errorView.alpha == 1).to.beTruthy();

      dataSource.error = nil;
      expect(errorView.isHidden || errorView.alpha == 0).to.beTruthy();
    });

    it(@"should use provided error view provider retroactively", ^{
      dataSource.error = [NSError lt_errorWithCode:1337];
      expect([errorView isDescendantOfView:viewController.view]).to.beFalsy();

      viewController.errorViewProvider = errorViewProvider;
      OCMVerify([errorViewProvider errorViewForError:dataSource.error associatedURL:OCMOCK_ANY]);
      expect([errorView isDescendantOfView:viewController.view]).to.beTruthy();
      expect(!errorView.isHidden && errorView.alpha == 1).to.beTruthy();
    });

    it(@"should continue to function accross data sources", ^{
      PTUFakeDataSource *newDataSource = [[PTUFakeDataSource alloc] init];
      PTUDataSourceProvider *newDataSourceProvider =
          OCMProtocolMock(@protocol(PTUDataSourceProvider));
      OCMExpect([newDataSourceProvider dataSourceForCollectionView:OCMOCK_ANY])
          .andReturn(dataSource);
      OCMExpect([newDataSourceProvider dataSourceForCollectionView:OCMOCK_ANY])
          .andReturn(newDataSource);

      viewController =
          [[PTUCollectionViewController alloc] initWithDataSourceProvider:newDataSourceProvider
                                                     initialConfiguration:configuration];
      [viewController.view layoutIfNeeded];

      viewController.errorViewProvider = errorViewProvider;
      dataSource.error = [NSError lt_errorWithCode:1337];
      expect(!errorView.isHidden && errorView.alpha == 1).to.beTruthy();

      [viewController reloadData];
      expect(errorView.isHidden || errorView.alpha == 0).to.beTruthy();

      newDataSource.error = [NSError lt_errorWithCode:1338];
      expect(!errorView.isHidden && errorView.alpha == 1).to.beTruthy();
    });

    it(@"should provide associated urls", ^{
      viewController.errorViewProvider = errorViewProvider;
      NSURL *url = [NSURL URLWithString:@"http://www.foo.bar"];

      dataSource.error = [NSError lt_errorWithCode:1337 url:url];
      OCMVerify([errorViewProvider errorViewForError:dataSource.error associatedURL:url]);

      NSURL *descriptorURL = [NSURL URLWithString:@"http://www.foo.bar/baz"];
      id<PTNDescriptor> descriptor = PTNCreateDescriptor(descriptorURL, @"baz", 0, nil);
      dataSource.error = [NSError ptn_errorWithCode:1337 associatedDescriptor:descriptor];
      OCMVerify([errorViewProvider errorViewForError:dataSource.error associatedURL:descriptorURL]);

      NSURL *descriptorsURL = [NSURL URLWithString:@"http://www.foo.bar/baz/gaz"];
      id<PTNDescriptor> otherDescriptor = PTNCreateDescriptor(descriptorsURL, @"gaz", 0, nil);
      dataSource.error = [NSError ptn_errorWithCode:1337 associatedDescriptors:@[otherDescriptor]];
      OCMVerify([errorViewProvider errorViewForError:dataSource.error
                                       associatedURL:descriptorsURL]);
    });

    it(@"should bind new error views and set them according to the current value", ^{
      viewController.errorViewProvider = errorViewProvider;
      dataSource.error = [NSError lt_errorWithCode:1337];
      expect(!errorView.isHidden && errorView.alpha == 1).to.beTruthy();

      dataSource.error = nil;
      expect(errorView.isHidden || errorView.alpha == 0).to.beTruthy();
    });
  });
});

context(@"content inset", ^{
  __block PTUCollectionViewController *controller;

  beforeEach(^{
    controller = [[PTUCollectionViewController alloc] initWithDataSourceProvider:dataSourceProvider
                                                            initialConfiguration:configuration];
  });

  it(@"should forward content inset to underlying collection view", ^{
    [controller.view layoutIfNeeded];
    auto collectionView =
        (UICollectionView *)[controller.view wf_viewForAccessibilityIdentifier:@"CollectionView"];

    controller.contentInset = UIEdgeInsetsMake(1, 3, 3, 7);
    expect(collectionView.contentInset).to.equal(UIEdgeInsetsMake(1, 3, 3, 7));
    expect(controller.contentInset).to.equal(UIEdgeInsetsMake(1, 3, 3, 7));
  });

  it(@"should apply existing content inset to underlying collection view when created", ^{
    auto collectionView =
        (UICollectionView *)[controller.view wf_viewForAccessibilityIdentifier:@"CollectionView"];
    expect(collectionView).to.beNil();

    controller.contentInset = UIEdgeInsetsMake(1, 3, 3, 7);
    [controller.view layoutIfNeeded];
    collectionView =
        (UICollectionView *)[controller.view wf_viewForAccessibilityIdentifier:@"CollectionView"];

    expect(collectionView.contentInset).to.equal(UIEdgeInsetsMake(1, 3, 3, 7));
    expect(controller.contentInset).to.equal(UIEdgeInsetsMake(1, 3, 3, 7));
  });
});

SpecEnd
