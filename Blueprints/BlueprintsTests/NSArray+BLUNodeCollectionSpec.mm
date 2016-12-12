// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "NSArray+BLUNodeCollection.h"

#import "BLUNode.h"
#import "BLUNodeCollectionExamples.h"

SpecBegin(NSArray_BLUNodeCollection)

itShouldBehaveLike(kBLUNodeCollectionExamples, ^{
  NSArray<BLUNode *> *collection = @[
    [BLUNode nodeWithName:@"first" childNodes:@[] value:@7],
    [BLUNode nodeWithName:@"second" childNodes:@[] value:@5],
    [BLUNode nodeWithName:@"third" childNodes:@[] value:@3]
  ];

  return @{kBLUNodeCollectionExamplesCollection: collection};
});

SpecEnd
