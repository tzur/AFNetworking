// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNCacheImageAsset.h"

#import "PTNCacheInfo.h"

NS_ASSUME_NONNULL_BEGIN

@implementation PTNCacheImageAsset

@synthesize underlyingAsset = _underlyingAsset;
@synthesize cacheInfo = _cacheInfo;

- (instancetype)initWithUnderlyingAsset:(id<PTNImageAsset, PTNDataAsset>)underlyingAsset
                              cacheInfo:(PTNCacheInfo *)cacheInfo {
  if (self = [super init]) {
    _underlyingAsset = underlyingAsset;
    _cacheInfo = cacheInfo;
  }
  return self;
}

+ (instancetype)imageAssetWithUnderlyingAsset:(id<PTNImageAsset, PTNDataAsset>)underlyingAsset
                                    cacheInfo:(PTNCacheInfo *)cacheInfo {
  return [[PTNCacheImageAsset alloc] initWithUnderlyingAsset:underlyingAsset cacheInfo:cacheInfo];
}

#pragma mark -
#pragma mark PTNImageAsset
#pragma mark -

- (RACSignal *)fetchImage {
  return [self.underlyingAsset fetchImage];
}

- (RACSignal *)fetchImageMetadata {
  return [self.underlyingAsset fetchImageMetadata];
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@: %p, underlying asset: %@, cache info: %@>",
          self.class, self, self.underlyingAsset, self.cacheInfo];
}

- (BOOL)isEqual:(PTNCacheImageAsset *)object {
  if (object == self) {
    return YES;
  }
  if (![object isKindOfClass:self.class]) {
    return NO;
  }

  return [self.underlyingAsset isEqual:object.underlyingAsset] &&
      [self.cacheInfo isEqual:object.cacheInfo];
}

- (NSUInteger)hash {
  return self.underlyingAsset.hash ^ self.cacheInfo.hash;
}

@end

NS_ASSUME_NONNULL_END
