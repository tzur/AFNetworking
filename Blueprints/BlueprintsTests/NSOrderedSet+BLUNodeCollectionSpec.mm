// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "NSOrderedSet+BLUNodeCollection.h"

#import "BLUNode.h"
#import "BLUNodeCollectionExamples.h"

SpecBegin(NSOrderedSet_BLUNodeCollection)

itShouldBehaveLike(kBLUNodeCollectionExamples, ^{
  NSOrderedSet<BLUNode *> *collection = [NSOrderedSet orderedSetWithArray:@[
    [BLUNode nodeWithName:@"first" childNodes:[NSOrderedSet orderedSet] value:@7],
    [BLUNode nodeWithName:@"second" childNodes:[NSOrderedSet orderedSet] value:@5],
    [BLUNode nodeWithName:@"third" childNodes:[NSOrderedSet orderedSet] value:@3]
  ]];

  return @{kBLUNodeCollectionExamplesCollection: collection};
});

SpecEnd
