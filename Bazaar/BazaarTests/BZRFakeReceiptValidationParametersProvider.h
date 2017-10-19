// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRReceiptValidationParametersProvider.h"

NS_ASSUME_NONNULL_BEGIN

/// Fake receipt validation parameters provider with stub \c receiptValidationParameters.
@interface BZRFakeReceiptValidationParametersProvider :
    NSObject <BZRReceiptValidationParametersProvider>

/// Subject used to send events with.
@property (readonly, nonatomic) RACSubject *eventsSubject;

@end

NS_ASSUME_NONNULL_END
