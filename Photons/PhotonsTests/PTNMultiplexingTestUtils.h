// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

NS_ASSUME_NONNULL_BEGIN

/// Returns a fake PTNAssetManager that rejects all requests.
id<PTNAssetManager> PTNCreateRejectingManager();

/// Returns a fake PTNAssetManager that returns \c value for any request made to it.
id<PTNAssetManager> PTNCreateAcceptingManager(RACSignal * _Nullable value);

NS_ASSUME_NONNULL_END
