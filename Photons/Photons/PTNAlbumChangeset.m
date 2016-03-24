// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "PTNAlbumChangeset.h"

#import "PTNAlbum.h"
#import "PTNIncrementalChanges.h"

NS_ASSUME_NONNULL_BEGIN

@implementation PTNAlbumChangeset

+ (instancetype)changesetWithAfterAlbum:(id<PTNAlbum>)afterAlbum {
  PTNAlbumChangeset *changeset = [[PTNAlbumChangeset alloc] init];
  changeset->_afterAlbum = afterAlbum;
  return changeset;
}

+ (instancetype)changesetWithBeforeAlbum:(nullable id<PTNAlbum>)beforeAlbum
                              afterAlbum:(id<PTNAlbum>)afterAlbum
                         subalbumChanges:(nullable PTNIncrementalChanges *)subalbumChanges
                            assetChanges:(nullable PTNIncrementalChanges *)assetChanges {
  PTNAlbumChangeset *changeset = [[PTNAlbumChangeset alloc] init];
  changeset->_beforeAlbum = beforeAlbum;
  changeset->_afterAlbum = afterAlbum;
  changeset->_subalbumChanges = subalbumChanges;
  changeset->_assetChanges = assetChanges;
  return changeset;
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (BOOL)isEqual:(PTNAlbumChangeset *)object {
  if (object == self) {
    return YES;
  }
  if (![object isKindOfClass:self.class]) {
    return NO;
  }

  return [self compare:self.beforeAlbum with:object.beforeAlbum] &&
      [self compare:self.afterAlbum with:object.afterAlbum] &&
      [self compare:self.subalbumChanges with:object.subalbumChanges] &&
      [self compare:self.assetChanges with:object.assetChanges];
}

- (BOOL)compare:(nullable id)first with:(nullable id)second {
  return first == second || [first isEqual:second];
}

- (NSUInteger)hash {
  return [self.beforeAlbum hash] ^ [self.afterAlbum hash] ^ [self.subalbumChanges hash] ^
      [self.assetChanges hash];
}

- (NSString *)description {
  if (self.beforeAlbum) {
    return [NSString stringWithFormat:@"<%@: %p, before: %@, after: %@, subalbum changes: %@, "
            "asset changes: %@>", self.class, self, self.beforeAlbum, self.afterAlbum,
            self.subalbumChanges, self.assetChanges];
  } else {
    return [NSString stringWithFormat:@"<%@: %p, album: %@>", self.class, self, self.afterAlbum];
  }
}

@end

NS_ASSUME_NONNULL_END
