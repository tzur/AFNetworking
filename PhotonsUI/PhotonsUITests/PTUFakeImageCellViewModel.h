// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTUImageCellViewModel.h"

NS_ASSUME_NONNULL_BEGIN

/// \c PTUImageCellModel implementation using exposed signals used for testing.
@interface PTUFakeImageCellViewModel : NSObject <PTUImageCellViewModel>

/// Initializes with \c imageSignal to be returned by \c imageSignalForCellSize: with any parameter,
/// \c titleSignal and \c subtitleSignal.
- (instancetype)initWithImageSignal:(nullable RACSignal *)imageSignal
                        titleSignal:(nullable RACSignal *)titleSignal
                     subtitleSignal:(nullable RACSignal *)subtitleSignal NS_DESIGNATED_INITIALIZER;

/// Signal used as this view model's \c imageSignalForCellSize: with any size.
@property (strong, nonatomic) RACSignal *imageSignal;

/// Signal used as this view model's \c titleSignal.
@property (strong, nonatomic) RACSignal *titleSignal;

/// Signal used as this view model's \c subtitleSignal.
@property (strong, nonatomic) RACSignal *subtitleSignal;

@end

NS_ASSUME_NONNULL_END
