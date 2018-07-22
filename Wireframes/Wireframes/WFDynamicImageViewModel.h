// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Alex Gershovich.

#import "WFImageViewModel.h"

NS_ASSUME_NONNULL_BEGIN

/// View model for presentation of images fetched dynamically based on URLs and an image provider.
///
/// @note consider using \c WFImageViewModelBuilder to create instances of this view model. It
/// offers a higher level API, more safety checks, and covers the most common use cases.
///
/// @see WFImageViewModelBuilder.
@interface WFDynamicImageViewModel : NSObject <WFImageViewModel>

/// Returns a view model with images loaded using the given image provider, with URLs sent via the
/// \c imagesSignal.
///
/// \c imagesSignal is a signal of \c RACTuple of two \c NSURL objects: URL for \c image and URL
/// for \c highlightedImage.
///
/// URL for \c image can be \c nil, in which case \c image would also be \c nil.
///
/// URL for \c highlightedImage can be \c nil, in which case \c highlightedImage would also be
/// \c nil. This is useful when there is no special image for highlighted state.
///
/// Images are reloaded each time a new, distinct value is sent via the signal.
///
/// \c animated and \c animationDuration set the receiver's \a isAnimated and \c animatedDuration
/// respectively.
///
/// @note prefer \c WFImageViewModelBuilder to create instances of this view model. It offers a
/// higher level API, more safety checks, and covers the most common use cases.
- (instancetype)initWithImageProvider:(id<WFImageProvider>)imageProvider
                         imagesSignal:(RACSignal<RACTwoTuple<NSURL *, NSURL *> *> *)imagesSignal
                             animated:(BOOL)animated
                    animationDuration:(NSTimeInterval)animationDuration
    NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
