// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNStaticImageAsset.h"

#import "PTNImageMetadata.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTNStaticImageAsset ()

/// Image backing this image asset.
@property (readonly, nonatomic) UIImage *image;

@end

@implementation PTNStaticImageAsset

- (instancetype)initWithImage:(UIImage *)image {
  if (self = [super init]) {
    _image = image;
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
  return [RACSignal return:[[PTNImageMetadata alloc] init]];
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (BOOL)isEqual:(PTNStaticImageAsset *)object {
  if (object == self) {
    return YES;
  }
  if (![object isKindOfClass:self.class]) {
    return NO;
  }

  return [self.image isEqual:object.image];
}

- (NSUInteger)hash {
  return self.image.hash;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@: %p, image: %@>", self.class, self, self.image];
}

@end

NS_ASSUME_NONNULL_END
