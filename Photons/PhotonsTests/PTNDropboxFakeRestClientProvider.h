// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNDropboxRestClientProvider.h"

NS_ASSUME_NONNULL_BEGIN

/// Fake \c PTNDropboxRestClientProvder implementation for easy testing.
@interface PTNDropboxFakeRestClientProvider : NSObject <PTNDropboxRestClientProvider>

/// Initializes with \c client as \c restClient.
- (instancetype)initWithClient:(nullable DBRestClient *)client NS_DESIGNATED_INITIALIZER;

/// Retuned \c DBRestClient when calling \c -ptn_restClient. Default value is \c nil.
@property (strong, nonatomic, nullable) DBRestClient *restClient;

/// Returned link status when calling \c -isLinked. Default value is \c YES.
@property (nonatomic) BOOL isLinked;

@end

NS_ASSUME_NONNULL_END
