// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "PTNPhotoKitAlbum.h"

#import <Photos/Photos.h>

#import "PTNCollection.h"

NS_ASSUME_NONNULL_BEGIN

@interface PHFetchResult () <PTNCollection>
@end

@interface PTNPhotoKitAlbum ()

/// Fetch results backing \c PHAsset objects.
@property (strong, nonatomic) PHFetchResult *assetsFetchResult;

/// Fetch results backing \c PHCollection objects.
@property (strong, nonatomic) PHFetchResult *albumsFetchResult;

@end

@implementation PTNPhotoKitAlbum

- (instancetype)initWithAssets:(PHFetchResult *)assets {
  if (self = [super init]) {
    self.assetsFetchResult = assets;
  }
  return self;
}

- (instancetype)initWithAlbums:(PHFetchResult *)albums {
  if (self = [super init]) {
    self.albumsFetchResult = albums;
  }
  return self;
}

- (id<PTNCollection>)assets {
  return self.assetsFetchResult ?: @[];
}

- (id<PTNCollection>)subalbums {
  return self.albumsFetchResult ?: @[];
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (BOOL)isEqual:(PTNPhotoKitAlbum *)object {
  if (object == self) {
    return YES;
  }
  if (![object isKindOfClass:self.class]) {
    return NO;
  }

  return [self.assets isEqual:object.assets] && [self.subalbums isEqual:object.subalbums];
}

- (NSUInteger)hash {
  return self.assetsFetchResult.hash ^ self.albumsFetchResult.hash;
}

@end

NS_ASSUME_NONNULL_END
