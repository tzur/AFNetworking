// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Alex Gershovich.

NS_ASSUME_NONNULL_BEGIN

/// Category for creating \c NSURL objects with query parameters supported by some implementations
/// of \c WFImageProvider.
@interface NSURL (WFImageProvider)

/// Returns a new URL with query parameters \c width and \c height reflecting the given \c size.
- (NSURL *)wf_URLWithImageSize:(CGSize)size;

/// Returns a new URL with query parameter \c color set to the given \c color.
- (NSURL *)wf_URLWithImageColor:(UIColor *)color;

@end

NS_ASSUME_NONNULL_END
