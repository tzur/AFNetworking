// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import <DropboxSDK/DropboxSDK.h>

#import "PTNDropboxRestClientProvider.h"

NS_ASSUME_NONNULL_BEGIN

/// Category for \c DBSession conforming to the \c PTNDropboxRestClientProvider protocol.
@interface DBSession (Photons) <PTNDropboxRestClientProvider>
@end

NS_ASSUME_NONNULL_END
