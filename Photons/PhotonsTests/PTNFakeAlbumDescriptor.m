// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNFakeAlbumDescriptor.h"

NS_ASSUME_NONNULL_BEGIN

@implementation PTNFakeAlbumDescriptor

@synthesize ptn_identifier = _ptn_identifier;
@synthesize localizedTitle = _localizedTitle;
@synthesize descriptorCapabilities = _descriptorCapabilities;
@synthesize descriptorTraits = _descriptorTraits;
@synthesize assetCount = _assetCount;
@synthesize albumDescriptorCapabilities = _albumDescriptorCapabilities;

- (instancetype)initWithIdentifier:(NSURL *)ptn_identifier
                    localizedTitle:(nullable NSString *)localizedTitle
            descriptorCapabilities:(PTNDescriptorCapabilities)descriptorCapabilities
                  descriptorTraits:(NSSet<NSString *> *)descriptorTraits
                        assetCount:(NSUInteger)assetCount
       albumDescriptorCapabilities:(PTNAlbumDescriptorCapabilities)albumDescriptorCapabilities {
  if (self = [super init]) {
    _ptn_identifier = ptn_identifier;
    _localizedTitle = localizedTitle;
    _descriptorCapabilities = descriptorCapabilities;
    _descriptorTraits = descriptorTraits;
    _assetCount = assetCount;
    _albumDescriptorCapabilities = albumDescriptorCapabilities;
  }
  return self;
}

@end

NS_ASSUME_NONNULL_END
