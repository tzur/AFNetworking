// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Reuven Siman Tov.

#import "PTUAlbumViewController.h"

#import <LTKit/UIDevice+Hardware.h>
#import <Photons/PTNDescriptor.h>

#import "PTNTestUtils.h"
#import "PTUAlbumViewModel.h"
#import "PTUCollectionViewConfiguration.h"
#import "PTUCollectionViewController.h"
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

@interface PTUAlbumViewController (ForTesting)
@property (strong, nonatomic, nullable) PTUCollectionViewController *collectionViewController;
@end

SpecBegin(PTUAlbumViewController)

__block PTUAlbumViewController *albumView;
__block PTUAlbumViewModel *viewModel;

__block PTUCollectionViewConfiguration *configuration;
__block id<PTUDataSourceProvider> dataSourceProvider;
__block RACSubject *dataSourceProviderSignal;
__block RACSubject *selectedAssets;
__block RACSubject *scrollToAsset;

beforeEach(^{
  configuration = [PTUCollectionViewConfiguration defaultConfiguration];
  dataSourceProvider = OCMProtocolMock(@protocol(PTUDataSourceProvider));
  dataSourceProviderSignal = [RACSubject subject];
  selectedAssets = [RACSubject subject];
  scrollToAsset = [RACSubject subject];
  viewModel = [[PTUAlbumViewModel alloc] initWithDataSourceProvider:dataSourceProviderSignal
                                                     selectedAssets:selectedAssets
                                                      scrollToAsset:scrollToAsset
                                                       defaultTitle:@"default" url:nil];

  albumView = [[PTUAlbumViewController alloc] initWithViewModel:viewModel
                                                  configuration:configuration];
  [albumView loadViewIfNeeded];
  [albumView.view layoutIfNeeded];
});

it(@"should initially set title according to inital title of view model", ^{
  PTUAlbumViewController *viewController =
      [[PTUAlbumViewController alloc] initWithViewModel:viewModel configuration:configuration];
  expect(viewController.title).to.equal(@"default");
  expect(viewController.localizedTitle).to.equal(@"default");
});

it(@"should initialize a collection view when a data soruce provider is sent", ^{
  [dataSourceProviderSignal sendNext:dataSourceProvider];
  [albumView.view layoutIfNeeded];

  expect([albumView.view wf_viewForAccessibilityIdentifier:@"CollectionView"]).toNot.beNil();
});

it(@"should initialize a new collection view controller for each data source provider", ^{
  [dataSourceProviderSignal sendNext:dataSourceProvider];
  [albumView.view layoutIfNeeded];

  UIView *collectionView = [albumView.view wf_viewForAccessibilityIdentifier:@"CollectionView"];

  [dataSourceProviderSignal sendNext:OCMProtocolMock(@protocol(PTUDataSourceProvider))];
  expect([albumView.view wf_viewForAccessibilityIdentifier:@"CollectionView"])
      .toNot.equal(collectionView);
});

it(@"should initialize collection views with the given configuration", ^{
  [dataSourceProviderSignal sendNext:dataSourceProvider];
  [albumView.view layoutIfNeeded];

  UICollectionView *collectionView =
      (UICollectionView *)[albumView.view wf_viewForAccessibilityIdentifier:@"CollectionView"];

  expect(collectionView.collectionViewLayout).toNot.beNil();
  expect(collectionView.showsVerticalScrollIndicator)
      .to.equal(configuration.showsVerticalScrollIndicator);
  expect(collectionView.showsHorizontalScrollIndicator)
      .to.equal(configuration.showsHorizontalScrollIndicator);
  expect(collectionView.collectionViewLayout).beAKindOf([UICollectionViewFlowLayout class]);

  UICollectionViewFlowLayout *layout =
      (UICollectionViewFlowLayout *)collectionView.collectionViewLayout;
  expect(layout.scrollDirection).to.equal(configuration.scrollDirection);
  expect(layout.minimumLineSpacing).to.equal(configuration.minimumLineSpacing);
  expect(layout.minimumInteritemSpacing).to.equal(configuration.minimumItemSpacing);
});

