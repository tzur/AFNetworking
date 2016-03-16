// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNGatewayAlbumDescriptor.h"

#import "NSURL+Gateway.h"

NS_ASSUME_NONNULL_BEGIN

@implementation PTNGatewayAlbumDescriptor

@synthesize ptn_identifier = _ptn_identifier;
@synthesize localizedTitle = _localizedTitle;

- (instancetype)initWithIdentifier:(NSURL *)identifier localizedTitle:(NSString *)localizedTitle
                             image:(UIImage *)image albumSignal:(RACSignal *)albumSignal {
  LTParameterAssert([identifier.scheme isEqualToString:[NSURL ptn_gatewayScheme]], @"identifer "
                    "must be a Gateway URL: %@", identifier);
  if (self = [super init]) {
    _ptn_identifier = identifier;
    _localizedTitle = localizedTitle;
    _image = image;
    _albumSignal = albumSignal;
  }
  return self;
}

- (NSUInteger)assetCount {
  return PTNNotFound;
}

@end

NS_ASSUME_NONNULL_END
