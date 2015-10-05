// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

/// Category for easily retrieving LTKit accompanying bundle.
@interface NSBundle (LTEngineBundle)

/// Local LTKit bundle, assuming it was copied to the main bundle.
+ (NSBundle *)LTEngineBundle;

@end
