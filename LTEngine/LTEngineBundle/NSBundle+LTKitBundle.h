// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

/// Category for easily retrieving LTKit accompanying bundle.
@interface NSBundle (LTKitBundle)

/// Local LTKit bundle, assuming it was copied to the main bundle.
+ (NSBundle *)LTKitBundle;

@end
