// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "DVNRandomTexCoordProvider.h"

#import <LTKit/LTRandom.h>

NS_ASSUME_NONNULL_BEGIN

@interface DVNRandomTexCoordProvider : NSObject <DVNTexCoordProvider> {
  /// Collection of quads from which quads for texture mapping can be chosen.
  std::vector<lt::Quad> _textureMapQuads;
}

/// Random number generator.
@property (readonly, nonatomic) LTRandom *random;

@end

@implementation DVNRandomTexCoordProvider

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithModel:(DVNRandomTexCoordProviderModel *)model {
  if (self = [super init]) {
    _textureMapQuads = model.textureMapQuads;
    _random = [[LTRandom alloc] initWithState:model.randomState];
  }
  return self;
}

#pragma mark -
#pragma mark DVNTexCoordProvider
#pragma mark -

- (std::vector<lt::Quad>)textureMapQuadsForQuads:(const std::vector<lt::Quad> &)quads {
  std::vector<lt::Quad> textureMapQuads;
  textureMapQuads.reserve(quads.size());

  uint numberOfAvailableQuads = (uint)_textureMapQuads.size();

  for (std::vector<lt::Quad>::size_type i = 0; i < quads.size() ; ++i) {
    std::vector<lt::Quad>::size_type index =
        [self.random randomUnsignedIntegerBelow:numberOfAvailableQuads];
    textureMapQuads.push_back(_textureMapQuads[index]);
  }

  return textureMapQuads;
}

- (DVNRandomTexCoordProviderModel *)currentModel {
  return [[DVNRandomTexCoordProviderModel alloc] initWithRandomState:self.random.engineState
                                                     textureMapQuads:_textureMapQuads];
}

@end

@interface DVNRandomTexCoordProviderModel () {
  /// Collection of quads from which quads for texture mapping can be chosen.
  std::vector<lt::Quad> _quads;
}

/// Reference to the \c _quads property. Exposed internally in order to avoid unnecessary vector
/// copy operations.
@property (readonly, nonatomic) std::vector<lt::Quad> &quads;

@end

@implementation DVNRandomTexCoordProviderModel

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithRandomState:(LTRandomState *)randomState
                    textureMapQuads:(const std::vector<lt::Quad> &)textureMapQuads {
  LTParameterAssert(randomState);
  LTParameterAssert(textureMapQuads.size());

  if (self = [super init]) {
    _randomState = randomState;
    _quads = textureMapQuads;
  }
  return self;
}

- (std::vector<lt::Quad>)textureMapQuads {
  return _quads;
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (BOOL)isEqual:(DVNRandomTexCoordProviderModel *)model {
  if (self == model) {
    return YES;
  }

  if (![model isKindOfClass:[DVNRandomTexCoordProviderModel class]]) {
    return NO;
  }

  return [self.randomState isEqual:model.randomState] && _quads == model.quads;
}

- (NSUInteger)hash {
  return self.randomState.hash ^ std::hash<std::vector<lt::Quad>>()(_quads);
}

#pragma mark -
#pragma mark Copying
#pragma mark -

- (id)copyWithZone:(nullable NSZone __unused *)zone {
  return self;
}

#pragma mark -
#pragma mark DVNTexCoordProviderModel
#pragma mark -

- (DVNRandomTexCoordProvider *)provider {
  return [[DVNRandomTexCoordProvider alloc] initWithModel:self];
}

@end

NS_ASSUME_NONNULL_END
