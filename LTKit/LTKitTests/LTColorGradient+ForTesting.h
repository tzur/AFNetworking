// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTColorGradient.h"

/// Convenience methods to create color gradients for testing.
@interface LTColorGradient (ForTesting)

/// Creates an instance of LTColorGradient that represents a colder-than-neutral gradient.
/// This gradient is useful for testing B&W scenarios, where identityGradient is not rich enough to
/// expose potential issues.
///
/// @return color gradient that represents a colder-than-neutral manipulation.
+ (LTColorGradient *)colderThanNeutralGradient;

/// Creates an instance of LTColorGradient that represents a magenta-yellow gradient.
/// This gradient is useful for testing color scenarios, where identityGradient is not rich enough
/// to expose potential issues.
///
/// @return color gradient that represents a colder-than-neutral manipulation.
+ (LTColorGradient *)magentaYellowGradient;

@end
