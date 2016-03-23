// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "PTNPhotoKitAlbum.h"

#import <Photos/Photos.h>

#import "NSURL+PhotoKit.h"
#import "PTNCollection.h"

NS_ASSUME_NONNULL_BEGIN

@interface PHFetchResult () <PTNCollection>
@end

@interface PTNPhotoKitAlbum ()

/// URL uniquely identifying this album.
@property (strong, nonatomic) NSURL *url;

/// Fetch results backing \c PHAsset objects.
@property (strong, nonatomic) PHFetchResult<PHAsset *> *assetsFetchResult;

/// Fetch results backing \c PHCollection objects.
@property (strong, nonatomic) PHFetchResult<PHCollection *> *albumsFetchResult;

@end

@implementation PTNPhotoKitAlbum

- (instancetype)initWithURL:(NSURL *)url fetchResult:(PHFetchResult *)fetchResult {
  LTParameterAssert(url.ptn_photoKitURLType == PTNPhotoKitURLTypeAlbum ||
                    url.ptn_photoKitURLType == PTNPhotoKitURLTypeAlbumType ||
                    url.ptn_photoKitURLType == PTNPhotoKitURLTypeAlbumOfAlbumsType,
                    @"Invalid URL type given: %lu", (unsigned long)url.ptn_photoKitURLType);
  if (self = [super init]) {
    self.url = url;

    if (url.ptn_photoKitURLType == PTNPhotoKitURLTypeAlbumOfAlbumsType) {
      self.albumsFetchResult = fetchResult;
    } else {
      self.assetsFetchResult = fetchResult;
    }
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
