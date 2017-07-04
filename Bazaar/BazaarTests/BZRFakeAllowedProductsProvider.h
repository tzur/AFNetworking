// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRAllowedProductsProvider.h"

NS_ASSUME_NONNULL_BEGIN

/// Fake provider that provides a set of allowed products manually injected to its
/// \c allowedProducts property.
@interface BZRFakeAllowedProductsProvider : NSObject <BZRAllowedProductsProvider>

/// \c eventsSignal redeclared as \c RACSubject to be able to send events with.
@property (readonly, nonatomic) RACSubject *eventsSignal;

/// A replaceable allowed products set.
@property (strong, nonatomic) NSSet<NSString *> *allowedProducts;

@end

NS_ASSUME_NONNULL_END
