// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNDescriptor.h"

NS_ASSUME_NONNULL_BEGIN

@protocol LTRandomAccessCollection, PTNAlbum;

@class PTNDisposableRetainingSignal;

/// Creates and returns a \c PTNAlbum with \c url, \c assets and \c subalbums.
id<PTNAlbum> PTNCreateAlbum(NSURL * _Nullable url, id<LTRandomAccessCollection> _Nullable assets,
                            id<LTRandomAccessCollection> _Nullable subalbums);

/// Creates and returns a \c PTNDescriptor with \c identifier, \c localizedTitle and
/// \c capabilities.
id<PTNDescriptor> PTNCreateDescriptor(NSURL * _Nullable identifier,
                                      NSString * _Nullable localizedTitle,
                                      PTNDescriptorCapabilities capabilites);

/// Creates and returns a \c PTNAssetDescriptor with \c identifier, \c localizedTitle,
/// \c capabilities, \c creationDate, \c modificationDate and \c assetCapabilities.
id<PTNAssetDescriptor> PTNCreateAssetDescriptor(NSURL * _Nullable identifier,
                                                NSString * _Nullable localizedTitle,
                                                PTNDescriptorCapabilities capabilites,
                                                NSDate * _Nullable creationDate,
                                                NSDate * _Nullable modificationDate,
                                                PTNAssetDescriptorCapabilities assetCapabilities);

/// Creates and returns a \c RACSignal that holds bookkeeping of disposables given on subscriptions.
/// This signal sends no events.
PTNDisposableRetainingSignal *PTNCreateDisposableRetainingSignal();

NS_ASSUME_NONNULL_END
