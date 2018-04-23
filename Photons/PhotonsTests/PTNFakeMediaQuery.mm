// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Michael Kimyagarov.

#import "PTNFakeMediaQuery.h"

#import <MediaPlayer/MPMediaQuery.h>

#import "PTNMediaQueryProvider.h"

NS_ASSUME_NONNULL_BEGIN

@implementation PTNFakeMediaQuery

@synthesize groupingType = _groupingType;
@synthesize filterPredicates = _filterPredicates;

- (instancetype)init {
  return [self initWithItems:nil collections:nil];
}

- (instancetype)initWithItems:(nullable NSArray<MPMediaItem *> *)items {
  return [self initWithItems:items collections:nil];
}

- (instancetype)initWithCollections:(nullable NSArray<MPMediaItemCollection *> *)collections {
  return [self initWithItems:nil collections:collections];
}

- (instancetype)initWithItems:(nullable NSArray<MPMediaItem *> *)items
                  collections:(nullable NSArray<MPMediaItemCollection *> *)collections {
  if (self = [super init]) {
    _items = items;
    _collections = collections;
    _filterPredicates = [NSSet set];
  }
  return self;
}

@end

NS_ASSUME_NONNULL_END
