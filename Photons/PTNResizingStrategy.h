// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "PTNImageContentMode.h"

NS_ASSUME_NONNULL_BEGIN

/// Protocol that defines a strategy for resizing an asset. The strategy is a function that accepts
/// an input size of an asset and returns the output size to resize the asset to.
@protocol PTNResizingStrategy <NSObject>

/// Returns the output size of an asset given its input size. The returned size must be integral
/// and uniformly scaled from \c size.
- (CGSize)sizeForInputSize:(CGSize)size;

/// Content mode used by this \c PTNResizingStrategy in the cases where the requested size
/// doesn't match the aspect ratio of the original size.
@property (readonly, nonatomic) PTNImageContentMode contentMode;

@end

/// Resizing strategy that returns the input size.
@interface PTNIdentityResizingStrategy : NSObject <PTNResizingStrategy>
@end

/// Resizing strategy that enforces that the maximal number of pixels of the returned size will not
/// be larger than a given limit.
@interface PTNMaxPixelsResizingStrategy : NSObject <PTNResizingStrategy>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes the strategy for enforcing an output size with no more than \c maxPixels.
- (instancetype)initWithMaxPixels:(NSUInteger)maxPixels NS_DESIGNATED_INITIALIZER;

@end

/// Resizing strategy for calculating an output size in an aspect fit manner. For example, for a
/// maximal dimension of 50 and an input size of (100, 200), the returned size will be (25, 50).
@interface PTNAspectFitResizingStrategy : NSObject <PTNResizingStrategy>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes the strategy with the given \c size to aspect fit to.
- (instancetype)initWithSize:(CGSize)size NS_DESIGNATED_INITIALIZER;

@end

/// Resizing strategy for calculating an output size in an aspect fill manner. For example, for a
/// target size of (50, 50) and an input size of (100, 200), the returned size will be (50, 100).
@interface PTNAspectFillResizingStrategy : NSObject <PTNResizingStrategy>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes the strategy with the given \c size to aspect fill to.
- (instancetype)initWithSize:(CGSize)size NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
