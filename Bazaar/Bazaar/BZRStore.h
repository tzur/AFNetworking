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
/// fetching, it will be sent with \c errorsSignal.
- (instancetype)initWithConfiguration:(BZRStoreConfiguration *)configuration
    NS_DESIGNATED_INITIALIZER;

/// Sends errors reported by underlying modules used by the receiver. The signal completes when the
/// receiver is deallocated. The signal doesn't err.
///
/// @return <tt>RACSignal<NSError></tt>
@property (readonly, nonatomic) RACSignal *errorsSignal;

@end

NS_ASSUME_NONNULL_END
