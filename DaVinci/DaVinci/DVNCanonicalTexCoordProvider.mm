// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "DVNCanonicalTexCoordProvider.h"

NS_ASSUME_NONNULL_BEGIN

static const lt::Quad kCanonicalQuad = lt::Quad(CGRectFromSize(CGSizeMakeUniform(1)));

@interface DVNCanonicalTexCoordProviderModel () <DVNTexCoordProvider>
@end

@implementation DVNCanonicalTexCoordProviderModel

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (BOOL)isEqual:(DVNCanonicalTexCoordProviderModel *)model {
  return self == model || [model isKindOfClass:[DVNCanonicalTexCoordProviderModel class]];
}

- (NSUInteger)hash {
  return 0;
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

- (DVNCanonicalTexCoordProviderModel *)provider {
  return self;
}

#pragma mark -
#pragma mark DVNTexCoordProvider
#pragma mark -

- (std::vector<lt::Quad>)textureMapQuadsForQuads:(const std::vector<lt::Quad> &)quads {
  return std::vector<lt::Quad>(quads.size(), kCanonicalQuad);
}

- (id<DVNTexCoordProviderModel>)currentModel {
  return self;
}

@end

NS_ASSUME_NONNULL_END
