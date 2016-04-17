// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNGatewayAlbumDescriptor.h"

#import "NSURL+Gateway.h"
#import "PTNStaticImageAsset.h"

NS_ASSUME_NONNULL_BEGIN

@implementation PTNGatewayAlbumDescriptor

@synthesize ptn_identifier = _ptn_identifier;
@synthesize localizedTitle = _localizedTitle;

- (instancetype)initWithIdentifier:(NSURL *)identifier localizedTitle:(NSString *)localizedTitle
                             image:(UIImage *)image albumSignal:(RACSignal *)albumSignal {
  RACSignal *imageSignal = [RACSignal return:[[PTNStaticImageAsset alloc] initWithImage:image]];
  return [self initWithIdentifier:identifier localizedTitle:localizedTitle imageSignal:imageSignal
                      albumSignal:albumSignal];
}

- (instancetype)initWithIdentifier:(NSURL *)identifier localizedTitle:(NSString *)localizedTitle
                       imageSignal:(RACSignal *)imageSignal
                       albumSignal:(RACSignal *)albumSignal {
  LTParameterAssert([identifier.scheme isEqualToString:[NSURL ptn_gatewayScheme]], @"identifer "
                    "must be a Gateway URL: %@", identifier);
  if (self = [super init]) {
    _ptn_identifier = identifier;
    _localizedTitle = localizedTitle;
    _imageSignal = imageSignal;
    _albumSignal = albumSignal;
  }
  return self;
}

- (NSUInteger)assetCount {
  return PTNNotFound;
}

- (PTNDescriptorCapabilities)descriptorCapabilites {
  return PTNDescriptorCapabilityNone;
}

- (PTNAlbumDescriptorCapabilities)albumDescriptorCapabilites {
  return PTNAlbumDescriptorCapabilityNone;
}

@end

NS_ASSUME_NONNULL_END