context(@"default configurations", ^{
  __block UIDevice *deviceMock;

  beforeEach(^{
    deviceMock = OCMClassMock([UIDevice class]);
    OCMStub([(id)deviceMock currentDevice]).andReturn(deviceMock);
  });

  afterEach(^{
    [(id)deviceMock stopMocking];
    deviceMock = nil;
  });

  it(@"should initialize collection views with photoStrip configuration in factory initialzer", ^{
    PTUAlbumViewController *albumView = [PTUAlbumViewController photoStripWithViewModel:viewModel];
    [dataSourceProviderSignal sendNext:dataSourceProvider];

    expect(albumView.collectionViewController.configuration)
        .to.equal([PTUCollectionViewConfiguration photoStrip]);
  });

  it(@"should initialize collection views with album configuration in factory initialzer", ^{
    OCMStub([deviceMock lt_isPadIdiom]).andReturn(NO);
    PTUAlbumViewController *albumView = [PTUAlbumViewController albumWithViewModel:viewModel];
    [dataSourceProviderSignal sendNext:dataSourceProvider];

    expect(albumView.collectionViewController.configuration)
        .to.equal([PTUCollectionViewConfiguration defaultConfiguration]);
  });

  it(@"should initialize collection views with iPad album configuration in factory initialzer", ^{
    OCMStub([deviceMock lt_isPadIdiom]).andReturn(YES);
    PTUAlbumViewController *albumView = [PTUAlbumViewController albumWithViewModel:viewModel];
    [dataSourceProviderSignal sendNext:dataSourceProvider];

    expect(albumView.collectionViewController.configuration)
        .to.equal([PTUCollectionViewConfiguration defaultIPadConfiguration]);
  });
});

it(@"should populate selection and deselction signals", ^{
  expect(viewModel.assetSelected).toNot.beNil();
  expect(viewModel.assetDeselected).toNot.beNil();
});

it(@"should not load view on initialization", ^{
  PTUAlbumViewController *viewController =
      [[PTUAlbumViewController alloc] initWithViewModel:viewModel configuration:configuration];
  PTUFakeDataSource *dataSource = [[PTUFakeDataSource alloc] init];
  OCMStub([dataSourceProvider dataSourceForCollectionView:OCMOCK_ANY]).andReturn(dataSource);
  [dataSourceProviderSignal sendNext:dataSourceProvider];

  expect(viewController.isViewLoaded).to.beFalsy();
});

it(@"should update configuration of collection view controller", ^{
  PTUAlbumViewController *albumView = [PTUAlbumViewController photoStripWithViewModel:viewModel];
  [dataSourceProviderSignal sendNext:dataSourceProvider];

  expect(albumView.collectionViewController.configuration)
      .to.equal([PTUCollectionViewConfiguration photoStrip]);

  PTUCollectionViewConfiguration *configuration =
      [PTUCollectionViewConfiguration defaultConfiguration];
  [albumView setConfiguration:configuration animated:NO];

  expect(albumView.collectionViewController.configuration)
      .to.equal(configuration);
});

