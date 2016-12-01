// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "PTNPhotoKitAlbum.h"

#import <LTKit/LTRandomAccessCollection.h>
#import <Photos/Photos.h>

#import "NSURL+PhotoKit.h"

NS_ASSUME_NONNULL_BEGIN

@interface PHFetchResult () <LTRandomAccessCollection>
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
  PTNPhotoKitURLType * _Nullable type = url.ptn_photoKitURLType;
  LTParameterAssert([type isEqual:$(PTNPhotoKitURLTypeAlbum)] ||
                    [type isEqual:$(PTNPhotoKitURLTypeAlbumType)] ||
                    [type isEqual:$(PTNPhotoKitURLTypeMetaAlbumType)] ||
                    [type isEqual:$(PTNPhotoKitURLTypeMediaAlbumType)],
                    @"Invalid URL type given: %@", url.ptn_photoKitURLType);
  if (self = [super init]) {
    self.url = url;

    if ([type isEqual:$(PTNPhotoKitURLTypeMetaAlbumType)]) {
      self.albumsFetchResult = fetchResult;
    } else {
      self.assetsFetchResult = fetchResult;
    }
  }
  return self;
}

- (id<LTRandomAccessCollection>)assets {
  return self.assetsFetchResult ?: @[];
}

- (id<LTRandomAccessCollection>)subalbums {
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
