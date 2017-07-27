// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

#import "LABAssignmentsSource.h"

NS_ASSUME_NONNULL_BEGIN

/// Returns a new \c LABVariant with \c name, \c assignments and \c experiment.
inline static LABVariant *LABCreateVariant(NSString *name,
                                           NSDictionary<NSString *, id> *assignments,
                                           NSString *experiment) {
  return [[LABVariant alloc] initWithName:name assignments:assignments experiment:experiment];
}

NS_ASSUME_NONNULL_END
