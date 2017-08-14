// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTUImageCell.h"

NS_ASSUME_NONNULL_BEGIN

@class PTUImageCellController;

/// Delegate of a \c PTUImageCellController allowing for simple assignment of cell view properties
/// without signal overhead.
@protocol PTUImageCellControllerDelegate <NSObject>

/// Called with \c imageCellController and \c image whenever a new image was loaded and should be
/// displayed. \c image will be set to \c nil if no image should be displayed.
- (void)imageCellController:(PTUImageCellController *)imageCellController
                loadedImage:(nullable UIImage *)image;

@optional

/// Called with \c imageCellController and \c title whenever a new title was loaded and should be
/// displayed. \c title will be set to \c nil if no title should be displayed.
- (void)imageCellController:(PTUImageCellController *)imageCellController
                loadedTitle:(nullable NSString *)title;

/// Called with \c imageCellController and \c subtitle whenever a new subtitle was loaded and should
/// be displayed. \c subtitle will be set to \c nil if no subtitle should be displayed.
- (void)imageCellController:(PTUImageCellController *)imageCellController
             loadedSubtitle:(nullable NSString *)subtitle;

/// Called with \c imageCellController and \c duration whenever a new duration was loaded and should
/// be displayed. \c duration will be set to \c nil if no duration should be displayed.
- (void)imageCellController:(PTUImageCellController *)imageCellController
             loadedDuration:(nullable NSString *)duration;

/// Called with \c imageCellController and the appropriate \c error whenever an error occurred while
/// attempting to fetch image from latest view model set in \c setViewModel:.
- (void)imageCellController:(PTUImageCellController *)imageCellController
          errorLoadingImage:(NSError *)error;

/// Called with \c imageCellController and the appropriate \c error whenever an error occurred while
/// attempting to fetch title from latest view model set in \c setViewModel:.
- (void)imageCellController:(PTUImageCellController *)imageCellController
          errorLoadingTitle:(NSError *)error;

/// Called with \c imageCellController and the appropriate \c error whenever an error occurred while
/// attempting to fetch subtitle from latest view model set in \c setViewModel:.
- (void)imageCellController:(PTUImageCellController *)imageCellController
       errorLoadingSubtitle:(NSError *)error;

/// Called with \c imageCellController and the appropriate \c error whenever an error occurred while
/// attempting to fetch duration from latest view model set in \c setViewModel:.
- (void)imageCellController:(PTUImageCellController *)imageCellController
       errorLoadingDuration:(NSError *)error;

@end

/// Controller of an image cell, allowing it to be efficiently set according to a
/// \c PTUImageCellViewModel with minimum overhead caused by subscriptions and signal management.
///
/// The controller efficiently subscribes and manually disposes the various \c viewController
/// signals and sends their values to its \c delegate.
@interface PTUImageCellController : NSObject

/// Delegate receiving values from the latest view model values and replacements.
@property (weak, nonatomic) id<PTUImageCellControllerDelegate> delegate;

/// View model to determine the properties displayed by this cell. Changing the view model will
/// first set all the relevant properties to \c nil followed by the latest value sent from each
/// signal of the \c viewModel. All values are explicitly delivered on the main thread. Current
/// \c viewModel image signal will be queried and used each time the \c imageSize changes.
@property (strong, nonatomic, nullable) id<PTUImageCellViewModel> viewModel;

/// Current size of image that should be fetched in pixels. Setting this will refetch the image of
/// the currently set view model if the new \c imageSize is different than the current. Additionally
/// it will be used in subsequent fetches from new view models. The initial value is
/// <tt>(0, 0)</tt>.
@property (nonatomic) CGSize imageSize;

@end

NS_ASSUME_NONNULL_END
