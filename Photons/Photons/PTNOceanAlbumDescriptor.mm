// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

#import "PTNOceanAlbumDescriptor.h"

#import "NSURL+Ocean.h"

NS_ASSUME_NONNULL_BEGIN

@implementation PTNOceanAlbumDescriptor

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithAlbumURL:(NSURL *)albumURL {
  LTParameterAssert([albumURL.ptn_oceanURLType isEqual:$(PTNOceanURLTypeAlbum)],
                    @"Provided URL must be of type PTNOceanURLTypeAlbum, got: %@",
                    albumURL.ptn_oceanURLType.name);

  if (self = [super init]) {
    _ptn_identifier = albumURL;
  }
  return self;
}

#pragma mark -
#pragma mark PTNAlbumDescriptor
#pragma mark -

@synthesize ptn_identifier = _ptn_identifier;

- (nullable NSString *)localizedTitle {
  return nil;
}

- (PTNDescriptorCapabilities)descriptorCapabilities {
  return PTNDescriptorCapabilityNone;
}

- (NSSet<NSString *> *)descriptorTraits {
  return [NSSet set];
}

- (NSUInteger)assetCount {
  return PTNNotFound;
}

- (PTNAlbumDescriptorCapabilities)albumDescriptorCapabilities {
  return PTNAlbumDescriptorCapabilityNone;
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (BOOL)isEqual:(PTNOceanAlbumDescriptor *)object {
  if (self == object) {
    return YES;
  }
  if (![object isKindOfClass:[self class]]) {
    return NO;
  }
  return [self.ptn_identifier isEqual:object.ptn_identifier];
}

- (NSUInteger)hash {
  return self.ptn_identifier.hash;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@: %@>", [self class], self.ptn_identifier];
}

@end

NS_ASSUME_NONNULL_END