context(@"collection control", ^{
  __block PTUFakeDataSource *dataSource;
  __block id<PTNDescriptor> asset;
  __block id<PTNDescriptor> otherAsset;

  __block UICollectionView *collectionView;

  beforeEach(^{
    dataSource = [[PTUFakeDataSource alloc] init];
    asset = PTNCreateDescriptor(@"foo");
    otherAsset = PTNCreateDescriptor(@"bar");
    dataSource.data = @[@[otherAsset, otherAsset, asset, otherAsset, otherAsset]];
    OCMStub([dataSourceProvider dataSourceForCollectionView:OCMOCK_ANY]).andReturn(dataSource)
        .andDo(^(NSInvocation *invocation) {
          __unsafe_unretained UICollectionView *collectionView;
          [invocation getArgument:&collectionView atIndex:2];
          dataSource.collectionView = collectionView;
        });

    [dataSourceProviderSignal sendNext:dataSourceProvider];

    albumView.view.frame = CGRectMake(0, 0, 100, 302);
    [albumView.view layoutIfNeeded];
    [albumView loadViewIfNeeded];

    collectionView =
        (UICollectionView *)[albumView.view wf_viewForAccessibilityIdentifier:@"CollectionView"];

    [dataSource.didUpdateCollectionView sendNext:[RACUnit defaultUnit]];
  });

  it(@"should notify when assets are selected", ^{
    LLSignalTestRecorder *recorder = [viewModel.assetSelected testRecorder];

    PTUSimulateSelection(collectionView, [NSIndexPath indexPathForItem:2 inSection:0]);
    PTUSimulateSelection(collectionView, [NSIndexPath indexPathForItem:0 inSection:0]);

    expect(recorder).will.sendValues(@[asset, otherAsset]);
  });

  it(@"should notify when assets are deselected", ^{
    LLSignalTestRecorder *recorder = [viewModel.assetDeselected testRecorder];

    PTUSimulateDeselection(collectionView, [NSIndexPath indexPathForItem:2 inSection:0]);
    PTUSimulateDeselection(collectionView, [NSIndexPath indexPathForItem:0 inSection:0]);

    expect(recorder).will.sendValues(@[asset, otherAsset]);
  });

  it(@"should select assets", ^{
    expect([collectionView indexPathsForSelectedItems]).to.equal(@[]);

    [selectedAssets sendNext:@[asset]];
    expect([collectionView indexPathsForSelectedItems])
        .to.equal(@[[NSIndexPath indexPathForItem:2 inSection:0]]);

    [selectedAssets sendNext:@[asset, otherAsset]];
    expect([collectionView indexPathsForSelectedItems]).to.equal(@[
      [NSIndexPath indexPathForItem:0 inSection:0],
      [NSIndexPath indexPathForItem:2 inSection:0]
    ]);
  });

  it(@"should deselect assets", ^{
    expect([collectionView indexPathsForSelectedItems]).to.equal(@[]);

    [selectedAssets sendNext:@[asset, otherAsset]];
    expect([collectionView indexPathsForSelectedItems]).to.equal(@[
      [NSIndexPath indexPathForItem:0 inSection:0],
      [NSIndexPath indexPathForItem:2 inSection:0]
    ]);

    [selectedAssets sendNext:@[otherAsset]];
    expect([collectionView indexPathsForSelectedItems])
        .to.equal(@[[NSIndexPath indexPathForItem:0 inSection:0]]);

    [selectedAssets sendNext:@[]];
    expect([collectionView indexPathsForSelectedItems]).to.equal(@[]);
  });

  it(@"should scroll to assets", ^{
    expect([collectionView contentOffset]).to.equal(CGPointZero);

    [scrollToAsset sendNext:RACTuplePack((id<NSObject>)asset,
                                         @(PTUCollectionViewScrollPositionCenter))];
    expect([collectionView contentOffset]).to.equal(CGPointMake(0, 101));

    [scrollToAsset sendNext:RACTuplePack((id<NSObject>)asset,
                                         @(PTUCollectionViewScrollPositionTopLeft))];
    expect([collectionView contentOffset]).to.equal(CGPointMake(0, 202));

    [scrollToAsset sendNext:RACTuplePack((id<NSObject>)otherAsset,
                                         @(PTUCollectionViewScrollPositionCenter))];
    expect([collectionView contentOffset]).to.equal(CGPointZero);

    [scrollToAsset sendNext:RACTuplePack((id<NSObject>)otherAsset,
                                         @(PTUCollectionViewScrollPositionBottomRight))];
    expect([collectionView contentOffset]).to.equal(CGPointZero);
  });

  context(@"cell at location", ^{
    beforeEach(^{
      dataSource.data = @[
        @[OCMProtocolMock(@protocol(PTNAlbumDescriptor))],
        @[asset, asset, asset]
      ];
      dataSource.sectionTitles = @{@0: @"foo", @1: @"bar", @2: @"baz"};
      [dataSource.didUpdateCollectionView sendNext:[RACUnit defaultUnit]];
      [collectionView reloadData];
      [collectionView layoutIfNeeded];
    });

    it(@"should return cell at location", ^{
      auto albumCell = [albumView cellAtPoint:CGPointMake(50, 75)];
      auto albumCellIndex = [NSIndexPath indexPathForItem:0 inSection:0];
      expect(albumCell).to.equal([collectionView cellForItemAtIndexPath:albumCellIndex]);

      auto imageCell = [albumView cellAtPoint:CGPointMake(50, 275)];
      auto imageCellIndex = [NSIndexPath indexPathForItem:1 inSection:1];
      expect(imageCell).to.equal([collectionView cellForItemAtIndexPath:imageCellIndex]);
    });

    it(@"should return nil for locations without visible cells", ^{
      expect([albumView cellAtPoint:CGPointMake(-20, 75)]).to.beNil();
      expect([albumView cellAtPoint:CGPointMake(50, 12)]).to.beNil();
      expect([albumView cellAtPoint:CGPointMake(50, 353)]).to.beNil();
    });

    it(@"should consider current scrolling", ^{
      collectionView.contentOffset = CGPointMake(0, 102);

      auto cell = [albumView cellAtPoint:CGPointMake(50, 250)];
      auto cellIndex = [NSIndexPath indexPathForItem:2 inSection:1];
      expect(cell).to.equal([collectionView cellForItemAtIndexPath:cellIndex]);
      expect([albumView cellAtPoint:CGPointMake(50, 301)]).to.beNil();
    });
  });

  context(@"data source provider replacement", ^{
    __block PTUFakeDataSource *otherDataSource;
    __block id<PTUDataSourceProvider> otherDataSourceProvider;
    __block UICollectionView *currentCollectionView;

    beforeEach(^{
      otherDataSource = [[PTUFakeDataSource alloc] init];
      otherDataSource.data = @[@[asset, otherAsset, otherAsset, otherAsset]];
      otherDataSourceProvider = OCMProtocolMock(@protocol(PTUDataSourceProvider));
      OCMStub([otherDataSourceProvider dataSourceForCollectionView:OCMOCK_ANY])
          .andReturn(otherDataSource).andDo(^(NSInvocation *invocation) {
            __unsafe_unretained UICollectionView *collectionView;
            [invocation getArgument:&collectionView atIndex:2];
            otherDataSource.collectionView = collectionView;
            currentCollectionView = collectionView;
          });
    });

    it(@"should replace collection view", ^{
      [dataSourceProviderSignal sendNext:otherDataSourceProvider];
      [albumView.view layoutIfNeeded];

      expect(currentCollectionView)
          .to.equal([albumView.view wf_viewForAccessibilityIdentifier:@"CollectionView"]);
      expect(currentCollectionView).toNot.equal(collectionView);
    });

    it(@"should continue to notify selected assets", ^{
      LLSignalTestRecorder *recorder = [viewModel.assetSelected testRecorder];

      PTUSimulateSelection(collectionView, [NSIndexPath indexPathForItem:2 inSection:0]);
      PTUSimulateSelection(collectionView, [NSIndexPath indexPathForItem:0 inSection:0]);

      [dataSourceProviderSignal sendNext:otherDataSourceProvider];
      [albumView.view layoutIfNeeded];

      PTUSimulateSelection(currentCollectionView, [NSIndexPath indexPathForItem:2 inSection:0]);
      PTUSimulateSelection(currentCollectionView, [NSIndexPath indexPathForItem:0 inSection:0]);

      expect(recorder).will.sendValues(@[asset, otherAsset, otherAsset, asset]);
    });

    it(@"should continue to notify deselected assets", ^{
      LLSignalTestRecorder *recorder = [viewModel.assetDeselected testRecorder];

      PTUSimulateDeselection(collectionView, [NSIndexPath indexPathForItem:2 inSection:0]);
      PTUSimulateDeselection(collectionView, [NSIndexPath indexPathForItem:0 inSection:0]);

      [dataSourceProviderSignal sendNext:otherDataSourceProvider];
      [albumView.view layoutIfNeeded];

      PTUSimulateDeselection(currentCollectionView, [NSIndexPath indexPathForItem:2 inSection:0]);
      PTUSimulateDeselection(currentCollectionView, [NSIndexPath indexPathForItem:0 inSection:0]);

      expect(recorder).will.sendValues(@[asset, otherAsset, otherAsset, asset]);
    });

    it(@"should continue to select assets", ^{
      expect([collectionView indexPathsForSelectedItems]).to.equal(@[]);

      [selectedAssets sendNext:@[asset]];
      expect([collectionView indexPathsForSelectedItems])
          .to.equal(@[[NSIndexPath indexPathForItem:2 inSection:0]]);

      [selectedAssets sendNext:@[asset, otherAsset]];
      expect([collectionView indexPathsForSelectedItems]).to.equal(@[
        [NSIndexPath indexPathForItem:0 inSection:0],
        [NSIndexPath indexPathForItem:2 inSection:0]
      ]);

      [dataSourceProviderSignal sendNext:otherDataSourceProvider];
      [albumView.view layoutIfNeeded];
      [otherDataSource.didUpdateCollectionView sendNext:[RACUnit defaultUnit]];
      expect([currentCollectionView indexPathsForSelectedItems]).to.equal(@[]);

      [selectedAssets sendNext:@[asset]];
      expect([currentCollectionView indexPathsForSelectedItems])
          .to.equal(@[[NSIndexPath indexPathForItem:0 inSection:0]]);

      [selectedAssets sendNext:@[asset, otherAsset]];
      expect([currentCollectionView indexPathsForSelectedItems]).to.equal(@[
        [NSIndexPath indexPathForItem:1 inSection:0],
        [NSIndexPath indexPathForItem:0 inSection:0]
      ]);
    });

    it(@"should continue to deselect assets", ^{
      expect([collectionView indexPathsForSelectedItems]).to.equal(@[]);

      [selectedAssets sendNext:@[asset, otherAsset]];
      expect([collectionView indexPathsForSelectedItems]).to.equal(@[
        [NSIndexPath indexPathForItem:0 inSection:0],
        [NSIndexPath indexPathForItem:2 inSection:0]
      ]);

      [selectedAssets sendNext:@[otherAsset]];
      expect([collectionView indexPathsForSelectedItems])
          .to.equal(@[[NSIndexPath indexPathForItem:0 inSection:0]]);

      [selectedAssets sendNext:@[]];
      expect([collectionView indexPathsForSelectedItems]).to.equal(@[]);

      [dataSourceProviderSignal sendNext:otherDataSourceProvider];
      [albumView.view layoutIfNeeded];
      [otherDataSource.didUpdateCollectionView sendNext:[RACUnit defaultUnit]];
      expect([collectionView indexPathsForSelectedItems]).to.equal(@[]);

      [selectedAssets sendNext:@[asset, otherAsset]];
      expect([currentCollectionView indexPathsForSelectedItems]).to.equal(@[
        [NSIndexPath indexPathForItem:1 inSection:0],
        [NSIndexPath indexPathForItem:0 inSection:0]
      ]);

      [selectedAssets sendNext:@[otherAsset]];
      expect([currentCollectionView indexPathsForSelectedItems])
          .to.equal(@[[NSIndexPath indexPathForItem:1 inSection:0]]);

      [selectedAssets sendNext:@[]];
      expect([currentCollectionView indexPathsForSelectedItems]).to.equal(@[]);
    });

    it(@"should continue to scroll to assets", ^{
      expect([collectionView contentOffset]).to.equal(CGPointZero);

      [scrollToAsset sendNext:RACTuplePack((id<NSObject>)asset,
                                           @(PTUCollectionViewScrollPositionCenter))];
      expect([collectionView contentOffset]).to.equal(CGPointMake(0, 101));

      [scrollToAsset sendNext:RACTuplePack((id<NSObject>)asset,
                                           @(PTUCollectionViewScrollPositionTopLeft))];
      expect([collectionView contentOffset]).to.equal(CGPointMake(0, 202));

      [dataSourceProviderSignal sendNext:otherDataSourceProvider];
      [albumView.view layoutIfNeeded];

      expect([currentCollectionView contentOffset]).to.equal(CGPointZero);
      expect(currentCollectionView.frame).to.equal(CGRectMake(0, 0, 100, 302));

      [scrollToAsset sendNext:RACTuplePack((id<NSObject>)otherAsset,
                                           @(PTUCollectionViewScrollPositionTopLeft))];
      expect([currentCollectionView contentOffset]).to.equal(CGPointMake(0, 101));
    });

    it(@"should map localized title to initial title followed by latest data source title", ^{
      expect(albumView.localizedTitle).to.equal(@"default");

      dataSource.title = @"foo";
      expect(albumView.localizedTitle).to.equal(@"foo");

      dataSource.title = @"bar";
      expect(albumView.localizedTitle).to.equal(@"bar");

      [dataSourceProviderSignal sendNext:otherDataSourceProvider];
      [albumView.view layoutIfNeeded];
      expect(albumView.localizedTitle).to.equal(@"default");

      otherDataSource.title = @"baz";
      expect(albumView.localizedTitle).to.equal(@"baz");
    });
  });

  it(@"should not send selection after change of selection not done by user", ^{
    LLSignalTestRecorder *recorder = [viewModel.assetSelected testRecorder];
    [selectedAssets sendNext:@[asset]];
    expect(recorder.values).to.equal(@[]);
  });

  it(@"should pass calls to reloadData to internal view controller", ^{
    dataSourceProvider = OCMProtocolMock(@protocol(PTUDataSourceProvider));
    [dataSourceProviderSignal sendNext:dataSourceProvider];

    OCMExpect([dataSourceProvider dataSourceForCollectionView:OCMOCK_ANY]);

    [albumView loadViewIfNeeded];
    [albumView.view layoutIfNeeded];
    [albumView reloadData];

    OCMVerifyAll(dataSourceProvider);
  });
});

