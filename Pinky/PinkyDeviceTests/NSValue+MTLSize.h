// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

NS_ASSUME_NONNULL_BEGIN

@interface NSValue (MTLSize)

- (MTLSize)MTLSizeValue;

+ (NSValue *)valueWithMTLSize:(MTLSize)size;

@end

NS_ASSUME_NONNULL_END
