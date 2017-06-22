// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Michael Kimyagarov.

#import "MPMediaItemCollection+Photons.h"

#import "NSURL+MediaLibrary.h"

NS_ASSUME_NONNULL_BEGIN

@implementation MPMediaItemCollection (Photons)

#pragma mark -
#pragma mark PTNAlbumDescriptor
#pragma mark -

- (NSUInteger)assetCount {
  return self.count;
}

- (PTNAlbumDescriptorCapabilities)albumDescriptorCapabilities {
  return PTNAlbumDescriptorCapabilityNone;
}

#pragma mark -
#pragma mark PTNDescriptor
#pragma mark -

- (NSURL *)ptn_identifier {
  return [NSURL ptn_mediaLibraryAlbumURLWithCollection:self];
}

- (nullable NSString *)localizedTitle {
  // note MPMediaItemCollection is always grouped by album, but in future this might change.
  return self.representativeItem.albumTitle;
}

- (PTNDescriptorCapabilities)descriptorCapabilities {
  return PTNDescriptorCapabilityNone;
}

- (NSSet<NSString *> *)descriptorTraits {
  return [NSSet set];
}

@end

NS_ASSUME_NONNULL_END
