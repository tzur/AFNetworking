// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "DVNTexCoordProvider.h"

NS_ASSUME_NONNULL_BEGIN

/// Model of an \c id<DVNTexCoordProvider> object providing the canonical square quad
/// <tt>((0, 0), (1, 0), (1, 1), (0, 1))</tt> for any given quad.
@interface DVNCanonicalTexCoordProviderModel : NSObject <DVNTexCoordProviderModel>
@end

NS_ASSUME_NONNULL_END
