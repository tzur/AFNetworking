// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "DVNBrushRenderTargetInformation.h"

NS_ASSUME_NONNULL_BEGIN

@implementation DVNBrushRenderTargetInformation

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithRenderTargetLocation:(lt::Quad)renderTargetLocation
                renderTargetHasSingleChannel:(BOOL)renderTargetHasSingleChannel {
  if (self = [super init]) {
    _renderTargetLocation = renderTargetLocation;
    _renderTargetHasSingleChannel = renderTargetHasSingleChannel;
  }
  return self;
}

+ (instancetype)instanceWithRenderTargetLocation:(lt::Quad)renderTargetLocation
                    renderTargetHasSingleChannel:(BOOL)renderTargetHasSingleChannel {
  return [[self alloc] initWithRenderTargetLocation:renderTargetLocation
                       renderTargetHasSingleChannel:renderTargetHasSingleChannel];
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@: %p, render target location: %@, render target has "
          "single channel: %@>", self.class, self, NSStringFromLTQuad(self.renderTargetLocation),
          self.renderTargetHasSingleChannel ? @"YES" : @"NO"];
}

- (BOOL)isEqual:(DVNBrushRenderTargetInformation *)information {
  if (information == self) {
    return YES;
  }

  if (![information isKindOfClass:[DVNBrushRenderTargetInformation class]]) {
    return NO;
  }

  return self.renderTargetLocation == information.renderTargetLocation &&
      self.renderTargetHasSingleChannel == information.renderTargetHasSingleChannel;
}

- (NSUInteger)hash {
  size_t seed = 0;
  lt::hash_combine(seed, std::hash<lt::Quad>()(self.renderTargetLocation));
  lt::hash_combine(seed, self.renderTargetHasSingleChannel);
  return seed;
}

@end

NS_ASSUME_NONNULL_END
