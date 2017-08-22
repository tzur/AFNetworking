// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Alex Gershovich.

NS_ASSUME_NONNULL_BEGIN

/// Category that provides various signals related to the layout process of the view.
///
/// All properties defined by the category must be accessed on the main thread only, and signals are
/// delivered on the caller's thread (that is - the main thread).
@interface UIView (LayoutSignals)

/// Hot signal that sends the receiver's \c bounds each time \c layoutSubviews is called
/// (immediately <b>after</b> the call). The signal completes when the receiver is deallocated.
@property (readonly, nonatomic) RACSignal<NSValue *> *wf_layoutSubviewsSignal;

/// Hot signal that sends the receiver's current \c bounds, and then new \c bounds whenever the
/// latter changes. The signal completes when the receiver is deallocated.
///
/// @note there is no guarantee that every new value of \c bounds is sent by the signal. However, it
/// is guarantied that after a change of view bounds, and before the view is redrawn - the most
/// recent value is sent. This is similar to the way \c -layoutSubviews works: it might not get
/// called for every change of \c bounds, but it is called eventually during a layout pass.
@property (readonly, nonatomic) RACSignal<NSValue *> *wf_boundsSignal;

/// Hot signal that sends the receiver's current size, and then new size each time the latter
/// changes. The signal completes when the receiver is deallocated.
///
/// @note the signal works similar to \c wf_boundsSignal.
@property (readonly, nonatomic) RACSignal<NSValue *> *wf_sizeSignal;

/// Same as \c wf_sizeSignal, but accepts only positive values (where positive size is a size with
/// both \c width and \c height having positive values).
///
/// Consider using this signal when an action makes sense only for positive sizes, for example
/// loading an image that fits the view, or drawing something. With autolayout, views are usually
/// created with zero size, and receive the actual bounds only during a layout pass. With the help
/// of this signal, actual work can be deferred until after the initial layout has been applied.
@property (readonly, nonatomic) RACSignal<NSValue *> *wf_positiveSizeSignal;

@end

NS_ASSUME_NONNULL_END
