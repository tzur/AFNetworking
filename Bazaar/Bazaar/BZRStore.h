// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRProductsInfoProvider.h"
#import "BZRProductsManager.h"

NS_ASSUME_NONNULL_BEGIN

@class BZRStoreConfiguration;

/// A unified interface for managing an application with in-app store purchases, configured with
/// \c BZRStoreConfiguration. This class is thread safe.
@interface BZRStore : NSObject <BZRProductsInfoProvider, BZRProductsManager>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c configuration, used to configure this class with configuration objects.
/// Upon initializiation, fetching of product list is performed. If there was an error while
/// fetching, it will be sent as an error event with \c eventsSignal.
- (instancetype)initWithConfiguration:(BZRStoreConfiguration *)configuration
    NS_DESIGNATED_INITIALIZER;

/// Sends messages of important events that occur in the receiver. The events can be
/// informational or errors. The signal completes when the receiver is deallocated. The signal
/// doesn't err.
///
/// @return <tt>RACSignal<BZREvent></tt>
@property (readonly, nonatomic) RACSignal *eventsSignal;

@end

NS_ASSUME_NONNULL_END
