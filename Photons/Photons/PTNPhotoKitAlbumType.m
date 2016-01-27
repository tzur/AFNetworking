// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "PTNPhotoKitAlbumType.h"

NS_ASSUME_NONNULL_BEGIN

@implementation PTNPhotoKitAlbumType

+ (instancetype)albumTypeWithType:(PHAssetCollectionType)type
                          subtype:(PHAssetCollectionSubtype)subtype {
  PTNPhotoKitAlbumType *albumType = [[PTNPhotoKitAlbumType alloc] init];
  albumType->_type = type;
  albumType->_subtype = subtype;
  return albumType;
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (BOOL)isEqual:(PTNPhotoKitAlbumType *)object {
  if (self == object) {
    return YES;
  }
  if (![object isKindOfClass:[PTNPhotoKitAlbumType class]]) {
    return NO;
  }

  return self.type == object.type && self.subtype == object.subtype;
}

- (NSUInteger)hash {
  return [@(self.type) hash] ^ [@(self.subtype) hash];
}

#pragma mark -
#pragma mark NSCopying
#pragma mark -

- (instancetype)copyWithZone:(nullable NSZone __unused *)zone {
  return self;
}

@end

NS_ASSUME_NONNULL_END
