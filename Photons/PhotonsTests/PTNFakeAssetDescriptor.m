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
@synthesize duration = _duration;
@synthesize assetDescriptorCapabilities = _assetDescriptorCapabilities;

- (instancetype)initWithIdentifier:(NSURL *)ptn_identifier
                    localizedTitle:(nullable NSString *)localizedTitle
            descriptorCapabilities:(PTNDescriptorCapabilities)descriptorCapabilities
                  descriptorTraits:(NSSet<NSString *> *)descriptorTraits
                      creationDate:(nullable NSDate *)creationDate
                  modificationDate:(nullable NSDate *)modificationDate
       assetDescriptorCapabilities:(PTNAssetDescriptorCapabilities)assetDescriptorCapabilities {
  return [self initWithIdentifier:ptn_identifier localizedTitle:localizedTitle
           descriptorCapabilities:descriptorCapabilities descriptorTraits:descriptorTraits
                     creationDate:creationDate modificationDate:modificationDate duration:0
      assetDescriptorCapabilities:assetDescriptorCapabilities];
}

- (instancetype)initWithIdentifier:(NSURL *)ptn_identifier
                    localizedTitle:(nullable NSString *)localizedTitle
            descriptorCapabilities:(PTNDescriptorCapabilities)descriptorCapabilities
                  descriptorTraits:(NSSet<NSString *> *)descriptorTraits
                      creationDate:(nullable NSDate *)creationDate
                  modificationDate:(nullable NSDate *)modificationDate
                          duration:(NSTimeInterval)duration
       assetDescriptorCapabilities:(PTNAssetDescriptorCapabilities)assetDescriptorCapabilities {
  if (self = [super init]) {
    _ptn_identifier = ptn_identifier;
    _localizedTitle = localizedTitle;
    _descriptorCapabilities = descriptorCapabilities;
    _descriptorTraits = descriptorTraits;
    _creationDate = creationDate;
    _modificationDate = modificationDate;
    _duration = duration;
    _assetDescriptorCapabilities = assetDescriptorCapabilities;
  }
  return self;
}

@end

NS_ASSUME_NONNULL_END