context(@"subviews", ^{
  __block UIView *view;
  __block PTUErrorViewProvider *errorViewProvider;

  beforeEach(^{
    [albumView loadViewIfNeeded];
    view = [[UIView alloc] initWithFrame:CGRectZero];
    errorViewProvider = [[PTUErrorViewProvider alloc] initWithView:view];
  });

  it(@"should set default views", ^{
    expect(albumView.backgroundView).to.beNil();
    expect(albumView.emptyView).toNot.beNil();
    expect(albumView.errorView).toNot.beNil();
    expect(albumView.errorViewProvider).to.beNil();
  });

  it(@"should match the initial views of the sub view controller", ^{
    [dataSourceProviderSignal sendNext:dataSourceProvider];
    expect(albumView.collectionViewController).willNot.beNil();

    expect(albumView.backgroundView).to.equal(albumView.collectionViewController.backgroundView);
    expect(albumView.emptyView).to.equal(albumView.collectionViewController.emptyView);
    expect(albumView.errorView).to.equal(albumView.collectionViewController.errorView);
    expect(albumView.errorViewProvider)
        .to.equal(albumView.collectionViewController.errorViewProvider);
  });

  it(@"should set the initial views of the sub view controller", ^{
    albumView.backgroundView = view;
    albumView.emptyView = view;
    albumView.errorView = view;
    albumView.errorViewProvider = errorViewProvider;

    [dataSourceProviderSignal sendNext:dataSourceProvider];
    expect(albumView.collectionViewController).willNot.beNil();

    expect(albumView.collectionViewController.backgroundView).to.equal(view);
    expect(albumView.collectionViewController.emptyView).to.equal(view);
    expect(albumView.collectionViewController.errorView).to.equal(view);
    expect(albumView.collectionViewController.errorViewProvider).to.equal(errorViewProvider);
  });

  context(@"setters", ^{
    beforeEach(^{
      [dataSourceProviderSignal sendNext:dataSourceProvider];
      expect(albumView.collectionViewController).willNot.beNil();

      albumView.backgroundView = view;
      albumView.emptyView = view;
      albumView.errorView = view;
      albumView.errorViewProvider = errorViewProvider;
    });

    it(@"should update the views of the sub view controller", ^{
      expect(albumView.collectionViewController.backgroundView).to.equal(view);
      expect(albumView.collectionViewController.emptyView).to.equal(view);
      expect(albumView.collectionViewController.errorView).to.equal(view);
      expect(albumView.collectionViewController.errorViewProvider).to.equal(errorViewProvider);
    });

    it(@"should update the views of new sub view controller", ^{
      PTUCollectionViewController *collectionViewController = albumView.collectionViewController;
      [dataSourceProviderSignal sendNext:dataSourceProvider];
      expect(albumView.collectionViewController).willNot.equal(collectionViewController);

      expect(albumView.collectionViewController.backgroundView).to.equal(view);
      expect(albumView.collectionViewController.emptyView).to.equal(view);
      expect(albumView.collectionViewController.errorView).to.equal(view);
      expect(albumView.collectionViewController.errorViewProvider).to.equal(errorViewProvider);
    });
  });
});

