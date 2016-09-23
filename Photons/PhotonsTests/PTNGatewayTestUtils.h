// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNGatewayAlbumDescriptor.h"

NS_ASSUME_NONNULL_BEGIN

@class PTNGatewayAlbumDescriptor;

/// Creates a fake \c PTNGatewayAlbumDescriptor for testing. The descriptor's identifier is a
/// gateway URL created with \c key. \c albumSignal is the signal returned by the corresponding
/// property. \c imageSignal is returned for every resizing strategy and options combination.
PTNGatewayAlbumDescriptor *PTNGatewayCreateAlbumDescriptorWithSignal(NSString *key,
                                                                     RACSignal *albumSignal,
                                                                     RACSignal *imageSignal);

/// Creates a fake \c PTNGatewayAlbumDescriptor for testing. The descriptor's identifier is a
/// gateway URL created with \c key. \c albumSignal is the signal returned by the corresponding
/// property. \c imageSignalBlock is set as the \c imageSignalBlock of the descriptor.
PTNGatewayAlbumDescriptor *PTNGatewayCreateAlbumDescriptor(NSString *key, RACSignal *albumSignal,
    PTNGatewayImageSignalBlock imageSignalBlock);

NS_ASSUME_NONNULL_END
