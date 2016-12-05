// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Reuven Siman Tov.

#import "PTNPhotoKitVideoAsset.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTNPhotoKitVideoAsset ()

/// \c AVAsset that this object is backed by.
@property (readonly, nonatomic) AVAsset *asset;

@end

@implementation PTNPhotoKitVideoAsset

- (instancetype)initWithAVAsset:(AVAsset *)asset {
  if (self = [super init]) {
    _asset = asset;
  }
  return self;
}

- (RACSignal *)fetchAVAsset {
  return [RACSignal return:self.asset];
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (BOOL)isEqual:(PTNPhotoKitVideoAsset *)object {
  if (object == self) {
    return YES;
  }
  if (![object isKindOfClass:self.class]) {
    return NO;
  }

  return [self.asset isEqual:object.asset];
}

- (NSUInteger)hash {
  return self.asset.hash;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@: %p, asset: %@>", self.class, self, self.asset];
}

@end

NS_ASSUME_NONNULL_END
