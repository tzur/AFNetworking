// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Nir Bruner.

@class AVCaptureDeviceFormat;

NS_ASSUME_NONNULL_BEGIN

/// Protocol defining a strategy to pick a specific \c AVCaptureDeviceFormat from a given list.
@protocol CAMFormatStrategy <NSObject>

/// Returns the selected format from the given \c formats, or \c nil if no suitable format was
/// found.
- (nullable AVCaptureDeviceFormat *)formatFrom:(NSArray<AVCaptureDeviceFormat *> *)formats;

@end

/// Factory class for convenient creation of various basic \c CAMFormatStrategy objects.
@interface CAMFormatStrategy : NSObject

/// Returns a strategy for selecting the highest resolution \c 420f format available.
///
/// @see kCVPixelFormatType_420YpCbCr8BiPlanarFullRange.
+ (id<CAMFormatStrategy>)highestResolution420f;

/// Returns a strategy for selecting a \c 420f format with the given resolution.
///
/// @see kCVPixelFormatType_420YpCbCr8BiPlanarFullRange.
+ (id<CAMFormatStrategy>)exact420fWidth:(NSUInteger)width height:(NSUInteger)height;

@end

/// \c CAMFormatStrategy implementation that selects the Y'CbCr 4:2:0 full-range format with the
/// highest available resolution. Returns \c nil if no matching formats are available. If more than
/// one format matches, the first is returned.
///
/// @note Highest resolution is defined by pixel count.
@interface CAMFormatStrategyHighestResolution420f : NSObject <CAMFormatStrategy>
@end

/// \c CAMFormatStrategy implementation that selects Y'CbCr 4:2:0 full-range format of the given
/// resolution. Returns \c nil if the exact format was not found. If more than one format matches,
/// the first is returned.
@interface CAMFormatStrategyExactResolution420f : NSObject <CAMFormatStrategy>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes an instance with the given resolution to look for.
- (instancetype)initWithWidth:(NSUInteger)width height:(NSUInteger)height NS_DESIGNATED_INITIALIZER;

/// Exact width to look for.
@property (readonly, nonatomic) NSUInteger width;

/// Exact height to look for.
@property (readonly, nonatomic) NSUInteger height;

@end

NS_ASSUME_NONNULL_END
