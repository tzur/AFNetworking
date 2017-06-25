// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

NS_ASSUME_NONNULL_BEGIN

/// Groups various image loading operations in order to provide another level of dereference for
/// easy testing and mocking.
@interface LTImageLoader : NSObject

/// Returns the singleton instance of the loader.
+ (instancetype)sharedInstance;

/// Returns the image object associated with the given name. See -[UIImage imageNamed:] for more
/// details.
- (nullable UIImage *)imageNamed:(NSString *)name;

/// Returns the variant of the image object associated with the given \c name in the given \c bundle
/// that is compatible with the given \c traitCollection.
/// See -[UIImage imageNamed:inBundle:compatibleWithTraitCollection:] for more details.
- (nullable UIImage *)imageNamed:(NSString *)name inBundle:(nullable NSBundle *)bundle
   compatibleWithTraitCollection:(nullable UITraitCollection *)traitCollection;

/// Returns the image object generated from the given file path. See
/// -[UIImage imageWithContentsOfFile:] for more details.
- (nullable UIImage *)imageWithContentsOfFile:(NSString *)name;

/// Returns the image object generated from the given data. See [UIImage imageWithData:] for more
/// details.
///
/// @note This method is possibly not thread safe, see
/// https://github.com/AFNetworking/AFNetworking/issues/2572
- (nullable UIImage *)imageWithData:(NSData *)data;

@end

NS_ASSUME_NONNULL_END
