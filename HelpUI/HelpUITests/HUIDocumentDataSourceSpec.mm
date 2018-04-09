// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Daniel Hadar.

#import "HUIDocumentDataSource.h"

#import <LTKit/LTImageLoader.h>

#import "HUIDocument.h"
#import "HUIImageCell.h"
#import "HUIItem.h"
#import "HUISection.h"
#import "HUISlideshowCell.h"
#import "HUIVideoCell.h"

SpecBegin(HUIDocumentDataSource)

__block HUIDocumentDataSource *dataSource;
__block UICollectionView *collectionViewMock;

beforeEach(^{
  collectionViewMock = OCMClassMock([UICollectionView class]);
});

context(@"with document", ^{
  __block HUIDocument *document;
  __block NSArray *indexPaths;

  beforeEach(^{
    NSDictionary *dict = @{
      @"sections": @[
        @{
          @"key": @"key1",
          @"items": @[
            @{
              @"type": @"slideshow",
              @"transition": @"curtain",
              @"images": @[],
              @"associatedProductIdentifiers": @[@"id1"],
            }
          ],
        },
        @{
          @"key": @"key2",
          @"items": @[
            @{
              @"type": @"video",
            },
            @{
              @"type": @"image",
              @"associatedProductIdentifiers": @[@"id2"],
              @"image": @"foo"
            },
            @{
              @"type": @"video",
              @"associatedProductIdentifiers": @[@"id3"],
            }
          ]
        }
      ]
    };

    NSError *error;
    document = [MTLJSONAdapter modelOfClass:HUIDocument.class fromJSONDictionary:dict error:&error];

    indexPaths = @[
      [NSIndexPath indexPathForItem:0 inSection:0],
      [NSIndexPath indexPathForItem:0 inSection:1],
      [NSIndexPath indexPathForItem:1 inSection:1],
      [NSIndexPath indexPathForItem:2 inSection:1]
    ];

    [HUISettings instance].imageLoader = [LTImageLoader sharedInstance];
    dataSource = [[HUIDocumentDataSource alloc] initWithHelpDocument:document];
  });

  it(@"should set dataSource correctly", ^{
    expect(dataSource.helpDocument).to.equal(document);
  });

  it(@"should retrieve slideshow cells correctly", ^{
    OCMStub([collectionViewMock dequeueReusableCellWithReuseIdentifier:@"HUISlideshowCell"
            forIndexPath:indexPaths[0]]).andReturn([[HUISlideshowCell alloc] init]);

    expect([dataSource collectionView:collectionViewMock
               cellForItemAtIndexPath:indexPaths[0]]).to.beKindOf(HUISlideshowCell.class);
  });

  it(@"should retrieve video cells correctly", ^{
    OCMStub([collectionViewMock dequeueReusableCellWithReuseIdentifier:@"HUIVideoCell"
            forIndexPath:indexPaths[1]]).andReturn([[HUIVideoCell alloc] init]);

    expect([dataSource collectionView:collectionViewMock
               cellForItemAtIndexPath:indexPaths[1]]).to.beKindOf(HUIVideoCell.class);
  });

  it(@"should retrieve image cells correctly", ^{
    OCMStub([collectionViewMock dequeueReusableCellWithReuseIdentifier:@"HUIImageCell"
            forIndexPath:indexPaths[2]]).andReturn([[HUIImageCell alloc] init]);

    expect([dataSource collectionView:collectionViewMock
               cellForItemAtIndexPath:indexPaths[2]]).to.beKindOf(HUIImageCell.class);
  });

  it(@"should return correct number of sections", ^{
    expect([dataSource numberOfSectionsInCollectionView:collectionViewMock]).to.equal(2);
  });

  it(@"should return correct number of items", ^{
    expect([dataSource collectionView:collectionViewMock numberOfItemsInSection:0]).to.equal(1);
    expect([dataSource collectionView:collectionViewMock numberOfItemsInSection:1]).to.equal(3);
  });

  it(@"should register cell classes", ^{
    [dataSource registerCellClassesWithCollectionView:collectionViewMock];

    OCMVerify([collectionViewMock registerClass:HUISlideshowCell.class
                     forCellWithReuseIdentifier:[OCMArg any]]);
    OCMVerify([collectionViewMock registerClass:HUIVideoCell.class
                     forCellWithReuseIdentifier:[OCMArg any]]);
    OCMVerify([collectionViewMock registerClass:HUIImageCell.class
                     forCellWithReuseIdentifier:[OCMArg any]]);
  });
});

it(@"should allow data source without help document", ^{
  dataSource = [[HUIDocumentDataSource alloc] initWithHelpDocument:nil];

  expect(dataSource).notTo.beNil();
  expect(dataSource.helpDocument).to.beNil();
  expect([dataSource numberOfSectionsInCollectionView:collectionViewMock]).to.equal(0);
});

SpecEnd
