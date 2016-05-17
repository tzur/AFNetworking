// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Alex Gershovich.

NS_ASSUME_NONNULL_BEGIN

@protocol WFImageProvider, WFImageViewModel;

/// Builder interface that creates instances of \c WFImageViewModel. Instantiate via
/// \c WFImageViewModel().
///
/// The builder uses a default image provider, as returned by \c WFDefaultImageProvider(). You can
/// specify custom provider using \c imageProvider() or globally override the default provider by
/// implementing your own \c WFDefaultImageProvider(). See the latter for more info.
///
/// A couple of examples covering the most common usage patterns:
///
/// Create view model that loads an icon from main bundle / asset catalog, using its original size.
/// @code
/// WFImageViewModel([NSURL URLWithString:@"icon"]).build();
/// @endcode
///
/// Create view model that loads an asset from main bundle / asset catalog, using its original size,
/// and another asset to be displayed in highlighted state.
/// @code
/// WFImageViewModel([NSURL URLWithString:@"icon"])
///     .highlightedImageURL([NSURL URLWithString:@"highlightedIcon"])
///     .build();
/// @endcode
///
/// Create view model that displays icon "Icon", from PaintCode module "Module", colored blue and
/// yellow in normal and highlighted states respectively. Icon size matches the bounds of \c view,
/// and the icon is redrawn whenever the view bounds change (more precisely, during the following
/// layout pass).
/// @code
/// WFImageViewModel([NSURL URLWithString:@"paintcode://Module/Icon"])
///     .color([UIColor blueColor])
///     .highlightedColor([UIColor yellowColor])
///     .sizeToBounds(view)
///     .build();
/// @endcode
///
/// Same as above, but the icon is drawn with a constant size of 44x44 points.
/// @code
/// WFImageViewModel([NSURL URLWithString:@"paintcode://Module/Icon"])
///     .color([UIColor blueColor])
///     .highlightedColor([UIColor yellowColor])
///     .fixedSize(CGSizeMake(44, 44))
///     .build();
/// @endcode
///
/// @see \c WFDynamicImageViewModel for the underlying view model implementation.
@interface WFImageViewModelBuilder : NSObject

/// Returns a new instance of the builder. \c imageURL is used to load the \c image, using the
/// default image provider.
///
/// @note prefer the shorter version, by calling \c WFImageViewModel().
+ (instancetype)builderWithImageURL:(NSURL *)imageURL;

- (instancetype)init NS_UNAVAILABLE;

/// Uses a custom image provider, instead of the default one.
- (WFImageViewModelBuilder *(^)(id<WFImageProvider> imageProvider))imageProvider;

/// \c highlightedImageURL is used to load the \c highlightedImage.
- (WFImageViewModelBuilder *(^)(NSURL *highlightedImageURL))highlightedImageURL;

/// Images will be loaded with the given fixed size. The size is given in points, with the scale of
/// the main screen. The size must be positive.
- (WFImageViewModelBuilder *(^)(CGSize value))fixedSize;

/// Images will be loaded with the size of the given view's \c bounds, and reloaded whenever the
/// bounds change.
///
/// @note the view is not held strongly by the view model (nor by the builder).
- (WFImageViewModelBuilder *(^)(UIView *view))sizeToBounds;

/// Images will be loaded with the size sent via the signal, which must be a signal of \c CGSize
/// boxed in \c NSValue. Images are reloaded each time a new, distinct value is sent. Non positive
/// values are silently ignored.
- (WFImageViewModelBuilder *(^)(RACSignal *value))sizeSignal;

/// Colorizes the image with the given color. The color is passed via \c color query parameter into
/// the image provider.
- (WFImageViewModelBuilder *(^)(UIColor *color))color;

/// Colorizes the \c highlightedImage with the given color. The color is passed via \c color query
/// parameter into the image provider. If no URL for highlighted image is set, uses \c imageURL
/// as the image to be colorized. This is useful when image and highlighted image differ only in
/// color.
- (WFImageViewModelBuilder *(^)(UIColor *color))highlightedColor;

/// Finalizes the builder and returns a new instance of the view model matching the built
/// configuration.
///
/// The builder can't be altered after this call.
///
/// Raises \c NSInvalidArgumentException if the configuration is invalid, or if this is not the
/// first time \c build() is called.
- (id<WFImageViewModel> (^)())build;

@end

#ifdef __cplusplus
extern "C" {
#endif

/// Creates a new instance of \c WFImageViewModelBuilder. This is essentially a shortcut for
/// <tt>+[WFImageViewModelBuilder builderWithImageURL:]</tt>.
inline WFImageViewModelBuilder *WFImageViewModel(NSURL *imageURL) {
  return [WFImageViewModelBuilder builderWithImageURL:imageURL];
}

/// Returns an instance of image provider, used by \c WFImageViewModelBuilder to dynamically
/// load images (unless another image provider is explicitly specified).
///
/// Wireframes library provides an implementation of this function, that shares a global singleton
/// instance of \c WFImageLoader, created with a default configuration.
///
/// It is possible to override Wireframes' implementation, by providing your own. Simply implement
/// this function in your project.
///
/// @note The function uses C linkage. If implemented in .mm file, it must be placed inside
/// <tt>extern "C"</tt> scope, or marked as <tt>extern "C"</tt>.
extern id<WFImageProvider> WFDefaultImageProvider();

#ifdef __cplusplus
}
#endif

NS_ASSUME_NONNULL_END
