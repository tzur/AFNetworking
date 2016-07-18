// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Reuven Siman Tov.

#import "PTUChangesetProvider.h"

NS_ASSUME_NONNULL_BEGIN

@protocol PTNDescriptor;

/// \c PTUChangesetProvider that provides a constant array of \c PTNDescriptor objects for the
/// signal returned by \c fetchChangeset.
@interface PTUArrayChangesetProvider : NSObject <PTUChangesetProvider>

- (instancetype)init NS_UNAVAILABLE;

/// Initilizes the receiver with the given \c descriptor objects and \c changesetTitle associated
/// with these \c PTNDescriptor objects.
///
/// \c fetchChangeset returns a signal that sends a single \c PTUChangeset, containing the given
/// \c descriptors as its only section and completes. This signal sends its events on an arbitrary
/// thread, and never errs.
///
/// \c fetchChangesetMetadata returns a signal that sends a \c PTUChangesetMetadata object with the
/// given \c changesetTitle and empty \c sectionTitles. This signal sends its events on an arbitrary
/// thread, and never errs.
- (instancetype)initWithDescriptors:(NSArray<id<PTNDescriptor>> *)descriptors
                     changesetTitle:(nullable NSString *)changesetTitle;

@end

NS_ASSUME_NONNULL_END
