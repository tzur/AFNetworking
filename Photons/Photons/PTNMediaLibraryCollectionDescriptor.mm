// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Michael Kimyagarov.

#import "PTNMediaLibraryCollectionDescriptor.h"

#import <MediaPlayer/MediaPlayer.h>

#import "NSURL+MediaLibrary.h"

NS_ASSUME_NONNULL_BEGIN

@implementation PTNMediaLibraryCollectionDescriptor

#pragma mark -
#pragma mark Initalization
#pragma mark -

- (instancetype)initWithCollection:(MPMediaItemCollection *)collection url:(NSURL *)url {
  LTParameterAssert(url.ptn_mediaLibraryURLType == PTNMediaLibraryURLTypeAlbum, @"%@ type must be "
                    "PTNMediaLibraryURLTypeAlbum is not supported.", url);
  if (self = [super init]) {
    _collection = collection;
    _url = url;
  }
  return self;
}

#pragma mark -
#pragma mark PTNAlbumDescriptor
#pragma mark -

- (NSUInteger)assetCount {
  return self.collection.count;
}

- (PTNAlbumDescriptorCapabilities)albumDescriptorCapabilities {
  return PTNAlbumDescriptorCapabilityNone;
}

#pragma mark -
#pragma mark PTNDescriptor
#pragma mark -

- (NSURL *)ptn_identifier {
  return self.url;
}

- (nullable NSString *)localizedTitle {
  if ([self.url ptn_valuesForPredicate:MPMediaItemPropertyArtistPersistentID].count) {
    return self.collection.representativeItem.artist;
  }
  return self.collection.representativeItem.albumTitle;
}

- (PTNDescriptorCapabilities)descriptorCapabilities {
  return PTNDescriptorCapabilityNone;
}

- (NSSet<NSString *> *)descriptorTraits {
  return [NSSet set];
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (BOOL)isEqual:(PTNMediaLibraryCollectionDescriptor *)object {
  if (object == self) {
    return YES;
  }
  if (![object isKindOfClass:self.class]) {
    return NO;
  }

  return [self compare:self.url with:object.url] &&
      [self compare:self.collection with:object.collection];
}

- (BOOL)compare:(nullable id)first with:(nullable id)second {
  return first == second || [first isEqual:second];
}

- (NSUInteger)hash {
  return [self.url hash] ^ [self.collection hash];
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@: %p, url: %@, collection: %@>", self.class, self,
          self.url, self.collection];
}

@end

NS_ASSUME_NONNULL_END