context(@"content inset", ^{
  __block PTUAlbumViewController *controller;

  beforeEach(^{
    controller = [[PTUAlbumViewController alloc] initWithViewModel:viewModel
                                                     configuration:configuration];
  });

  it(@"should forward content inset to underlying collection view", ^{
    [dataSourceProviderSignal sendNext:dataSourceProvider];
    [controller.view layoutIfNeeded];

    controller.contentInset = UIEdgeInsetsMake(1, 3, 3, 7);
    expect(controller.collectionViewController.contentInset).to.equal(UIEdgeInsetsMake(1, 3, 3, 7));
    expect(controller.contentInset).to.equal(UIEdgeInsetsMake(1, 3, 3, 7));
  });

  it(@"should apply existing content inset to underlying collection view when created", ^{
    expect(controller.collectionViewController).to.beNil();

    controller.contentInset = UIEdgeInsetsMake(1, 3, 3, 7);
    [dataSourceProviderSignal sendNext:dataSourceProvider];
    [controller.view layoutIfNeeded];
    expect(controller.collectionViewController.contentInset).to.equal(UIEdgeInsetsMake(1, 3, 3, 7));
    expect(controller.contentInset).to.equal(UIEdgeInsetsMake(1, 3, 3, 7));
  });
});

it(@"should deallocate regardless of view model signals' lifetime", ^{
  __weak PTUAlbumViewController *weakViewController;

  @autoreleasepool {
    PTUAlbumViewController *viewController =
        [[PTUAlbumViewController alloc] initWithViewModel:viewModel configuration:configuration];
    [viewController loadViewIfNeeded];
    weakViewController = viewController;
  }

  expect(weakViewController).to.beNil();
});

SpecEnd
