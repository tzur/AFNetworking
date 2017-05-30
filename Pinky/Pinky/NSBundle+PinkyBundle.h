// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

NS_ASSUME_NONNULL_BEGIN

/// Category for easily retrieving the Pinky accompanying bundle.
@interface NSBundle (PinkyBundle)

/// Local Pinky bundle, assuming it resides in the main bundle.
+ (nullable NSBundle *)pnk_bundle;

@end

NS_ASSUME_NONNULL_END
