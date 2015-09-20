// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

/// Groups various image loading operations in order to provide another level of dereference for
/// easy testing and mocking.
@interface LTImageLoader : NSObject

/// Returns the singleton instance of the loader.
+ (instancetype)sharedInstance;

/// Returns the image object associated with the given name. See -[UIImage imageNamed:] for more
/// details.
- (UIImage *)imageNamed:(NSString *)name;

/// Returns the image object generated from the given file path. See
/// -[UIImage imageWithContentsOfFile:] for more details.
- (UIImage *)imageWithContentsOfFile:(NSString *)name;

@end
