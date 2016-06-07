// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNFakeDescriptor.h"

NS_ASSUME_NONNULL_BEGIN

@implementation PTNFakeDescriptor

@synthesize ptn_identifier = _ptn_identifier;
@synthesize localizedTitle = _localizedTitle;
@synthesize descriptorCapabilities = _descriptorCapabilities;

- (instancetype)initWithIdentifier:(NSURL *)ptn_identifier localizedTitle:(NSString *)localizedTitle
            descriptorCapabilities:(PTNDescriptorCapabilities)descriptorCapabilities {
  if (self = [super init]) {
    _ptn_identifier = ptn_identifier;
    _localizedTitle = localizedTitle;
    _descriptorCapabilities = descriptorCapabilities;
  }
  return self;
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@: %p, identifier: %@, title: %@, capabilities: %lu>",
          self.class, self, self.ptn_identifier, self.localizedTitle,
          (unsigned long)self.descriptorCapabilities];
}

- (BOOL)isEqual:(PTNFakeDescriptor *)object {
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
      self.descriptorCapabilities == object.descriptorCapabilities;
}

- (NSUInteger)hash {
  return self.ptn_identifier.hash ^ self.localizedTitle.hash ^ self.descriptorCapabilities;
}

@end

NS_ASSUME_NONNULL_END
