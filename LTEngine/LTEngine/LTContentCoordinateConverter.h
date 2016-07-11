// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

NS_ASSUME_NONNULL_BEGIN

@protocol LTContentLocationProvider;

/// Protocol which should be implemented by objects converting between floating-point pixel units of
/// the content coordinate system and point units of the presentation coordinate system.
@protocol LTContentCoordinateConverter <NSObject>

/// Converts the given \c point, given in floating-point pixel units of the content coordinate
/// system, to the corresponding point in point units of presentation coordinate system.
- (CGPoint)convertPointFromContentToPresentationCoordinates:(CGPoint)point;

/// Converts the given \c point, given in point units of presentation coordinate system, to the
/// corresponding point in floating-point pixel units of the content coordinate system.
- (CGPoint)convertPointFromPresentationToContentCoordinates:(CGPoint)point;

/// Affine transform converting a \c CGPoint, given in floating-point pixel units of the content
/// coordinate system, into the corresponding \c CGPoint, in point units of the presentation
/// coordinate system.
@property (readonly, nonatomic) CGAffineTransform contentToPresentationCoordinateTransform;

/// Affine transform converting a \c CGPoint, given in point units of the presentation coordinate
/// system, into the corresponding \c CGPoint, in floating-point pixel units of the content
/// coordinate system.
@property (readonly, nonatomic) CGAffineTransform presentationToContentCoordinateTransform;

@end

@interface LTContentCoordinateConverter : NSObject <LTContentCoordinateConverter>

- (instancetype)init NS_UNAVAILABLE;

/// Initialize with the given \c provider. The given \c provider is held strongly.
- (instancetype)initWithLocationProvider:(id<LTContentLocationProvider>)provider
    NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
