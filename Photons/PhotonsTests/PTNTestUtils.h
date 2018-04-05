// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNDescriptor.h"

NS_ASSUME_NONNULL_BEGIN

@protocol LTRandomAccessCollection, PTNAlbum;

@class PTNDisposableRetainingSignal;

/// Creates and returns a \c PTNAlbum with \c url or "foo://bar.baz" if \c nil as the URL of the
/// album, \c assets or an empty collection if \c nil as the assets and \c subalbums or empty
/// collection if \c nil as subalbums.
id<PTNAlbum> PTNCreateAlbum(NSURL * _Nullable url, id<LTRandomAccessCollection> _Nullable assets,
                            id<LTRandomAccessCollection> _Nullable subalbums);

/// Creates and returns a \c PTNDescriptor with \c identifier or \c nil for a default identifier
/// of \c fake://descriptor, \c localizedTitle or \nil for empty localized title, \c capabilities
/// and \c traits or \c nil to support no traits.
id<PTNDescriptor> PTNCreateDescriptor(NSURL * _Nullable identifier,
                                      NSString * _Nullable localizedTitle,
                                      PTNDescriptorCapabilities capabilities,
                                      NSSet<NSString *> * _Nullable traits);

/// Creates and returns a \c PTNAssetDescriptor with \c identifier or \c nil for a default
/// identifier of \c fake://descriptor.asset, \c localizedTitle, \c capabilities, \c traits or
/// \c nil to support no traits, \c creationDate, \c modificationDate, \c filename, zero duration
/// and \c assetCapabilities.
id<PTNAssetDescriptor> PTNCreateAssetDescriptor(NSURL * _Nullable identifier,
                                                NSString * _Nullable localizedTitle,
                                                PTNDescriptorCapabilities capabilities,
                                                NSSet<NSString *> * _Nullable traits,
                                                NSDate * _Nullable creationDate,
                                                NSDate * _Nullable modificationDate,
                                                NSString * _Nullable filename,
                                                PTNAssetDescriptorCapabilities assetCapabilities);

/// Creates and returns a \c PTNAssetDescriptor with \c identifier or \c nil for a default
/// identifier of \c fake://descriptor.asset, \c localizedTitle, \c capabilities, \c traits or
/// \c nil to support no traits, \c creationDate, \c modificationDate, \c filename, \c duration and
/// \c assetCapabilities.
id<PTNAssetDescriptor> PTNCreateAssetDescriptor(NSURL * _Nullable identifier,
                                                NSString * _Nullable localizedTitle,
                                                PTNDescriptorCapabilities capabilities,
                                                NSSet<NSString *> * _Nullable traits,
                                                NSDate * _Nullable creationDate,
                                                NSDate * _Nullable modificationDate,
                                                NSString * _Nullable filename,
                                                NSTimeInterval duration,
                                                PTNAssetDescriptorCapabilities assetCapabilities);

/// Creates and returns a \c PTNAlbumDescriptor with \c identifier or \c nil for a default
/// identifier of \c fake://descriptor.album, \c localizedTitle, \c capabilities, \c traits or
/// \c nil to support no traits, \c assetCount and \c albumCapabilities.
id<PTNAlbumDescriptor> PTNCreateAlbumDescriptor(NSURL * _Nullable identifier,
                                                NSString * _Nullable localizedTitle,
                                                PTNDescriptorCapabilities capabilities,
                                                NSSet<NSString *> * _Nullable traits,
                                                NSUInteger assetCount,
                                                PTNAlbumDescriptorCapabilities albumCapabilities);

/// Creates and returns a \c PTNDescriptor with \c localizedTitle, a \c nil \c identifier and no
/// capabilities or traits.
id<PTNDescriptor> PTNCreateDescriptor(NSString *localizedTitle);

/// Creates and returns a \c PTNAssetDescriptor with \c localizedTitle, a \c nil \c identifier,
/// \c creationDate and \c modificationDate and no capabilities or traits.
id<PTNAssetDescriptor> PTNCreateAssetDescriptor(NSString *localizedTitle);

/// Creates and returns a \c PTNAlbumDescriptor with \c localizedTitle, \c asset count, a \c nil
/// \c identifier and no capabilities or traits.
id<PTNAlbumDescriptor> PTNCreateAlbumDescriptor(NSString *localizedTitle, NSUInteger assetCount);

/// Creates and returns a \c RACSignal that holds bookkeeping of disposables given on subscriptions.
/// This signal sends no events.
PTNDisposableRetainingSignal *PTNCreateDisposableRetainingSignal();

NS_ASSUME_NONNULL_END
