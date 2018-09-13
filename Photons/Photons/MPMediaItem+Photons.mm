// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Michael Kimyagarov.

#import "MPMediaItem+Photons.h"

#import <LTKit/NSArray+NSSet.h>

#import "NSURL+MediaLibrary.h"

NS_ASSUME_NONNULL_BEGIN

@implementation MPMediaItem (Photons)

#pragma mark -
#pragma mark PTNDescriptor
#pragma mark -

- (NSURL *)ptn_identifier {
  return [NSURL ptn_mediaLibraryAssetWithItem:self];
}

- (nullable NSString *)localizedTitle {
  return self.title;
}

- (PTNDescriptorCapabilities)descriptorCapabilities {
  return PTNDescriptorCapabilityNone;
}

- (NSSet<NSString *> *)descriptorTraits {
  if (self.isCloudItem) {
    return [@[kPTNDescriptorTraitCloudBasedKey, kPTNDescriptorTraitAudiovisualKey] lt_set];
  }
  return [NSSet setWithObject:kPTNDescriptorTraitAudiovisualKey];
}

#pragma mark -
#pragma mark PTNAssetDescriptor
#pragma mark -

- (nullable NSDate *)creationDate {
  return self.dateAdded;
}

- (nullable NSDate *)modificationDate {
  // MPMediaItem is immutable.
  return nil;
}

- (nullable NSString *)filename {
  // MPMediaItem is not backed by a concrete file.
  return nil;
}

- (NSTimeInterval)duration {
  return self.playbackDuration;
}

- (PTNAssetDescriptorCapabilities)assetDescriptorCapabilities {
  return PTNAssetDescriptorCapabilityNone;
}

@end

NS_ASSUME_NONNULL_END
