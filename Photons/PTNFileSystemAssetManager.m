// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "PTNFileSystemAssetManager.h"

#import <LTKit/LTPath.h>

#import "NSError+Photons.h"
#import "NSURL+FileSystem.h"
#import "PTNAlbumChangeset.h"
#import "PTNCollection.h"
#import "PTNFileSystemAlbum.h"
#import "PTNFileSystemDirectoryDescriptor.h"
#import "PTNFileSystemFileManager.h"
#import "PTNFileSystemFileDescriptor.h"
#import "PTNImageContainer.h"
#import "PTNImageFetchOptions.h"
#import "PTNImageMetadata.h"
#import "PTNImageResizer.h"
#import "PTNProgress.h"
#import "PTNResizingStrategy.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTNFileSystemAssetManager ()

/// Used for shallow iteration of a file system and fetching files and directories.
@property (strong, nonatomic) id<PTNFileSystemFileManager> fileManager;

/// Used for resizing local images.
@property (strong, nonatomic) PTNImageResizer *imageResizer;

@end

@implementation PTNFileSystemAssetManager

- (instancetype)initWithFileManager:(id<PTNFileSystemFileManager>)fileManager
                       imageResizer:(PTNImageResizer *)imageResizer {
  if (self = [super init]) {
    self.fileManager = fileManager;
    self.imageResizer = imageResizer;
  }
  return self;
}

#pragma mark -
#pragma mark Album fetching
#pragma mark -

- (RACSignal *)fetchAlbumWithURL:(NSURL *)url {
  if (url.ptn_fileSystemURLType != PTNFileSystemURLTypeAlbum) {
    return [RACSignal error:[NSError lt_errorWithCode:PTNErrorCodeInvalidURL url:url]];
  }

  return [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    NSError *error;
    NSArray *contents =
        [self.fileManager contentsOfDirectoryAtURL:url.ptn_fileSystemAlbumPath.url
                        includingPropertiesForKeys:@[NSURLIsDirectoryKey, NSURLNameKey]
                                           options:NSDirectoryEnumerationSkipsHiddenFiles
                                             error:&error];
    if (error) {
      [subscriber sendError:[NSError lt_errorWithCode:PTNErrorCodeAlbumNotFound url:url
                                     underlyingError:error]];
      return nil;
    } else if (!contents) {
      [subscriber sendError:[NSError lt_errorWithCode:PTNErrorCodeAlbumNotFound url:url]];
      return nil;
    }

    LTPath *path = url.ptn_fileSystemAlbumPath;
    NSArray *subdirectories = [self subdirectoriesFromContents:contents withPath:path];
    NSArray *files = [self imageFilesFromContents:contents withPath:path];

    id<PTNAlbum> album = [[PTNFileSystemAlbum alloc] initWithPath:url subdirectories:subdirectories
                                                            files:files];
    PTNAlbumChangeset *changeset = [PTNAlbumChangeset changesetWithAfterAlbum:album];

    [subscriber sendNext:changeset];
    [subscriber sendCompleted];
    return nil;
  }] subscribeOn:[RACScheduler scheduler]];
}

- (NSArray *)subdirectoriesFromContents:(NSArray *)contents withPath:(LTPath *)path {
  return [[self pathSequenceFromContents:contents withPath:path keepDirectories:YES]
      map:^(LTPath *path) {
        return [[PTNFileSystemDirectoryDescriptor alloc] initWithPath:path];
      }].array;
}

- (NSArray *)imageFilesFromContents:(NSArray *)contents withPath:(LTPath *)path {
  return [[[self pathSequenceFromContents:contents withPath:path keepDirectories:NO]
      filter:^BOOL(LTPath *path) {
        return [[self.class imageFileExtensions]
                containsObject:path.path.pathExtension.lowercaseString];
      }]
      map:^(LTPath *path) {
        return [[PTNFileSystemFileDescriptor alloc] initWithPath:path];
      }].array;
}

- (RACSequence *)pathSequenceFromContents:(NSArray *)contents withPath:(LTPath *)path
                          keepDirectories:(BOOL)keepDirectories {
  return [[contents.rac_sequence
      filter:^BOOL(NSURL *item) {
        NSNumber *isDirectory;
        [item getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:nil];

        return keepDirectories ? isDirectory.boolValue : !isDirectory.boolValue;
      }] map:^LTPath *(NSURL *item) {
        NSString *name;
        [item getResourceValue:&name forKey:NSURLNameKey error:nil];

        NSString *relativePath = [path.relativePath stringByAppendingPathComponent:name];

        return [LTPath pathWithBaseDirectory:path.baseDirectory andRelativePath:relativePath];
      }];
}

+ (NSArray *)imageFileExtensions {
  static NSArray *extensions;

  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    extensions = @[@"jpg", @"jpeg", @"png", @"tiff"];
  });

  return extensions;
}

