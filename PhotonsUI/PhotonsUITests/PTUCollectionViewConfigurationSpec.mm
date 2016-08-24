// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTUCollectionViewConfiguration.h"

#import "PTUCellSizingStrategy.h"

SpecBegin(PTUCollectionViewConfiguration)

it(@"should correctly initialize", ^{
  id<PTUCellSizingStrategy> assetSizingStrategy = OCMProtocolMock(@protocol(PTUCellSizingStrategy));
  id<PTUCellSizingStrategy> albumSizingStrategy = OCMProtocolMock(@protocol(PTUCellSizingStrategy));
  id<PTUCellSizingStrategy> headerSizingStrategy =
      OCMProtocolMock(@protocol(PTUCellSizingStrategy));

  PTUCollectionViewConfiguration *configuration = [[PTUCollectionViewConfiguration alloc]
      initWithAssetCellSizingStrategy:assetSizingStrategy
      albumCellSizingStrategy:albumSizingStrategy headerCellSizingStrategy:headerSizingStrategy
      minimumItemSpacing:1 minimumLineSpacing:2
      scrollDirection:UICollectionViewScrollDirectionVertical showVerticalScrollIndicator:YES
      showHorizontalScrollIndicator:NO enablePaging:YES];

  expect(configuration.assetCellSizingStrategy).to.equal(assetSizingStrategy);
  expect(configuration.albumCellSizingStrategy).to.equal(albumSizingStrategy);
  expect(configuration.headerCellSizingStrategy).to.equal(headerSizingStrategy);
  expect(configuration.minimumItemSpacing).to.equal(1);
  expect(configuration.minimumLineSpacing).to.equal(2);
  expect(configuration.scrollDirection).to.equal(UICollectionViewScrollDirectionVertical);
  expect(configuration.showsVerticalScrollIndicator).to.beTruthy();
  expect(configuration.showsHorizontalScrollIndicator).to.beFalsy();
  expect(configuration.enablePaging).to.beTruthy();
});

it(@"should correctly initalize with default initializer", ^{
  PTUCollectionViewConfiguration *configuration =
      [PTUCollectionViewConfiguration defaultConfiguration];

  id<PTUCellSizingStrategy> assetSizingStrategy =
      [PTUCellSizingStrategy adaptiveFitRow:CGSizeMake(92, 92) maximumScale:1.2];
  id<PTUCellSizingStrategy> albumSizingStrategy = [PTUCellSizingStrategy rowWithHeight:100];
  id<PTUCellSizingStrategy> headerSizingStrategy = [PTUCellSizingStrategy rowWithHeight:25];
  expect(configuration.assetCellSizingStrategy).to.equal(assetSizingStrategy);
  expect(configuration.albumCellSizingStrategy).to.equal(albumSizingStrategy);
  expect(configuration.headerCellSizingStrategy).to.equal(headerSizingStrategy);
  expect(configuration.minimumItemSpacing).to.equal(1);
  expect(configuration.minimumLineSpacing).to.equal(1);
  expect(configuration.scrollDirection).to.equal(UICollectionViewScrollDirectionVertical);
  expect(configuration.showsVerticalScrollIndicator).to.beTruthy();
  expect(configuration.showsHorizontalScrollIndicator).to.beFalsy();
  expect(configuration.enablePaging).to.beFalsy();
});

it(@"should correctly initalize with photo strip initializer", ^{
  PTUCollectionViewConfiguration *configuration = [PTUCollectionViewConfiguration photoStrip];
  
  id<PTUCellSizingStrategy> assetSizingStrategy = [PTUCellSizingStrategy gridWithItemsPerColumn:1];
  id<PTUCellSizingStrategy> albumSizingStrategy = [PTUCellSizingStrategy gridWithItemsPerColumn:1];
  id<PTUCellSizingStrategy> headerSizingStrategy = [PTUCellSizingStrategy constant:CGSizeZero];
  expect(configuration.assetCellSizingStrategy).to.equal(assetSizingStrategy);
  expect(configuration.albumCellSizingStrategy).to.equal(albumSizingStrategy);
  expect(configuration.headerCellSizingStrategy).to.equal(headerSizingStrategy);
  expect(configuration.minimumItemSpacing).to.equal(0);
  expect(configuration.minimumLineSpacing).to.equal(1);
  expect(configuration.scrollDirection).to.equal(UICollectionViewScrollDirectionHorizontal);
  expect(configuration.showsVerticalScrollIndicator).to.beFalsy();
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
    id<PTUCellSizingStrategy> headerSizingStrategy =
        OCMProtocolMock(@protocol(PTUCellSizingStrategy));

    firstConfiguration = [[PTUCollectionViewConfiguration alloc]
      initWithAssetCellSizingStrategy:assetSizingStrategy
      albumCellSizingStrategy:albumSizingStrategy headerCellSizingStrategy:headerSizingStrategy
      minimumItemSpacing:1 minimumLineSpacing:2
      scrollDirection:UICollectionViewScrollDirectionVertical showVerticalScrollIndicator:YES
      showHorizontalScrollIndicator:NO enablePaging:YES];
    secondConfiguration = [[PTUCollectionViewConfiguration alloc]
      initWithAssetCellSizingStrategy:assetSizingStrategy
      albumCellSizingStrategy:albumSizingStrategy headerCellSizingStrategy:headerSizingStrategy
      minimumItemSpacing:1 minimumLineSpacing:2
      scrollDirection:UICollectionViewScrollDirectionVertical showVerticalScrollIndicator:YES
      showHorizontalScrollIndicator:NO enablePaging:YES];
    otherConfiguration = [[PTUCollectionViewConfiguration alloc]
      initWithAssetCellSizingStrategy:assetSizingStrategy
      albumCellSizingStrategy:albumSizingStrategy headerCellSizingStrategy:headerSizingStrategy
      minimumItemSpacing:3 minimumLineSpacing:2
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
