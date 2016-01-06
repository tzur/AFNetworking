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

/// \c YES if <tt>([self sizeForInputSize:])</tt> with \c size bounds from above the the size
/// returned by <tt>([self sizeForInputSize:])</tt> for \b any size.
/// Size \c s1 bounds from above size \c s2 if the rect <tt>(0, 0, s1.width, s1.height)</tt>
/// bounds from above the rect <tt>(0, 0, s2.width, s2.height)</tt>.
- (BOOL)inputSizeBoundedBySize:(CGSize)size;

/// Content mode used by this \c PTNResizingStrategy in the cases where the requested size
/// doesn't match the aspect ratio of the original size.
@property (readonly, nonatomic) PTNImageContentMode contentMode;

@end

/// Factory class for convenient creation of various basic \c PTNResizingStrategy compliant objects.
@interface PTNResizingStrategy : NSObject

/// Returns a resizing strategy that returns the input size.
+ (id<PTNResizingStrategy>)identity;

/// Returns a resizing strategy that enforces that the maximal number of pixels of the returned size
/// will not be larger than a given limit.
+ (id<PTNResizingStrategy>)maxPixels:(NSUInteger)maxPixels;

/// Returns a resizing strategy for calculating an output size in an aspect fit manner.
+ (id<PTNResizingStrategy>)aspectFit:(CGSize)size;

/// Returns a resizing strategy for calculating an output size in an aspect fill manner.
+ (id<PTNResizingStrategy>)aspectFill:(CGSize)size;

/// Returns a resizing strategy for calculating an output size in the manner specified in
/// \c contentMode.
+ (id<PTNResizingStrategy>)contentMode:(PTNImageContentMode)contentMode size:(CGSize)size;

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
