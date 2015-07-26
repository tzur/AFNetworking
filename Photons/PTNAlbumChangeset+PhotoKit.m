// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "PTNAlbumChangeset+PhotoKit.h"

#import <Photos/Photos.h>

#import "NSURL+PhotoKit.h"
#import "PTNAlbumChangesetMove.h"
#import "PTNPhotoKitAlbum.h"

NS_ASSUME_NONNULL_BEGIN

@implementation PTNAlbumChangeset (PhotoKit)

+ (instancetype)changesetWithURL:(NSURL *)url photoKitFetchResult:(PHFetchResult *)fetchResult {
  id<PTNAlbum> afterAlbum = [[PTNPhotoKitAlbum alloc] initWithURL:url fetchResult:fetchResult];
  return [PTNAlbumChangeset changesetWithAfterAlbum:afterAlbum];
}

+ (instancetype)changesetWithURL:(NSURL *)url
           photoKitChangeDetails:(PHFetchResultChangeDetails *)changeDetails {
  id<PTNAlbum> beforeAlbum = [[PTNPhotoKitAlbum alloc]
                              initWithURL:url fetchResult:changeDetails.fetchResultBeforeChanges];
  id<PTNAlbum> afterAlbum = [[PTNPhotoKitAlbum alloc]
                             initWithURL:url fetchResult:changeDetails.fetchResultAfterChanges];
  NSArray *moves = [self movesFromChangeDetails:changeDetails];

  return [PTNAlbumChangeset changesetWithBeforeAlbum:beforeAlbum afterAlbum:afterAlbum
                                      removedIndexes:changeDetails.removedIndexes
                                     insertedIndexes:changeDetails.insertedIndexes
                                      updatedIndexes:changeDetails.changedIndexes moves:moves];
}

+ (NSArray *)movesFromChangeDetails:(PHFetchResultChangeDetails *)changeDetails {
  NSMutableArray *moves = [NSMutableArray array];
  [changeDetails enumerateMovesWithBlock:^(NSUInteger fromIndex, NSUInteger toIndex) {
    PTNAlbumChangesetMove *move = [PTNAlbumChangesetMove changesetMoveFrom:fromIndex to:toIndex];
    [moves addObject:move];
  }];
  return [moves copy];
}

@end

NS_ASSUME_NONNULL_END
