// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Reuven Siman Tov.

#import "PTNAudiovisualAsset.h"

#import <AVFoundation/AVAsset.h>

NS_ASSUME_NONNULL_BEGIN

@interface PTNAudiovisualAsset ()

/// \c AVAsset that this object is backed by.
@property (readonly, nonatomic) AVAsset *asset;

@end

@implementation PTNAudiovisualAsset

- (instancetype)initWithAVAsset:(AVAsset *)asset {
  if (self = [super init]) {
    _asset = asset;
  }
  return self;
}

- (RACSignal<AVAsset *> *)fetchAVAsset {
  return [RACSignal return:self.asset];
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (BOOL)isEqual:(PTNAudiovisualAsset *)object {
  if (object == self) {
    return YES;
  }
  if (![object isKindOfClass:self.class]) {
    return NO;
  }

  if ([self.asset isKindOfClass:AVURLAsset.class] &&
      [object.asset isKindOfClass:AVURLAsset.class]) {
    return [((AVURLAsset *)self.asset).URL isEqual:((AVURLAsset *)object.asset).URL];
  }

  return [self.asset isEqual:object.asset];
}

- (NSUInteger)hash {
  return [self.asset isKindOfClass:AVURLAsset.class] ? ((AVURLAsset *)self.asset).URL.hash :
      self.asset.hash;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@: %p, asset: %@>", self.class, self, self.asset];
}

@end

NS_ASSUME_NONNULL_END
