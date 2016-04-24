// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNAlbum.h"

#import "PTNCollection.h"

NS_ASSUME_NONNULL_BEGIN

@implementation PTNAlbum

@synthesize url = _url;
@synthesize subalbums = _subalbums;
@synthesize assets = _assets;

- (instancetype)initWithURL:(NSURL *)url
                  subalbums:(NSArray<id<PTNAlbumDescriptor>> *)subalbums
                     assets:(NSArray<id<PTNAssetDescriptor>> *)assets {
  if (self = [super init]) {
    _url = url;
    _subalbums = subalbums;
    _assets = assets;
  }
  return self;
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@: %p, url: %@, subalbums: %@, assets: %@>",
          self.class, self, self.url, self.subalbums, self.assets];
}

- (BOOL)isEqual:(PTNAlbum *)object {
  if (object == self) {
    return YES;
  }
  if (![object isKindOfClass:self.class]) {
    return NO;
  }

  return [self.url isEqual:object.url] && [self.subalbums isEqual:object.subalbums] &&
      [self.assets isEqual:object.assets];
}

- (NSUInteger)hash {
  return self.url.hash ^ self.subalbums.hash ^ self.assets.hash;
}

@end

NS_ASSUME_NONNULL_END
