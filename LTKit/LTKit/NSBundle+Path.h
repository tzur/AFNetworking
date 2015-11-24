// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

NS_ASSUME_NONNULL_BEGIN

@interface NSBundle (Path)

/// Returns the path for the given resource \c name (including file extension) that resides in the
/// same bundle of the given \c classObject. If the file cannot be found, \c nil is returned.
+ (nullable NSString *)lt_pathForResource:(NSString *)name nearClass:(Class)classObject;

/// Returns the path for the given resource \c name in the receiver bundle, or \c nil if no such
/// resource is found.
///
/// @see -[NSBundle pathForResource:ofType:].
- (nullable NSString *)lt_pathForResource:(NSString *)name;

@end

NS_ASSUME_NONNULL_END
