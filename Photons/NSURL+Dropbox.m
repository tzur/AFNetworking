// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "NSURL+Dropbox.h"

#import "NSURL+Photons.h"
#import "PTNDropboxEntry.h"

NS_ASSUME_NONNULL_BEGIN

@implementation NSURL (Dropbox)

+ (NSString *)ptn_dropboxScheme {
  return @"com.lightricks.Photons.Dropbox";
}

+ (NSURL *)ptn_dropboxAssetURLWithEntry:(PTNDropboxEntry *)entry {
  return [self ptn_urlForType:PTNDropboxURLTypeAsset andEntry:entry];
}

+ (NSURL *)ptn_dropboxAlbumURLWithEntry:(PTNDropboxEntry *)entry {
  return [self ptn_urlForType:PTNDropboxURLTypeAlbum andEntry:entry];
}

+ (NSURL *)ptn_urlForType:(PTNDropboxURLType)type andEntry:(PTNDropboxEntry *)entry {
  NSURLComponents *components = [[NSURLComponents alloc] init];

  components.scheme = [NSURL ptn_dropboxScheme];
  components.host = type == PTNDropboxURLTypeAsset ? @"asset" : @"album";
  components.queryItems = @[[NSURLQueryItem queryItemWithName:@"path" value:entry.path],
                            [NSURLQueryItem queryItemWithName:@"revision" value:entry.revision]];

  return components.URL;
}

- (nullable PTNDropboxEntry *)ptn_dropboxAlbumEntry {
  if (![self.scheme isEqual:[NSURL ptn_dropboxScheme]] || ![self.host isEqual:@"album"]) {
    return nil;
  }

  return [self ptn_dropboxEntry];
}

- (nullable PTNDropboxEntry *)ptn_dropboxAssetEntry {
  if (![self.scheme isEqual:[NSURL ptn_dropboxScheme]] || ![self.host isEqual:@"asset"]) {
    return nil;
  }

  return [self ptn_dropboxEntry];
}

- (nullable PTNDropboxEntry *)ptn_dropboxEntry {
  NSDictionary *query = self.ptn_queryDictionary;
  if (!query[@"path"]) {
    return nil;
  }

  return [PTNDropboxEntry entryWithPath:query[@"path"] andRevision:query[@"revision"]];
}

- (PTNDropboxURLType)ptn_dropboxURLType {
  if (![self.scheme isEqual:[NSURL ptn_dropboxScheme]]) {
    return PTNDropboxURLTypeInvalid;
  }

  NSDictionary *query = self.ptn_queryDictionary;
  if (!query[@"path"]) {
    return PTNDropboxURLTypeInvalid;
  }

  if ([self.host isEqual:@"asset"]) {
    return PTNDropboxURLTypeAsset;
  } else if ([self.host isEqual:@"album"]) {
    return PTNDropboxURLTypeAlbum;
  }

  return PTNDropboxURLTypeInvalid;
}

@end

NS_ASSUME_NONNULL_END
