// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTContentTouchEventPredicate.h"

NS_ASSUME_NONNULL_BEGIN

/// Immutable object constituting an \c OR predicate, which accepts if at least one of its
/// predicates accepts the event.
@interface LTContentTouchEventOrPredicate : NSObject <LTContentTouchEventMultiPredicate>
@end

NS_ASSUME_NONNULL_END
