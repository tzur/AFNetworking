// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import <Foundation/Foundation.h>
#import <ReactiveCocoa/ReactiveCocoa.h>

/// Project version number for Photons.
FOUNDATION_EXPORT double PhotonsVersionNumber;

/// Project version string for Photons.
FOUNDATION_EXPORT const unsigned char PhotonsVersionString[];

/// Base.
#import <Photons/PTNAlbum.h>
#import <Photons/PTNAlbumChangeset.h>
#import <Photons/PTNAlbumChangesetMove.h>
#import <Photons/PTNAssetManager.h>
#import <Photons/PTNCollection.h>
#import <Photons/PTNDataAsset.h>
#import <Photons/PTNDescriptor.h>
#import <Photons/PTNImageAsset.h>
#import <Photons/PTNImageContentMode.h>
#import <Photons/PTNImageFetchOptions.h>
#import <Photons/PTNImageMetadata.h>
#import <Photons/PTNImageResizer.h>
#import <Photons/PTNProgress.h>
#import <Photons/PTNResizingStrategy.h>

/// Dropbox.
#import <Photons/NSURL+Dropbox.h>
#import <Photons/PTNDropboxEntry.h>
#import <Photons/PTNDropboxPathProvider.h>
#import <Photons/PTNDropboxRestClient.h>

/// File System.
#import <Photons/NSFileManager+FileSystem.h>
#import <Photons/NSURL+FileSystem.h>
#import <Photons/PTNFileSystemAssetManager.h>

/// Multiplexing
#import <Photons/PTNMultiplexerAssetManager.h>

/// PhotoKit.
#import <Photons/NSURL+PhotoKit.h>
#import <Photons/PTNPhotoKitAlbum.h>
#import <Photons/PTNPhotoKitAlbumType.h>
#import <Photons/PTNPhotoKitAssetManager.h>
#import <Photons/PTNPhotoKitFetcher.h>
#import <Photons/PTNPhotoKitImageManager.h>
#import <Photons/PTNPhotoKitObserver.h>
