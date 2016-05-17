// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Alex Gershovich.

NS_ASSUME_NONNULL_BEGIN

@protocol WFImageViewModel;

/// Category that binds \c WFImageViewModel view model onto the view. Used to display dynamically
/// sized images, like PaintCode icons.
///
/// Consider a button that shows an icon, given as a png asset. The code would be similar to:
/// @code
/// UIButton *button = [[UIButton alloc] initWithFrame:CGRectZero];
/// [button setImage:[UIImage imageNamed:@"icon"] forState:UIControlStateNormal];
/// @endcode
///
/// The same result could be achieved using \c WFImageViewModel:
/// @code
/// UIButton *button = [[UIButton alloc] initWithFrame:CGRectZero];
/// button.wf_viewModel = WFImageViewModel([NSURL URLWithString:@"icon"]).build();
/// @endcode
///
/// But now it is possible to draw the icon with PaintCode. For this you'll need to explicitly
/// specify icon's size.
/// @code
/// UIButton *button = [[UIButton alloc] initWithFrame:CGRectZero];
/// button.wf_viewModel = WFImageViewModel([NSURL URLWithString:@"paintcode://Module/Icon"])
///    .sizeToBounds(button)
///    .build();
/// @endcode
///
/// \c sizeToBound configures the view model to request images fitting the size of the button, and
/// redraw the icon whenever the size changes.
///
/// In addition, many icons in highlighted state differ only by their color, so it makes sense to
/// create PaintCode icons with \c color parameter that defines the icon's color. There is a
/// built-in support for this:
/// @code
/// UIButton *button = [[UIButton alloc] initWithFrame:CGRectZero];
/// button.wf_viewModel = WFImageViewModel([NSURL URLWithString:@"paintcode://Module/Icon"])
///    .color([UIColor blueColor])
///    .highlightedColor([UIColor redColor])
///    .sizeToBounds(button)
///    .build();
/// @endcode
///
/// In the example above, the icon will be drawn blue in normal state, and red in highlighted (and
/// selected) states. Note that although it looks like there's a retain cycle:
/// button -> viewModel -> button, the cycle is broken once the button deallocates, and therefore no
/// memory leak will occur.
///
/// @see WFImageViewModelBuilder for more examples.
@interface UIButton (ViewModel)

/// View model bound to this view. When set, the view binds itself to the view model.
///
/// Button's image for normal state (\c UIControlStateNormal) is bound to \c image property of the
/// view model, and images for highlighted state (\c UIControlStateHighlighted), selected state
/// (\c UIControlStateSelected) and both states together are bound to \c highlightedImage property.
///
/// While the view model is not \c nil, do not set button's images directly. Doing so might
/// interfere with the view model. On the other hand, setting view model to \c nil immediately
/// disposes all binding to the receiver, so it becomes possible to directly control button's
/// images.
///
/// The property is KVO compliant.
@property (strong, nonatomic, nullable) id<WFImageViewModel> wf_viewModel;

@end

NS_ASSUME_NONNULL_END
