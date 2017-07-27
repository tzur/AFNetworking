// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTUImageCellViewModel.h"

NS_ASSUME_NONNULL_BEGIN

/// \c PTUImageCellModel implementation using exposed signals used for testing.
@interface PTUFakeImageCellViewModel : NSObject <PTUImageCellViewModel>

/// Initializes with \c imageSignal to be returned by \c imageSignalForCellSize: with any parameter,
/// \c titleSignal, \c subtitleSignal and \c traits or \c nil to expose no cell traits.
- (instancetype)initWithImageSignal:(nullable RACSignal *)imageSignal
                        titleSignal:(nullable RACSignal *)titleSignal
                     subtitleSignal:(nullable RACSignal *)subtitleSignal
                             traits:(nullable NSSet<NSString *> *)traits
    NS_DESIGNATED_INITIALIZER;

/// Signal used as this view model's \c imageSignalForCellSize: with any size.
@property (strong, nonatomic, nullable) RACSignal *imageSignal;

/// Signal used as this view model's \c titleSignal.
@property (strong, nonatomic, nullable) RACSignal *titleSignal;

/// Signal used as this view model's \c subtitleSignal.
@property (strong, nonatomic, nullable) RACSignal *subtitleSignal;

/// Cell traits associated with this view model.
@property (strong, nonatomic) NSSet<NSString *> *traits;

@end

NS_ASSUME_NONNULL_END
