// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNFakeAssetDescriptor.h"

NS_ASSUME_NONNULL_BEGIN

@implementation PTNFakeAssetDescriptor

@synthesize ptn_identifier = _ptn_identifier;
@synthesize localizedTitle = _localizedTitle;
@synthesize descriptorCapabilities = _descriptorCapabilities;
@synthesize descriptorTraits = _descriptorTraits;
@synthesize creationDate = _creationDate;
@synthesize modificationDate = _modificationDate;
@synthesize filename = _filename;
@synthesize duration = _duration;
@synthesize assetDescriptorCapabilities = _assetDescriptorCapabilities;
@synthesize artist = _artist;

- (instancetype)initWithIdentifier:(NSURL *)ptn_identifier
                    localizedTitle:(nullable NSString *)localizedTitle
            descriptorCapabilities:(PTNDescriptorCapabilities)descriptorCapabilities
                  descriptorTraits:(NSSet<NSString *> *)descriptorTraits
                      creationDate:(nullable NSDate *)creationDate
                  modificationDate:(nullable NSDate *)modificationDate
                          filename:(nullable NSString *)filename
       assetDescriptorCapabilities:(PTNAssetDescriptorCapabilities)assetDescriptorCapabilities
                            artist:(nullable NSString *)artist {
  return [self initWithIdentifier:ptn_identifier localizedTitle:localizedTitle
           descriptorCapabilities:descriptorCapabilities descriptorTraits:descriptorTraits
                     creationDate:creationDate modificationDate:modificationDate filename:filename
                         duration:0 assetDescriptorCapabilities:assetDescriptorCapabilities
                           artist:artist];
}

- (instancetype)initWithIdentifier:(NSURL *)ptn_identifier
                    localizedTitle:(nullable NSString *)localizedTitle
            descriptorCapabilities:(PTNDescriptorCapabilities)descriptorCapabilities
                  descriptorTraits:(NSSet<NSString *> *)descriptorTraits
                      creationDate:(nullable NSDate *)creationDate
                  modificationDate:(nullable NSDate *)modificationDate
                          filename:(nullable NSString *)filename
                          duration:(NSTimeInterval)duration
       assetDescriptorCapabilities:(PTNAssetDescriptorCapabilities)assetDescriptorCapabilities
                            artist:(nullable NSString *)artist {
  if (self = [super init]) {
    _ptn_identifier = ptn_identifier;
    _localizedTitle = localizedTitle;
    _descriptorCapabilities = descriptorCapabilities;
    _descriptorTraits = descriptorTraits;
    _creationDate = creationDate;
    _modificationDate = modificationDate;
    _filename = filename;
    _duration = duration;
    _assetDescriptorCapabilities = assetDescriptorCapabilities;
    _artist = artist;
  }
  return self;
}

@end

NS_ASSUME_NONNULL_END
