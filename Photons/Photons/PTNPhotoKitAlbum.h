// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "PTNAlbum.h"

NS_ASSUME_NONNULL_BEGIN

@class PHFetchResult;

@interface PTNPhotoKitAlbum : NSObject <PTNAlbum>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes a PhotoKit album identified by the given \c url and a fetch result. The given \c url
/// must be of type \c PTNPhotoKitURLTypeAlbum or \c PTNPhotoKitURLTypeAlbumType. If the type is
/// \c PTNPhotoKitURLTypeAlbum, the newly created album will contain assets only, and an empty \c
/// subalbums collection. If the type is \c PTNPhotoKitURLTypeAlbumType, the newly created album
/// will contain subalbums only, and an empty \c assets collection.
- (instancetype)initWithURL:(NSURL *)url fetchResult:(PHFetchResult *)fetchResult
    NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
