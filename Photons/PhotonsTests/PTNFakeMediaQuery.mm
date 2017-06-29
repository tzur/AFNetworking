// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Michael Kimyagarov.

#import "PTNFakeMediaQuery.h"

#import <MediaPlayer/MPMediaQuery.h>

#import "PTNMediaQueryProvider.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTNFakeMediaQuery ()

/// Array storing the items, which are sequentially retrieved when reading \c self.items.
@property (readonly, nonatomic, nullable) NSArray<NSArray<MPMediaItem *> *> *itemsSequence;

/// Array storing the collections, which are sequentially retrieved when reading
/// \c self.collections.
@property (readonly, nonatomic, nullable)
    NSArray<NSArray<MPMediaItemCollection *> *> *collectionsSequence;

/// Current reading index in the \c itemsSequence array.
@property (nonatomic) NSUInteger itemIndex;

/// Current reading index in the \c collectionsSequence array.
@property (nonatomic) NSUInteger collectionIndex;

@end

@implementation PTNFakeMediaQuery

@synthesize groupingType = _groupingType;
@synthesize filterPredicates = _filterPredicates;

- (instancetype)initWithItems:(nullable NSArray<MPMediaItem *> *)items {
  if (!items) {
    return [self initWithItemsSequence:nil];
  }
  return [self initWithItemsSequence:@[items]];
}

- (instancetype)initWithItemsSequence:(nullable NSArray<NSArray<MPMediaItem *> *> *)itemsSequence {
  return [self initWithSequencesOfItems:itemsSequence collections:nil];
}

- (instancetype)initWithCollectionsSequence:
    (nullable NSArray<NSArray<MPMediaItemCollection *> *> *)sequence {
  return [self initWithSequencesOfItems:nil collections:sequence];
}

- (instancetype)initWithSequencesOfItems:(nullable NSArray *)itemSeq
                             collections:(nullable NSArray *)collectionSeq {
  if (self = [super init]) {
    _itemsSequence = itemSeq;
    _collectionsSequence = collectionSeq;
    _itemIndex = 0;
    _collectionIndex = 0;
  }
  return self;
}

- (nullable NSArray<MPMediaItem *> *)items {
  if (!self.itemsSequence) {
    return nil;
  }
  NSArray<MPMediaItem *> *items = self.itemsSequence[self.itemIndex];
  self.itemIndex = (self.itemIndex + 1) % self.itemsSequence.count;
  return items;
}

- (nullable NSArray<MPMediaItemCollection *> *)collections {
  if (!self.collectionsSequence) {
    return nil;
  }
  NSArray<MPMediaItemCollection *> *collections = self.collectionsSequence[self.collectionIndex];
  self.collectionIndex = (self.collectionIndex + 1) % self.collectionsSequence.count;
  return collections;
}

@end

NS_ASSUME_NONNULL_END
