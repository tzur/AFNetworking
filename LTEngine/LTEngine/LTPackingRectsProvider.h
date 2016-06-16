// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Gluzman.

#import <LTKit/LTUnorderedMap.h>

NS_ASSUME_NONNULL_BEGIN

/// Protocol for producing packing rects from a given map of sizes.
@protocol LTPackingRectsProvider <NSObject>

/// Returns a packing rects map from a given map of \c sizes. The map specifies the rect of each
/// size in \c sizes at the same key.
- (lt::unordered_map<NSString *, CGRect>)packingOfSizes:
    (const lt::unordered_map<NSString *, CGSize> &)sizes;

@end

NS_ASSUME_NONNULL_END
