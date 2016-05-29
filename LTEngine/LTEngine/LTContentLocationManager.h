// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTContentLocationProvider.h"

typedef NS_ENUM(NSUInteger, LTViewNavigationMode);

NS_ASSUME_NONNULL_BEGIN

@class LTViewNavigationState;

/// Protocol which should be implemented by objects managing the location of a rectangle bounding
/// pixel content that can be displayed inside a suitable view. The content rectangle is
/// axis-aligned, non-rotatable, pannable, and zoomable (in relation to the enclosing view).
@protocol LTContentLocationManager <LTContentLocationProvider>

/// For some reason on the iPhone 6 Plus (and possibly on the iPhone 6) the scrollview's pan gesture
/// triggers even while its numberOfTouches is less than its minimumNumberOfTouches. This triggers a
/// call to touchesCancelled, which prevents any touch functionality from happening.
/// This hack detects this scenario, when in two fingers navigation mode, and cancels the pan
/// gesture by disabling and re-enabling the recoginzer.
- (void)cancelBogusScrollviewPanGesture;

/// Size, in integer pixel units of the content coordinate system, of the content rectangle managed
/// by this instance.
@property (nonatomic) CGSize contentSize;

/// Navigation mode currently used by this instance.
@property (nonatomic) LTViewNavigationMode navigationMode;

@end

NS_ASSUME_NONNULL_END
