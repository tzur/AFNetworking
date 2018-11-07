// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNGatewayAlbumDescriptor.h"

#import <LTKit/LTProgress.h>

#import "NSURL+Gateway.h"
#import "PTNStaticImageAsset.h"

NS_ASSUME_NONNULL_BEGIN

@implementation PTNGatewayAlbumDescriptor

@synthesize ptn_identifier = _ptn_identifier;
@synthesize localizedTitle = _localizedTitle;

- (instancetype)initWithIdentifier:(NSURL *)identifier localizedTitle:(NSString *)localizedTitle
                             image:(UIImage *)image albumSignal:(RACSignal *)albumSignal {
  id<PTNImageAsset> asset = [[PTNStaticImageAsset alloc] initWithImage:image];
  LTProgress *progress = [[LTProgress alloc] initWithResult:asset];
  RACSignal *imageSignal = [RACSignal return:progress];
  return [self initWithIdentifier:identifier localizedTitle:localizedTitle imageSignal:imageSignal
                      albumSignal:albumSignal];
}

- (instancetype)initWithIdentifier:(NSURL *)identifier localizedTitle:(NSString *)localizedTitle
                       imageSignal:(RACSignal *)imageSignal
                       albumSignal:(RACSignal *)albumSignal {
  return [self initWithIdentifier:identifier localizedTitle:localizedTitle
                 imageSignalBlock:^RACSignal *(id<PTNResizingStrategy>, PTNImageFetchOptions *) {
                   return imageSignal;
                 } albumSignal:albumSignal];
}

- (instancetype)initWithIdentifier:(NSURL *)identifier localizedTitle:(NSString *)localizedTitle
                  imageSignalBlock:(PTNGatewayImageSignalBlock)imageSignalBlock
                       albumSignal:(RACSignal *)albumSignal {
  LTParameterAssert([identifier.scheme isEqualToString:[NSURL ptn_gatewayScheme]], @"identifer "
                    "must be a Gateway URL: %@", identifier);
  LTParameterAssert(imageSignalBlock, @"No image signal block given");
  if (self = [super init]) {
    _ptn_identifier = identifier;
    _localizedTitle = localizedTitle;
    _imageSignalBlock = [imageSignalBlock copy];
    _albumSignal = albumSignal;
  }
  return self;
}

- (NSUInteger)assetCount {
  return PTNNotFound;
}

- (PTNDescriptorCapabilities)descriptorCapabilities {
  return PTNDescriptorCapabilityNone;
}

- (PTNAlbumDescriptorCapabilities)albumDescriptorCapabilities {
  return PTNAlbumDescriptorCapabilityNone;
}

- (NSSet<NSString *> *)descriptorTraits {
  return [NSSet set];
}

@end

NS_ASSUME_NONNULL_END
