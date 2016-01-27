// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNImageContainer.h"

#import "PTNImageMetadata.h"

NS_ASSUME_NONNULL_BEGIN

@implementation PTNImageContainer

- (instancetype)initWithImage:(UIImage *)image {
  return [self initWithImage:image metadata:nil];
}

- (instancetype)initWithImage:(UIImage *)image metadata:(nullable PTNImageMetadata *)metadata {
  if (self = [super init]) {
    _image = image;
    _metadata = metadata;
  }
  return self;
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (BOOL)isEqual:(PTNImageContainer *)object {
  if (object == self) {
    return YES;
  }
  if (![object isKindOfClass:self.class]) {
    return NO;
  }

  return (self.image == object.image || [self.image isEqual:object.image]) &&
      (self.metadata == object.metadata || [self.metadata isEqual:object.metadata]);
}

- (NSUInteger)hash {
  return self.image.hash ^ self.metadata.hash;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@: %p, image: %@, metadata: %@>", self.class, self,
      self.image, self.metadata];
}

@end

NS_ASSUME_NONNULL_END
