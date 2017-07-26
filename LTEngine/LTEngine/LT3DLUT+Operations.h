// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "LT3DLUT.h"

NS_ASSUME_NONNULL_BEGIN

@interface LT3DLUT (Operations)

/// Returns a new \c LT3DLUT that is the composition of the receiver with \c other. The composition
/// is the LUT that when applied to an image produces the same result that would be produced by
/// applying \c self and then \c other to the image. The lattice size of \c other must equal the
/// lattice size of \c self.
- (instancetype)composeWith:(LT3DLUT *)other;

@end

NS_ASSUME_NONNULL_END
