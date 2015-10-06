// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTRect.h"

#ifdef __cplusplus

@interface NSValue (LTRect)

- (LTRect)LTRectValue;

+ (NSValue *)valueWithLTRect:(LTRect)rect;

@end

#endif
