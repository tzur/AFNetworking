// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import <FBTweak/FBTweakInline.h>

#import "SHKTweakInlineInternal.h"

/// Defines and returns an \c FBTTweak object with \c name. The new Tweak will reside in
/// \c collection inside \c category.
/// Returns \c nil if Tweaks are disabled.
///
/// @see SHKTweakValue
#define SHKTweakInline(category, collection, name, ...) \
    _FBTweakInline(category, collection, name, __VA_ARGS__)

/// Defines a Tweak with \c name and returns its current value. The new Tweak will reside in
/// \c collection inside \c category.
/// Returns the default value (4th parameter) if Tweaks are disabled.
///
/// @important Do not define the same Tweak twice.
///
/// @example
/// CGFloat animationDuration = FBTweakValue(@"Category", @"Group", @"Duration", 0.5);
///
/// @important Only compile-time constants are allowed as default values - local variables are not
/// allowed but constants are allowed, as well as literal \c NSString, \c NSNumber and primitives.
///
/// @example
/// self.red = FBTweakValue(@"Header", @"Colors", @"Red", 0.5, 0.0, 1.0);
///
/// It is also possible to constrain the values for a Tweak by providing a 5th parameters. The
/// fifth parameter can be an \c NSArray, \c NSDictionary, or an \c FBTweakNumericRange. If it's
/// an \c NSDictionary, the values should be strings to show in the list of choices. Arrays will
/// show the values' description as choices. (Note that arrays and dictionary should be surrounded
/// with an extra set of parentheses).
///
/// @example
/// self.server = FBTweakValue(@"Photons", @"Ocean", @"Server", @(PTNOceanServerProduction),
///     (@{ @(PTNOceanServerProduction) : @"Production", @(PTNOceanServerStaging) : @"Staging" }));
///
/// In case of numeric values (\c int, \c CGFloat, etc) it's possible to constrain their range by
/// using the 5th and 6th parameters.
///
/// @example
/// self.red = FBTweakValue(@"Header", @"Colors", @"Red", 0.5, 0.0, 1.0);
#define SHKTweakValue(category, collection, name, ...) \
    _FBTweakValue(category, collection, name, __VA_ARGS__)

/// Defines a Tweak with \c name and binds its value to the given \c object \c property. The new
/// Tweak will reside in \c collection inside \c category. Binds the default value (4th parameter)
/// if Tweaks are disabled.
///
/// @example
/// FBTweakBind(self.headerView, alpha, @"Main Screen", @"Header", @"Alpha", 0.85);
///
/// @see SHKTweakValue
#define SHKTweakBind(object, property, category, collection, name, ...) \
    _FBTweakBind(object, property, category, collection, name, __VA_ARGS__)

/// Defines a Tweak with \c name and returns a singal that fires the value of a Tweak when the
/// value changes. The signal does not err or complete. The new Tweak will reside in \c collection
/// inside \c category.
///
/// Returns a signal that immeditely return the default value (4th parameter) if Tweaks are
/// disabled. The default values cannot be primitives.
///
/// @see SHKTweakValue
#define SHKTweakSignal(category, collection, name, ...) \
    _SHKTweakSignal(category, collection, name, __VA_ARGS__)

/// Defines and returns an action Tweak using a given block (4th parameter). Action Tweak let the
/// user execute the block using the Tweak UI.
///
/// @important The block must not reference any local variables, and may access only global objecs.
///
/// The block does not return any value and does not have parameters as \c dispatch_block_t.
/// The new Tweak will reside in \c collection inside \c category.
///
/// Does nothing if Tweaks are disabled.
#define SHKTweakAction(category, collection, name, ...) \
    _FBTweakAction(category, collection, name, __VA_ARGS__)
