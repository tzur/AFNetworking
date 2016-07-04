// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTContentTouchEventPredicate.h"

NS_ASSUME_NONNULL_BEGIN

/// Immutable object constituting an \c AND predicate, which accepts if all its predicates accept
/// the event.
@interface LTContentTouchEventAndPredicate : NSObject <LTContentTouchEventMultiPredicate>
@end

NS_ASSUME_NONNULL_END
