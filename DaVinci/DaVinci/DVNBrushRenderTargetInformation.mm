// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "DVNBrushRenderTargetInformation.h"

NS_ASSUME_NONNULL_BEGIN

@implementation DVNBrushRenderTargetInformation

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithRenderTargetLocation:(lt::Quad)renderTargetLocation
                renderTargetHasSingleChannel:(BOOL)renderTargetHasSingleChannel
              renderTargetIsNonPremultiplied:(BOOL)renderTargetIsNonPremultiplied
                renderTargetHasBytePrecision:(BOOL)renderTargetHasBytePrecision {
  if (self = [super init]) {
    _renderTargetLocation = renderTargetLocation;
    _renderTargetHasSingleChannel = renderTargetHasSingleChannel;
    _renderTargetIsNonPremultiplied = renderTargetIsNonPremultiplied;
    _renderTargetHasBytePrecision = renderTargetHasBytePrecision;
  }
  return self;
}

+ (instancetype)instanceWithRenderTargetLocation:(lt::Quad)renderTargetLocation
                    renderTargetHasSingleChannel:(BOOL)renderTargetHasSingleChannel
                  renderTargetIsNonPremultiplied:(BOOL)renderTargetIsNonPremultiplied
                    renderTargetHasBytePrecision:(BOOL)renderTargetHasBytePrecision {
  return [[self alloc] initWithRenderTargetLocation:renderTargetLocation
                       renderTargetHasSingleChannel:renderTargetHasSingleChannel
                     renderTargetIsNonPremultiplied:renderTargetIsNonPremultiplied
                       renderTargetHasBytePrecision:renderTargetHasBytePrecision];
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@: %p, render target location: %@, render target has "
          "single channel: %@, render target is non-premultiplied: %@, render target has byte "
          "precision: %@>", self.class, self,
          NSStringFromLTQuad(self.renderTargetLocation),
          [@(self.renderTargetHasSingleChannel) stringValue],
          [@(self.renderTargetIsNonPremultiplied) stringValue],
          [@(self.renderTargetHasBytePrecision) stringValue]];
}

- (BOOL)isEqual:(DVNBrushRenderTargetInformation *)information {
  if (information == self) {
    return YES;
  }

  if (![information isKindOfClass:[DVNBrushRenderTargetInformation class]]) {
    return NO;
  }

  return self.renderTargetLocation == information.renderTargetLocation &&
      self.renderTargetHasSingleChannel == information.renderTargetHasSingleChannel &&
      self.renderTargetIsNonPremultiplied == information.renderTargetIsNonPremultiplied &&
      self.renderTargetHasBytePrecision == information.renderTargetHasBytePrecision;
}

- (NSUInteger)hash {
  size_t seed = 0;
  lt::hash_combine(seed, std::hash<lt::Quad>()(self.renderTargetLocation));
  lt::hash_combine(seed, self.renderTargetHasSingleChannel);
  lt::hash_combine(seed, self.renderTargetIsNonPremultiplied);
  lt::hash_combine(seed, self.renderTargetHasBytePrecision);
  return seed;
}

@end

NS_ASSUME_NONNULL_END
