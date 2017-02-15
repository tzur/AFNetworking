// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTQuad.h"

NS_ASSUME_NONNULL_BEGIN

#ifdef __cplusplus

/// Category augmenting the \c NSValue class with convenience methods for boxing and unboxing of
/// \c lt::Quad values.
@interface NSValue (LTQuad)

/// Returns a new instance encoding the given \c quad.
+ (NSValue *)valueWithLTQuad:(lt::Quad)quad;

/// Returns the \c quad assumed to be encoded by this instance.
- (lt::Quad)LTQuadValue;

@end

#endif

NS_ASSUME_NONNULL_END
