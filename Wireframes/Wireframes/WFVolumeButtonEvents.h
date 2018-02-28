// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Michael Kimyagarov.

NS_ASSUME_NONNULL_BEGIN

/// Supported volume button events.
LTEnumDeclare(NSUInteger, WFVolumeButtonEvent,
  /// Volume up button pressed.
  WFVolumeButtonEventVolumeUpPress,
  /// Volume up button released.
  WFVolumeButtonEventVolumeUpRelease,
  /// Volume down button pressed.
  WFVolumeButtonEventVolumeDownPress,
  /// Volume down button released.
  WFVolumeButtonEventVolumeDownRelease
);

/// Returns a signal which sends \c WFVolumeButtonEvent each time user presses or releases devices
/// volume buttons. The returned signal doesn't err or complete. It's equivalent to the following
/// code:
///
/// @code
/// WFVolumeButtonEvents([UIApplication sharedApplication]);
/// @endcode
NS_EXTENSION_UNAVAILABLE_IOS("") RACSignal<WFVolumeButtonEvent *> *WFVolumeButtonEvents();

/// Returns a signal which sends \c WFVolumeButtonEvent each time user presses or releases devices
/// volume buttons. The returned signal doesn't err or complete. The given \c application is used to
/// enable / disable the generation of volume button events.
///
/// @important volume event generation starts whenever the returned signal is subscribed. During
/// that time the default behaviour of volume buttons is disabled. The default behavior is restored
/// when there's no active subscriptions left to signals returned by this method.
///
/// @note whenever volume event generation is enabled the system (iOS) generates \c UIPressesEvent
/// which is delivered to <tt>-[UIResponder presses{Began,Ended}:withEvent:]<\tt>. (Many key
/// objects are also responders, including the \c UIApplication, \c UIViewController, and
/// \c UIView). Make sure you understand the UIKit's event handing mechanism described in
/// "Understanding Event Handling, Responders, and the Responder Chain"
/// https://developer.apple.com/documentation/uikit/touches_presses_and_gestures/understanding_event_handling_responders_and_the_responder_chain
///
/// @note volume button events are generated differently by different accessories.
/// 1. Bluetooth selfie stick can perform in following ways:
///    a. Generate \c WFVolumeButtonEventVolumeUp{Press,Release} whenever the "take photo" button is
///       pressed and released correspondingly.
///    b. Generate a pair of \c WFVolumeButtonEventVolumeUp{Press,Release} events whenever the "take
///       photo" button is released. No event is sent whenever the up volume button is pressed.
/// 2. Apple's original earphones (with 3.5mm or Lightning jacks) generates a pair of
///    \c WFVolumeButtonEventVolume{Up,Down}Press and \c WFVolumeButtonEventVolume{Up,Down}Relese
///    events upon EACH press on the volume up / down button. When the button is released no event
///    is sent.
NS_EXTENSION_UNAVAILABLE_IOS("") RACSignal<WFVolumeButtonEvent *> *
    WFVolumeButtonEvents(UIApplication *application);

NS_ASSUME_NONNULL_END
