// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNFakeAssetDescriptor.h"

NS_ASSUME_NONNULL_BEGIN

@implementation PTNFakeAssetDescriptor

@synthesize ptn_identifier = _ptn_identifier;
@synthesize localizedTitle = _localizedTitle;
@synthesize descriptorCapabilities = _descriptorCapabilities;
@synthesize creationDate = _creationDate;
@synthesize modificationDate = _modificationDate;
@synthesize assetDescriptorCapabilities = _assetDescriptorCapabilities;

- (instancetype)initWithIdentifier:(NSURL *)ptn_identifier localizedTitle:(NSString *)localizedTitle
            descriptorCapabilities:(PTNDescriptorCapabilities)descriptorCapabilities
                      creationDate:(nullable NSDate *)creationDate
                  modificationDate:(nullable NSDate *)modificationDate
       assetDescriptorCapabilities:(PTNAssetDescriptorCapabilities)assetDescriptorCapabilities {
  if (self = [super init]) {
    _ptn_identifier = ptn_identifier;
    _localizedTitle = localizedTitle;
    _descriptorCapabilities = descriptorCapabilities;
    _creationDate = creationDate;
    _modificationDate = modificationDate;
    _assetDescriptorCapabilities = assetDescriptorCapabilities;
  }
  return self;
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@: %p, identifier: %@, title: %@, capabilities: %lu, "
          "creation date: %@, modification date: %@, asset capabilities: %lu>", self.class, self,
          self.ptn_identifier, self.localizedTitle, (unsigned long)self.descriptorCapabilities,
          self.creationDate, self.modificationDate,
          (unsigned long)self.assetDescriptorCapabilities];
}

- (BOOL)isEqual:(PTNFakeAssetDescriptor *)object {
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
      (self.creationDate == object.creationDate ||
      [self.creationDate isEqual:object.creationDate]) &&
      (self.modificationDate == object.modificationDate ||
      [self.modificationDate isEqual:object.modificationDate]) &&
      self.assetDescriptorCapabilities == object.assetDescriptorCapabilities;
}

- (NSUInteger)hash {
  return self.ptn_identifier.hash ^ self.localizedTitle.hash ^ self.descriptorCapabilities ^
      self.creationDate.hash ^ self.modificationDate.hash ^ self.assetDescriptorCapabilities;
}

@end

NS_ASSUME_NONNULL_END
