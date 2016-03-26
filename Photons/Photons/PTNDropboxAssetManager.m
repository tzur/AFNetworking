// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNDropboxAssetManager.h"

#import <DropboxSDK/DropboxSDK.h>
#import <LTKit/LTBidirectionalMap.h>
#import <LTKit/LTPath.h>

#import "NSError+Photons.h"
#import "NSURL+Dropbox.h"
#import "NSURL+PTNResizingStrategy.h"
#import "PTNAlbumChangeset.h"
#import "PTNCollection.h"
#import "PTNDropboxAlbum.h"
#import "PTNDropboxDirectoryDescriptor.h"
#import "PTNDropboxEntry.h"
#import "PTNDropboxFileDescriptor.h"
#import "PTNDropboxRestClient.h"
#import "PTNDropboxRestClientProvider.h"
#import "PTNDropboxThumbnail.h"
#import "PTNFileBackedImageAsset.h"
#import "PTNImageFetchOptions.h"
#import "PTNImageResizer.h"
#import "PTNProgress.h"
#import "PTNResizingStrategy.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTNDropboxAssetManager ()

/// Dropbox session to used to access Dropbox files.
@property (readonly, nonatomic) PTNDropboxRestClient *client;

/// Image resizer to use when creating image assets.
@property (readonly, nonatomic) PTNImageResizer *imageResizer;

/// File manager to use when creating image assets.
@property (readonly, nonatomic) NSFileManager *fileManager;

@end

@implementation PTNDropboxAssetManager

- (instancetype)initWithDropboxClient:(PTNDropboxRestClient *)dropboxClient
                         imageResizer:(PTNImageResizer *)imageResizer
                          fileManager:(NSFileManager *)fileManager {
  if (self = [super init]) {
    _client = dropboxClient;
    _imageResizer = imageResizer;
    _fileManager = fileManager;
  }
  return self;
}

#pragma mark -
#pragma mark Album Fetching
#pragma mark -

- (RACSignal *)fetchAlbumWithURL:(NSURL *)url {
  if (url.ptn_dropboxURLType != PTNDropboxURLTypeAlbum) {
    return [RACSignal error:[NSError lt_errorWithCode:PTNErrorCodeInvalidURL url:url]];
  }

  PTNDropboxEntry *entry = url.ptn_dropboxAlbumEntry;
  return [[[self.client fetchMetadata:entry.path revision:nil]
      flattenMap:^id(DBMetadata *metadata) {
        if (!metadata.isDirectory) {
          return [RACSignal error:[NSError lt_errorWithCode:PTNErrorCodeAlbumNotFound url:url]];
        }

        NSURL *albumURL = [NSURL ptn_dropboxAlbumURLWithEntry:url.ptn_dropboxAlbumEntry];
        PTNDropboxAlbum *album = [self albumFromMetadata:metadata path:albumURL];
        return [RACSignal return:[PTNAlbumChangeset changesetWithAfterAlbum:album]];
      }]
      catch:^RACSignal *(NSError *error) {
        return [RACSignal error:[NSError lt_errorWithCode:PTNErrorCodeAlbumNotFound url:url
                                          underlyingError:error]];
      }];
}

- (PTNDropboxAlbum *)albumFromMetadata:(DBMetadata *)metadata path:(NSURL *)path {
  NSArray *subdirectories = [[[metadata.contents rac_sequence]
      filter:^BOOL(DBMetadata *metadata) {
        return metadata.isDirectory;
      }]
      map:^id(DBMetadata *metadata) {
        return [[PTNDropboxDirectoryDescriptor alloc] initWithMetadata:metadata];
      }].array;

  NSArray *files = [[[metadata.contents rac_sequence]
      filter:^BOOL(DBMetadata *metadata) {
        return !metadata.isDirectory;
      }]
      map:^id(DBMetadata *metadata) {
        return [[PTNDropboxFileDescriptor alloc] initWithMetadata:metadata];
      }].array;

  return [[PTNDropboxAlbum alloc] initWithPath:path subdirectories:subdirectories files:files];
}

#pragma mark -
#pragma mark Asset fetching
#pragma mark -

- (RACSignal *)fetchAssetWithURL:(NSURL *)url {
  if (url.ptn_dropboxURLType != PTNDropboxURLTypeAsset) {
    return [RACSignal error:[NSError lt_errorWithCode:PTNErrorCodeInvalidURL url:url]];
  }

  PTNDropboxEntry *entry = url.ptn_dropboxAssetEntry;
  return [[[self.client fetchMetadata:entry.path revision:entry.revision]
      map:^id(DBMetadata *metadata) {
        return metadata.isDirectory ?
            [[PTNDropboxDirectoryDescriptor alloc] initWithMetadata:metadata] :
            [[PTNDropboxFileDescriptor alloc] initWithMetadata:metadata];
      }]
      catch:^RACSignal *(NSError *error) {
        return [RACSignal error:[NSError lt_errorWithCode:PTNErrorCodeAssetLoadingFailed url:url
                                          underlyingError:error]];
      }];
}

