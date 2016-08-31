// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

NS_ASSUME_NONNULL_BEGIN

/// Provider of \c UIView instances to display in case of a given error when fetching an album.
@protocol PTUErrorViewProvider <NSObject>

/// View to display in case of \c error. \c url is the url associated with the error if available,
/// or \c nil if no such url exists.
- (UIView *)errorViewForError:(NSError *)error associatedURL:(nullable NSURL *)url;

@end

/// Block transforming \c error and nullable \c url pair to an appropriate \c UIView.
typedef UIView * _Nonnull(^PTUErrorViewBlock)(NSError *error, NSURL * _Nullable url);

/// Implementation of \c PTUErrorViewProvider using a \c PTUErrorViewBlock.
@interface PTUErrorViewProvider : NSObject <PTUErrorViewProvider>

/// Initializes with \c block used whenever the provider is required to supply a view.
- (instancetype)initWithBlock:(PTUErrorViewBlock)block NS_DESIGNATED_INITIALIZER;

/// Initializes with \c view as the view to return for every \c error and \c url pair.
- (instancetype)initWithView:(UIView *)view;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
