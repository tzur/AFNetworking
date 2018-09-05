// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

/// Category for easily retrieving LTEngine accompanying bundle.
@interface NSBundle (LTEngineBundle)

/// Local LTEngine bundle, assuming it is placed in the same directory that LTEngine's binary code
/// is placed.
+ (NSBundle *)lt_engineBundle;

@end