- (RACSignal *)fetchKeyAssetForDirectoryURL:(NSURL *)url {
  return [[self fetchAlbumWithURL:url]
      flattenMap:^(PTNAlbumChangeset *changeset) {
        PTNDropboxFileDescriptor *keyAsset = changeset.afterAlbum.assets.firstObject;
        if (!keyAsset) {
          return [RACSignal error:[NSError lt_errorWithCode:PTNErrorCodeKeyAssetsNotFound url:url]];
        }
        return [RACSignal return:keyAsset];
      }];
}

#pragma mark -
#pragma mark Image fetching
#pragma mark -

- (RACSignal *)fetchImageWithDescriptor:(id<PTNDescriptor>)descriptor
                       resizingStrategy:(id<PTNResizingStrategy>)resizingStrategy
                                options:(PTNImageFetchOptions *)options {
  if (![descriptor isKindOfClass:[PTNDropboxFileDescriptor class]] &&
      ![descriptor isKindOfClass:[PTNDropboxDirectoryDescriptor class]]) {
    return [RACSignal error:[NSError ptn_errorWithCode:PTNErrorCodeInvalidDescriptor
                                  associatedDescriptor:descriptor]];
  }

  if ([descriptor isKindOfClass:[PTNDropboxDirectoryDescriptor class]]) {
    return [[self fetchKeyAssetForDirectoryURL:descriptor.ptn_identifier]
        flattenMap:^(PTNDropboxFileDescriptor *file) {
          return [self fetchImageContentWithEntry:file.ptn_identifier.ptn_dropboxAssetEntry
                                 resizingStrategy:resizingStrategy
                                          options:options];
        }];
  }

  PTNDropboxEntry *entry = descriptor.ptn_identifier.ptn_dropboxAssetEntry;
  return [[self fetchImageContentWithEntry:entry
                          resizingStrategy:resizingStrategy
                                   options:options]
      catch:^RACSignal *(NSError *error) {
        return [RACSignal error:[NSError lt_errorWithCode:PTNErrorCodeAssetLoadingFailed
                                                      url:descriptor.ptn_identifier
                                          underlyingError:error]];
      }];
}

- (RACSignal *)fetchImageContentWithEntry:(PTNDropboxEntry *)entry
                         resizingStrategy:(id<PTNResizingStrategy>)resizingStrategy
                                  options:(PTNImageFetchOptions *)options {
  RACSignal *highQualitySignal = [self fetchHighQualityImageForEntry:entry
                                                    resizingStrategy:resizingStrategy];
  if (entry.revision || options.deliveryMode == PTNImageDeliveryModeHighQuality) {
    return highQualitySignal;
  }

  RACSignal *lowQualitySignal = [self fetchLowQualityImageForEntry:entry
                                                  resizingStrategy:resizingStrategy];

  switch (options.deliveryMode) {
    case PTNImageDeliveryModeFast:
      return lowQualitySignal;
    case PTNImageDeliveryModeHighQuality:
      return highQualitySignal;
    case PTNImageDeliveryModeOpportunistic:
      return [lowQualitySignal takeUntilReplacement:highQualitySignal];
  }
}

- (RACSignal *)fetchLowQualityImageForEntry:(PTNDropboxEntry *)entry
                           resizingStrategy:(id<PTNResizingStrategy>)resizingStrategy {
  RACSignal *thumbnailSignal = [self.client fetchThumbnail:entry.path
      type:[PTNDropboxThumbnailType enumWithValue:PTNDropboxThumbnailTypeExtraSmall]];
  return [self imageAssetSignalFromPathSignal:thumbnailSignal
                          andResizingStrategy:resizingStrategy];
}

- (RACSignal *)fetchHighQualityImageForEntry:(PTNDropboxEntry *)entry
                            resizingStrategy:(id<PTNResizingStrategy>)resizingStrategy {
  // If the \c latest revision is requested, attempt to optimize by fetching a thumbnail large
  // enough to bound the requested size from above.
  if (!entry.revision) {
    for (PTNDropboxThumbnailType *type in [PTNDropboxThumbnailType fields]) {
      if ([resizingStrategy inputSizeBoundedBySize:type.size]) {
        RACSignal *matchingThumbnail = [self.client fetchThumbnail:entry.path type:type];
        return [self imageAssetSignalFromPathSignal:matchingThumbnail
                                andResizingStrategy:resizingStrategy];
      }
    }
  }

  // Requested specific revision or an image size larger than the largest thumbnail available and
  // therefore fetch the original image.
  return [[self.client fetchFile:entry.path revision:entry.revision]
      flattenMap:^(PTNProgress<NSString *> *progress) {
        if (!progress.result) {
          return [RACSignal return:progress];
        }

        return [self imageAssetSignalFromPathSignal:[RACSignal return:progress.result]
                                andResizingStrategy:resizingStrategy];
      }];
}

- (RACSignal *)imageAssetSignalFromPathSignal:(RACSignal *)pathSignal
                          andResizingStrategy:(id<PTNResizingStrategy>)resizingStrategy {
  return [pathSignal map:^(NSString *path) {
    PTNFileBackedImageAsset *imageAsset =
        [[PTNFileBackedImageAsset alloc] initWithFilePath:[LTPath pathWithPath:path]
                                              fileManager:self.fileManager
                                             imageResizer:self.imageResizer
                                         resizingStrategy:resizingStrategy];
    return [[PTNProgress alloc] initWithResult:imageAsset];
  }];
}

@end

NS_ASSUME_NONNULL_END
