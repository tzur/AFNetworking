// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

NS_ASSUME_NONNULL_BEGIN

/// View model object mapping signals of \c UIImage and \c NSString objects into managable
/// properties to be observed by the cell.
@protocol PTUImageCellViewModel

/// Currently set title. Guaranteed to change on the main thread.
@property (readonly, nonatomic, nullable) NSString *title;

/// Currently set subtitle. Guaranteed to change on the main thread.
@property (readonly, nonatomic, nullable) NSString *subtitle;

/// Currently set image. Guaranteed to change on the main thread.
@property (readonly, nonatomic, nullable) UIImage *image;

@end

/// Implementation of \c PTUImageCellViewModel that receievs signals upon initialization and updates
/// values according to latest values sent on the signals.
@interface PTUImageCellViewModel : NSObject <PTUImageCellViewModel>

- (instancetype)init NS_UNAVAILABLE;

/// Initialize with \c imageSignal to determine the \c image property, \c titleSignal to determine
/// the \c title property and \c subtitleSignal to determine the \c subtitle property. All errors
/// and invalid value types on these signals are ignored, and the latest valid value is set.
- (instancetype)initWithImageSignal:(RACSignal *)imageSignal titleSignal:(RACSignal *)titleSignal
                     subtitleSignal:(RACSignal *)subtitleSignal;

@end

NS_ASSUME_NONNULL_END
