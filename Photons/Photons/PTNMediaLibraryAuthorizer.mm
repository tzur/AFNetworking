// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Michael Kimyagarov.

#import "PTNMediaLibraryAuthorizer.h"

NS_ASSUME_NONNULL_BEGIN

@implementation PTNMediaLibraryAuthorizer

- (void)requestAuthorization:(PTNMediaLibraryAuthorizationStatusHandler)handler {
  [MPMediaLibrary requestAuthorization:handler];
}

- (MPMediaLibraryAuthorizationStatus)authorizationStatus {
  return [MPMediaLibrary authorizationStatus];
}

@end

NS_ASSUME_NONNULL_END
