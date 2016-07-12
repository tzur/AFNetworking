// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Nofar Noy.

NS_ASSUME_NONNULL_BEGIN

/// Category adding additional enumeration functionality to the \c CALayer class.
@interface CALayer (Enumeration)

/// Executes the given \c block for each sub layer including the receiver itself.
- (void)wf_enumerateLayersUsingBlock:(void (^)(CALayer *layer))block;

@end

NS_ASSUME_NONNULL_END
