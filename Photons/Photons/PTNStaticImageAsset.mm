// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNStaticImageAsset.h"

#import "PTNImageMetadata.h"

NS_ASSUME_NONNULL_BEGIN

@implementation PTNStaticImageAsset

- (instancetype)initWithImage:(UIImage *)image {
  return [self initWithImage:image imageMetadata:nil];
}

- (instancetype)initWithImage:(UIImage *)image
                imageMetadata:(nullable PTNImageMetadata *)imageMetadata {
  if (self = [super init]) {
    _image = image;
    _imageMetadata = imageMetadata ?: [[PTNImageMetadata alloc] init];
  }
  return self;
}

#pragma mark -
#pragma mark PTNImageAsset
#pragma mark -

- (RACSignal *)fetchImage {
  return [RACSignal return:self.image];
}

- (RACSignal *)fetchImageMetadata {
  return [RACSignal return:self.imageMetadata];
}

@end

NS_ASSUME_NONNULL_END
