// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNFakeAlbumDescriptor.h"

NS_ASSUME_NONNULL_BEGIN

@implementation PTNFakeAlbumDescriptor

@synthesize ptn_identifier = _ptn_identifier;
@synthesize localizedTitle = _localizedTitle;
@synthesize descriptorCapabilities = _descriptorCapabilities;
@synthesize assetCount = _assetCount;
@synthesize albumDescriptorCapabilities = _albumDescriptorCapabilities;

- (instancetype)initWithIdentifier:(NSURL *)ptn_identifier localizedTitle:(NSString *)localizedTitle
            descriptorCapabilities:(PTNDescriptorCapabilities)descriptorCapabilities
                        assetCount:(NSUInteger)assetCount
       albumDescriptorCapabilities:(PTNAlbumDescriptorCapabilities)albumDescriptorCapabilities {
  if (self = [super init]) {
    _ptn_identifier = ptn_identifier;
    _localizedTitle = localizedTitle;
    _descriptorCapabilities = descriptorCapabilities;
    _assetCount = assetCount;
    _albumDescriptorCapabilities = albumDescriptorCapabilities;
  }
  return self;
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@: %p, identifier: %@, title: %@, capabilities: %lu, "
          "asset count: %lu, album capabilities: %lu>", self.class, self,
          self.ptn_identifier, self.localizedTitle, (unsigned long)self.descriptorCapabilities,
          (unsigned long)self.assetCount, (unsigned long)self.albumDescriptorCapabilities];
}

- (BOOL)isEqual:(PTNFakeAlbumDescriptor *)object {
  if (object == self) {
    return YES;
  }
  if (![object isKindOfClass:self.class]) {
    return NO;
  }

  return (self.ptn_identifier == object.ptn_identifier ||
      [self.ptn_identifier isEqual:object.ptn_identifier]) &&
      (self.localizedTitle == object.localizedTitle ||
      [self.localizedTitle isEqual:object.localizedTitle]) &&
      self.descriptorCapabilities == object.descriptorCapabilities &&
      self.assetCount == object.assetCount &&
      self.albumDescriptorCapabilities == object.albumDescriptorCapabilities;
}

- (NSUInteger)hash {
  return self.ptn_identifier.hash ^ self.localizedTitle.hash ^ self.descriptorCapabilities ^
      self.assetCount ^ self.albumDescriptorCapabilities;
}

@end

NS_ASSUME_NONNULL_END