#pragma mark -
#pragma mark Asset fetching
#pragma mark -

- (RACSignal *)fetchAssetWithURL:(NSURL *)url {
  if (url.ptn_fileSystemURLType != PTNFileSystemURLTypeAsset) {
    return [RACSignal error:[NSError lt_errorWithCode:PTNErrorCodeInvalidURL url:url]];
  }

  return [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    BOOL isDirectory;
    BOOL fileExists = [self.fileManager fileExistsAtPath:url.ptn_fileSystemAssetPath.path
                                             isDirectory:&isDirectory];

    if (!fileExists || isDirectory) {
      [subscriber sendError:[NSError lt_errorWithCode:PTNErrorCodeAssetNotFound url:url]];
      return nil;
    }

    id<PTNDescriptor> asset = [[PTNFileSystemFileDescriptor alloc]
                               initWithPath:url.ptn_fileSystemAssetPath];

    [subscriber sendNext:asset];
    [subscriber sendCompleted];
    return nil;
  }] subscribeOn:[RACScheduler scheduler]];
}

- (RACSignal *)fetchKeyAssetForDirectoryURL:(NSURL *)url {
  return [[self fetchAlbumWithURL:url] flattenMap:^(PTNAlbumChangeset *changeset) {
    PTNFileSystemFileDescriptor *keyAsset = changeset.afterAlbum.assets.firstObject;
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
  RACSignal *assetContent = [self fetchImageContentForDescriptor:descriptor
                                                resizingStrategy:resizingStrategy
                                                         options:options];
  if (!options.fetchMetadata) {
    return [assetContent subscribeOn:RACScheduler.scheduler];
  }

  return [[assetContent
      flattenMap:^(PTNProgress<PTNImageContainer *> *progress) {
        return [self attachMetadataOfDescriptor:descriptor toImage:progress.result.image];
      }]
      subscribeOn:RACScheduler.scheduler];
}

- (RACSignal *)fetchImageContentForDescriptor:(id<PTNDescriptor>)descriptor
                             resizingStrategy:(id<PTNResizingStrategy>)resizingStrategy
                                      options:(PTNImageFetchOptions *)options {
  if (![descriptor isKindOfClass:[PTNFileSystemFileDescriptor class]] &&
      ![descriptor isKindOfClass:[PTNFileSystemDirectoryDescriptor class]]) {
    return [RACSignal error:[NSError ptn_errorWithCode:PTNErrorCodeInvalidDescriptor
                                  associatedDescriptor:descriptor]];
  }

  if ([descriptor isKindOfClass:[PTNFileSystemDirectoryDescriptor class]]) {
    return [[self fetchKeyAssetForDirectoryURL:descriptor.ptn_identifier]
        flattenMap:^(PTNFileSystemFileDescriptor *file) {
          return [self fetchImageContentForDescriptor:file resizingStrategy:resizingStrategy
                                              options:options];
        }];
  }

  NSURL *filePath = descriptor.ptn_identifier.ptn_fileSystemAssetPath.url;
  return [[[self.imageResizer resizeImageAtURL:filePath resizingStrategy:resizingStrategy]
      map:^(UIImage *image) {
        PTNImageContainer *container = [[PTNImageContainer alloc] initWithImage:image];
        return [[PTNProgress alloc] initWithResult:container];
      }]
      catch:^(NSError *resizeError) {
        NSError *wrappedError = [NSError lt_errorWithCode:PTNErrorCodeAssetLoadingFailed
                                                      url:descriptor.ptn_identifier
                                          underlyingError:resizeError];
        return [RACSignal error:wrappedError];
      }];
}

- (RACSignal *)attachMetadataOfDescriptor:(id<PTNDescriptor>)descriptor toImage:(UIImage *)image {
  return [[self fetchMetadataForDescriptor:descriptor]
      map:^(PTNImageMetadata *metadata) {
        PTNImageContainer *imageContainer = [[PTNImageContainer alloc]
                                             initWithImage:image metadata:metadata];
        return [[PTNProgress alloc] initWithResult:imageContainer];
      }];
}

- (RACSignal *)fetchMetadataForDescriptor:(id<PTNDescriptor>)descriptor {
  return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    NSURL *filePath = descriptor.ptn_identifier.ptn_fileSystemAssetPath.url;
    NSError *metadataError;
    PTNImageMetadata *metadata = [[PTNImageMetadata alloc] initWithImageURL:filePath
                                                                      error:&metadataError];
    if (metadataError) {
      NSError *wrappedError = [NSError lt_errorWithCode:PTNErrorCodeAssetMetadataLoadingFailed
                                                    url:descriptor.ptn_identifier
                                        underlyingError:metadataError];
      [subscriber sendError:wrappedError];
      return nil;
    }

    [subscriber sendNext:metadata];
    [subscriber sendCompleted];
    return nil;
  }];
}

@end

NS_ASSUME_NONNULL_END
