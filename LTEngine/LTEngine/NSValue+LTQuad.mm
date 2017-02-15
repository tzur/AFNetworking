// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "NSValue+LTQuad.h"

NS_ASSUME_NONNULL_BEGIN

@implementation NSValue (LTQuad)

+ (NSValue *)valueWithLTQuad:(lt::Quad)quad {
  return [NSValue valueWithBytes:&quad objCType:@encode(lt::Quad)];
}

- (lt::Quad)LTQuadValue {
  lt::Quad quad;
  [self getValue:&quad];
  return quad;
}

@end

NS_ASSUME_NONNULL_END
