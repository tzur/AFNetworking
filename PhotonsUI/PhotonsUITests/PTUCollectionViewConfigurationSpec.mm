// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTUCollectionViewConfiguration.h"

#import "PTUCellSizingStrategy.h"

SpecBegin(PTUCollectionViewConfiguration)

it(@"should correctly initialize", ^{
  id<PTUCellSizingStrategy> assetSizingStrategy = OCMProtocolMock(@protocol(PTUCellSizingStrategy));
  id<PTUCellSizingStrategy> albumSizingStrategy = OCMProtocolMock(@protocol(PTUCellSizingStrategy));

  PTUCollectionViewConfiguration *configuration = [[PTUCollectionViewConfiguration alloc]
      initWithAssetCellSizingStrategy:assetSizingStrategy
      albumCellSizingStrategy:albumSizingStrategy minimumItemSpacing:1 minimumLineSpacing:2
      scrollDirection:UICollectionViewScrollDirectionVertical showVerticalScrollIndicator:YES
      showHorizontalScrollIndicator:NO enablePaging:YES];

  expect(configuration.assetCellSizingStrategy).to.equal(assetSizingStrategy);
  expect(configuration.albumCellSizingStrategy).to.equal(albumSizingStrategy);
  expect(configuration.minimumItemSpacing).to.equal(1);
  expect(configuration.minimumLineSpacing).to.equal(2);
  expect(configuration.scrollDirection).to.equal(UICollectionViewScrollDirectionVertical);
  expect(configuration.showsVerticalScrollIndicator).to.beTruthy();
  expect(configuration.showsHorizontalScrollIndicator).to.beFalsy();
  expect(configuration.enablePaging).to.beTruthy();
});

it(@"should correctly initalize with convenient initializer", ^{
  PTUCollectionViewConfiguration *configuration =
      [PTUCollectionViewConfiguration defaultConfiguration];

  expect(configuration.assetCellSizingStrategy).to.beKindOf([PTUAdaptiveCellSizingStrategy class]);
  expect(configuration.albumCellSizingStrategy).to.beKindOf([PTURowSizingStrategy class]);
  expect(configuration.minimumItemSpacing).to.equal(1);
  expect(configuration.minimumLineSpacing).to.equal(1);
  expect(configuration.scrollDirection).to.equal(UICollectionViewScrollDirectionVertical);
  expect(configuration.showsVerticalScrollIndicator).to.beTruthy();
  expect(configuration.showsHorizontalScrollIndicator).to.beFalsy();
  expect(configuration.enablePaging).to.beFalsy();
});

context(@"equality", ^{
  __block PTUCollectionViewConfiguration *firstConfiguration;
  __block PTUCollectionViewConfiguration *secondConfiguration;
  __block PTUCollectionViewConfiguration *otherConfiguration;

  beforeEach(^{
    id<PTUCellSizingStrategy> assetSizingStrategy =
        OCMProtocolMock(@protocol(PTUCellSizingStrategy));
    id<PTUCellSizingStrategy> albumSizingStrategy =
        OCMProtocolMock(@protocol(PTUCellSizingStrategy));

    firstConfiguration = [[PTUCollectionViewConfiguration alloc]
      initWithAssetCellSizingStrategy:assetSizingStrategy
      albumCellSizingStrategy:albumSizingStrategy minimumItemSpacing:1 minimumLineSpacing:2
      scrollDirection:UICollectionViewScrollDirectionVertical showVerticalScrollIndicator:YES
      showHorizontalScrollIndicator:NO enablePaging:YES];
    secondConfiguration = [[PTUCollectionViewConfiguration alloc]
      initWithAssetCellSizingStrategy:assetSizingStrategy
      albumCellSizingStrategy:albumSizingStrategy minimumItemSpacing:1 minimumLineSpacing:2
      scrollDirection:UICollectionViewScrollDirectionVertical showVerticalScrollIndicator:YES
      showHorizontalScrollIndicator:NO enablePaging:YES];
    otherConfiguration = [[PTUCollectionViewConfiguration alloc]
      initWithAssetCellSizingStrategy:assetSizingStrategy
      albumCellSizingStrategy:albumSizingStrategy minimumItemSpacing:3 minimumLineSpacing:2
      scrollDirection:UICollectionViewScrollDirectionVertical showVerticalScrollIndicator:YES
      showHorizontalScrollIndicator:NO enablePaging:NO];
  });

  it(@"should handle isEqual correctly", ^{
    expect(firstConfiguration).to.equal(secondConfiguration);
    expect(secondConfiguration).to.equal(firstConfiguration);

    expect(firstConfiguration).notTo.equal(otherConfiguration);
    expect(secondConfiguration).notTo.equal(otherConfiguration);
  });

  it(@"should create proper hash", ^{
    expect(firstConfiguration.hash).to.equal(secondConfiguration.hash);
  });
});

SpecEnd
