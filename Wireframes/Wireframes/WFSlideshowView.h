// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Daniel Hadar.

NS_ASSUME_NONNULL_BEGIN

@class WFSlideshowView;

/// Protocol for providing \c WFSlideshowView with views to slide between.
@protocol WFSlideshowViewDelegate <NSObject>

/// Returns the total number of slides to be shown by the given \c slideshowView.
- (NSUInteger)numberOfSlidesInSlideshowView:(WFSlideshowView *)slideshowView;

/// Returns a view that represents a single slide at the given \c index. The returned view is used
/// by \c slideshowView to actually draw the slide.
- (UIView *)slideshowView:(WFSlideshowView *)slideshowView viewForSlideIndex:(NSUInteger)index;

@end

/// Transition types supported by the slideshow item.
typedef NS_ENUM(NSUInteger, WFSlideshowTransition) {
  /// Sliding curtain reveals the next slide. The slide direction is left to right.
  WFSlideshowTransitionCurtain,
  /// Next slide fades in from transparent to opaque.
  WFSlideshowTransitionFade,
};

/// View that presents a slideshow by animating between a number of slides. Each slide is drawn by
/// a view provided via the \c delegate.
///
/// The slideshow animation consists of two indefinitely recurring parts: still part, during which
/// the current slide is displayed without motion or animation, and transition part, where the next
/// slide appears and the current slide disappers.
@interface WFSlideshowView : UIView

/// Starts indefinite animation, sliding between the slides. Animation timings are controlled by
/// \c stillDuration and \c transitionDuration properties.
- (void)play;

/// Pauses sliding between the slides. An ongoing sliding animation continues, but the next
/// transition will not occur. If you wish to stop animations immediately, call
/// \c pauseAndRemoveOngoingAnimation instead.
- (void)pause;

/// Pauses slideing between the slides and immediately removes all ongoing animations.
///
/// @important removal of an ongoing animation may have an upleasant visual effect. Use only when
/// the view is not visible.
- (void)pauseAndRemoveOngoingAnimations;

/// Pauses slideing between the slides, immediately removes all ongoing animations, and loads views
/// from the delegate to present the slideshow from the begining.
///
/// @important removal of an ongoing animation may have an upleasant visual effect. Use only when
/// the view is not visible.
- (void)reloadSlides;

/// Transition type used to animate the transition between slides. \c WFSlideshowTransitionCurtain
/// by default. Setting this property pauses slideing between the slides, immediately removes all
/// ongoing animations, and loads views from the delegate to present the slideshow from the
/// begining. Note that the removal of an ongoing animation may have an upleasant visual effect. Use
/// only when the view is not visible.
@property (nonatomic) WFSlideshowTransition transition;

/// Duration for holding a slide still. \c 1 second by default. Negative values are treated like
/// zero. The value takes affect right before the next still part.
@property (nonatomic) NSTimeInterval stillDuration;

/// Duration for transition animation between slides. \c 1 second by default. If
/// \c transitionDuration is not a positive number, the transition is made without animation. The
/// value takes affect right before the next still part.
@property (nonatomic) NSTimeInterval transitionDuration;

/// Delegate which provides the view with the actual slides to be shown. Setting the \c delegate
/// pauses slideing between the slides, immediately removes all ongoing animations, and loads views
/// from the delegate to present the slideshow from the begining.
///
/// @important removal of an ongoing animation may have an upleasant visual effect. Use only when
/// the view is not visible.
@property (weak, nonatomic, nullable) id<WFSlideshowViewDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
