// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Dekel Avrahami.

#import "EUISMYourPlanViewModel.h"

NS_ASSUME_NONNULL_BEGIN

/// Fake implementation of \c EUISMYourPlanViewModel used for testing.
@interface EUISMFakeYourPlanViewModel : NSObject <EUISMYourPlanViewModel>
@property (readwrite, nonatomic) NSString *title;
@property (readwrite, nonatomic) NSString *subtitle;
@property (readwrite, nonatomic) NSString *body;
@end

NS_ASSUME_NONNULL_END
