// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNCacheAlbum.h"

#import "PTNCacheInfo.h"

NS_ASSUME_NONNULL_BEGIN

@implementation PTNCacheAlbum

@synthesize underlyingAlbum = _underlyingAlbum;
@synthesize cacheInfo = _cacheInfo;

- (instancetype)initWithUnderlyingAlbum:(id<PTNAlbum>)underlyingAlbum
                              cacheInfo:(PTNCacheInfo *)cacheInfo {
  if (self = [super init]) {
    _underlyingAlbum = underlyingAlbum;
    _cacheInfo = cacheInfo;
  }
  return self;
}

+ (instancetype)cacheAlbumWithUnderlyingAlbum:(id<PTNAlbum>)underlyingAlbum
                                    cacheInfo:(PTNCacheInfo *)cacheInfo {
  return [[PTNCacheAlbum alloc] initWithUnderlyingAlbum:underlyingAlbum cacheInfo:cacheInfo];
}

#pragma mark -
#pragma mark PTNAlbum
#pragma mark -

- (NSURL *)url {
  return self.underlyingAlbum.url;
}

- (id<PTNCollection>)subalbums {
  return self.underlyingAlbum.subalbums;
}

- (id<PTNCollection>)assets {
  return self.underlyingAlbum.assets;
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@: %p, underlying album: %@, cache info: %@>",
          self.class, self, self.underlyingAlbum, self.cacheInfo];
}

- (BOOL)isEqual:(PTNCacheAlbum *)object {
  if (object == self) {
    return YES;
  }
  if (![object isKindOfClass:self.class]) {
    return NO;
  }

  return [self.underlyingAlbum isEqual:object.underlyingAlbum] &&
      [self.cacheInfo isEqual:object.cacheInfo];
}

- (NSUInteger)hash {
  return self.underlyingAlbum.hash ^ self.cacheInfo.hash;
}

@end

NS_ASSUME_NONNULL_END
