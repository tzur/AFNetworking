// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Alex Gershovich.

NS_ASSUME_NONNULL_BEGIN

/// Protocol for asynchronously providing images, as \c UIImage objects, based on URLs.
///
/// The format of the URL is not defined by this protocol. It is up to implementations to come up
/// with reasonable format suiting their particular needs.
@protocol WFImageProvider <NSObject>

/// Returns a signal of \c UIImage that sends an image associated with the given \c url and
/// completes afterwards. The signal errs if the image cannot be provided.
///
/// @note the signal might be delivered on any scheduler.
///
/// @note be careful when ignoring errors sent by the signal, since it can lead to actual
/// programming errors staying under the surface. For example, a typo in asset's name causes an
/// error, and if ignored it may stay unnoticed for a long time, especially for small icons.
- (RACSignal<UIImage *> *)imageWithURL:(NSURL *)url;

@end

NS_ASSUME_NONNULL_END
