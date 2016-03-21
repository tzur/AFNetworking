// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

NS_ASSUME_NONNULL_BEGIN

@class PTNGatewayAlbumDescriptor;

/// Creates a fake \c PTNGatewayAlbumDescriptor for testing. The descriptor's identifier is a
/// gateway URL created with \c key. \c albumSignal and \c imageSignal are the signals returned
/// by the corresponding properties.
PTNGatewayAlbumDescriptor *PTNGatewayCreateAlbumDescriptor(NSString *key,
                                                           RACSignal * _Nullable albumSignal,
                                                           RACSignal * _Nullable imageSignal);

NS_ASSUME_NONNULL_END
