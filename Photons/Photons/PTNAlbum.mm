// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNAlbum.h"

#import <LTKit/LTRandomAccessCollection.h>

NS_ASSUME_NONNULL_BEGIN

@implementation PTNAlbum

@synthesize url = _url;
@synthesize subalbums = _subalbums;
@synthesize assets = _assets;
@synthesize nextAlbumURL = _nextAlbumURL;

- (instancetype)initWithURL:(NSURL *)url
                  subalbums:(id<LTRandomAccessCollection>)subalbums
                     assets:(id<LTRandomAccessCollection>)assets
               nextAlbumURL:(nullable NSURL *)nextAlbumURL {
  if (self = [super init]) {
    _url = url;
    _subalbums = subalbums;
    _assets = assets;
    _nextAlbumURL = nextAlbumURL;
  }
  return self;
}

- (instancetype)initWithURL:(NSURL *)url
                  subalbums:(id<LTRandomAccessCollection>)subalbums
                     assets:(id<LTRandomAccessCollection>)assets {
  return [self initWithURL:url subalbums:subalbums assets:assets nextAlbumURL:nil];
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (NSString *)description {
  return
      [NSString stringWithFormat:@"<%@: %p, url: %@, subalbums: %@, assets: %@ nextAlbumURL: %@>",
       self.class, self, self.url, self.subalbums, self.assets, self.nextAlbumURL];
}

- (BOOL)isEqual:(PTNAlbum *)object {
  if (object == self) {
    return YES;
  }
  if (![object isKindOfClass:self.class]) {
    return NO;
  }
  return [self.url isEqual:object.url] && [self.subalbums isEqual:object.subalbums] &&
      [self.assets isEqual:object.assets] &&
      (self.nextAlbumURL == object.nextAlbumURL || [self.nextAlbumURL isEqual:object.nextAlbumURL]);
}

- (NSUInteger)hash {
  return self.url.hash ^ self.subalbums.hash ^ self.assets.hash ^ self.nextAlbumURL.hash;
}

@end

NS_ASSUME_NONNULL_END
