// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

NS_ASSUME_NONNULL_BEGIN

@protocol PTNAssetManager, PTNDescriptor;

/// Protocol for collection view image cells view models to conform to in order to be used by the
/// Photons framework.
@protocol PTUImageCellViewModel <NSObject>

/// Returns a signal carrying latest image to dispay in a cell of size \c cellSize in pixels, or
/// \c nil if no image should be set for such a cell.
- (nullable RACSignal *)imageSignalForCellSize:(CGSize)cellSize;

/// Signal carrying title to display, or \c nil if no values should be set for the title to display,
/// and it should be set to \c nil.
@property (readonly, nonatomic, nullable) RACSignal *titleSignal;

/// Signal carrying subtitle to display, or \c nil if no values should be set for the subtitle to
/// display, and it should be set to \c nil.
@property (readonly, nonatomic, nullable) RACSignal *subtitleSignal;

@end

/// \c PTUImageCellViewModel implementation mapping signals of \c UIImage and \c NSString objects
/// into properties required by the protocol.
@interface PTUImageCellViewModel : NSObject <PTUImageCellViewModel>

- (instancetype)init NS_UNAVAILABLE;

/// Initialize with \c imageSignal to determine the \c image property, \c titleSignal to determine
/// the \c title property and \c subtitleSignal to determine the \c subtitle property. If any of
/// the signals are \c nil the value represented by that signal will remain \c nil and will not
/// update.
- (instancetype)initWithImageSignal:(nullable RACSignal *)imageSignal
                        titleSignal:(nullable RACSignal *)titleSignal
                     subtitleSignal:(nullable RACSignal *)subtitleSignal NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
