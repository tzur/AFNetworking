// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Alex Gershovich.

NS_ASSUME_NONNULL_BEGIN

@protocol WFImageViewModel;

/// Category that binds \c WFImageViewModel view model onto the view. Used to display dynamically
/// sized images, like PaintCode icons.
///
/// Consider an image view that shows an icon, given as a png asset. The code would be similar to:
/// @code
/// UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
/// imageView.image = [UIImage imageNamed:@"icon"];
/// @endcode
///
/// The same result could be achieved using \c WFImageViewModel:
/// @code
/// UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
/// imageView.wf_viewModel = WFImageViewModel([NSURL URLWithString:@"icon"]).build();
/// @endcode
///
/// But now it is possible to draw the icon with PaintCode. For this you'll need to explicitly
/// specify the icon's size.
/// @code
/// UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
/// imageView.wf_viewModel = WFImageViewModel([NSURL URLWithString:@"paintcode://Module/Icon"])
///    .sizeToBounds(imageView)
///    .build();
/// @endcode
///
/// \c sizeToBound configures the view model to request images fitting the size of the imageView,
/// and redraw the icon whenever the size changes.
///
/// In addition, many icons in highlighted state differ only by their color, so it makes sense to
/// create PaintCode icons with \c color parameter that defines the icon's color. There is a
/// built-in support for this:
/// @code
/// UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
/// imageView.wf_viewModel = WFImageViewModel([NSURL URLWithString:@"paintcode://Module/Icon"])
///    .color([UIColor blueColor])
///    .highlightedColor([UIColor redColor])
///    .sizeToBounds(imageView)
///    .build();
/// @endcode
///
/// In the example above, the icon will be drawn blue in normal state, and red in highlighted state.
/// Note that although it looks like there's a retain cycle: button -> viewModel -> button, the
/// cycle is broken once the button deallocates, and therefore no memory leak will occur.
///
/// @see WFImageViewModelBuilder for more examples.
@interface UIImageView (ViewModel)

/// View model bound to this view. When set, the view binds itself to the view model.
///
/// \c image and \c highlightedImage properties of the view are bound to the same properties of
/// the view model, and should not be changed directly. Doing so might interfere with the view
/// model. On the other hand, setting view model to \c nil immediately disposes all binding to the
/// receiver, so it becomes possible to directly control the view.
///
/// The property is KVO compliant.
@property (strong, nonatomic, nullable) id<WFImageViewModel> wf_viewModel;

@end

NS_ASSUME_NONNULL_END
