// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "PTNFileSystemAssetManager.h"

#import <AVFoundation/AVFoundation.h>
#import <LTKit/LTPath.h>
#import <LTKit/LTRandomAccessCollection.h>

#import "NSError+Photons.h"
#import "NSURL+FileSystem.h"
#import "PTNAVImageAsset.h"
#import "PTNAlbum.h"
#import "PTNAlbumChangeset.h"
#import "PTNAudiovisualAsset.h"
#import "PTNFileBackedAVAsset.h"
#import "PTNFileBackedImageAsset.h"
#import "PTNFileSystemDirectoryDescriptor.h"
#import "PTNFileSystemFileDescriptor.h"
#import "PTNFileSystemFileManager.h"
#import "PTNImageFetchOptions.h"
#import "PTNImageMetadata.h"
#import "PTNImageResizer.h"
#import "PTNProgress.h"
#import "PTNResizingStrategy.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTNFileSystemAssetManager ()

/// Used for shallow iteration of a file system and fetching files and directories.
@property (readonly, nonatomic) id<PTNFileSystemFileManager> fileManager;

/// Used for resizing local images.
@property (readonly, nonatomic) PTNImageResizer *imageResizer;

@end

@implementation PTNFileSystemAssetManager

- (instancetype)initWithFileManager:(id<PTNFileSystemFileManager>)fileManager
                       imageResizer:(PTNImageResizer *)imageResizer {
  if (self = [super init]) {
    _fileManager = fileManager;
    _imageResizer = imageResizer;
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

    id<PTNAlbum> album = [[PTNAlbum alloc] initWithURL:url subalbums:subdirectories
                                                assets:files];
    PTNAlbumChangeset *changeset = [PTNAlbumChangeset changesetWithAfterAlbum:album];

    [subscriber sendNext:changeset];
    [subscriber sendCompleted];
    return nil;
  }] subscribeOn:[RACScheduler scheduler]];
}

- (NSArray *)subdirectoriesFromContents:(NSArray<NSURL *> *)contents withPath:(LTPath *)path {
  return [[self urlSequenceFromContents:contents keepDirectories:YES]
      map:^(NSURL *item) {
        LTPath *descriptorPath = [self descriptorPathFromContentURL:item andPath:path];
        return [[PTNFileSystemDirectoryDescriptor alloc] initWithPath:descriptorPath];
      }].array;
}

- (NSArray *)imageFilesFromContents:(NSArray<NSURL *> *)contents withPath:(LTPath *)path {
  return [[[self urlSequenceFromContents:contents keepDirectories:NO]
      filter:^BOOL(NSURL *item) {
        NSString * _Nullable UTI;
        BOOL success = [item getResourceValue:&UTI forKey:NSURLTypeIdentifierKey error:nil];
        return (success && [[self.class supportedUTIs] containsObject:UTI]);
      }]
      map:^(NSURL *item) {
        LTPath *descriptorPath = [self descriptorPathFromContentURL:item andPath:path];
        return [[PTNFileSystemFileDescriptor alloc] initWithPath:descriptorPath];
      }].array;
}

- (RACSequence *)urlSequenceFromContents:(NSArray<NSURL *> *)contents
                         keepDirectories:(BOOL)keepDirectories {
  return [contents.rac_sequence
      filter:^BOOL(NSURL *item) {
        NSNumber *isDirectory;
        [item getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:nil];

        return keepDirectories ? isDirectory.boolValue : !isDirectory.boolValue;
      }];
}

- (LTPath *)descriptorPathFromContentURL:(NSURL *)URL andPath:(LTPath *)path {
  NSString *name;
  [URL getResourceValue:&name forKey:NSURLNameKey error:nil];
  NSString *relativePath = [path.relativePath stringByAppendingPathComponent:name];

  return [LTPath pathWithBaseDirectory:path.baseDirectory andRelativePath:relativePath];
}

+ (NSArray<NSString *> *)supportedUTIs {
  static NSArray<NSString *> *supportedUTIs;

  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    supportedUTIs = [[AVURLAsset audiovisualTypes] arrayByAddingObjectsFromArray:@[
      @"public.jpeg",
      @"public.tiff",
      @"public.png"
    ]];
  });

  return supportedUTIs;
}

#pragma mark -
#pragma mark Asset fetching
#pragma mark -

- (RACSignal *)fetchDescriptorWithURL:(NSURL *)url {
  if (url.ptn_fileSystemURLType == PTNFileSystemURLTypeAsset) {
    return [[self fetchFileWithURL:url] subscribeOn:[RACScheduler scheduler]];
  } else if (url.ptn_fileSystemURLType == PTNFileSystemURLTypeAlbum) {
    return [[self fetchDirectoryWithURL:url] subscribeOn:[RACScheduler scheduler]];
  } else {
    return [RACSignal error:[NSError lt_errorWithCode:PTNErrorCodeInvalidURL url:url]];
  }
}

- (RACSignal *)fetchFileWithURL:(NSURL *)url {
  return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    if (![self nonDirectoryExistsAtURL:url]) {
      [subscriber sendError:[NSError lt_errorWithCode:PTNErrorCodeAssetNotFound url:url]];
      return nil;
    }

    id<PTNDescriptor> asset = [[PTNFileSystemFileDescriptor alloc]
                               initWithPath:url.ptn_fileSystemAssetPath];

    [subscriber sendNext:asset];
    [subscriber sendCompleted];
    return nil;
  }];
}

- (RACSignal *)fetchDirectoryWithURL:(NSURL *)url {
  return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    LTPath *path = url.ptn_fileSystemAlbumPath;
    if (!path) {
      [subscriber sendError:[NSError lt_errorWithCode:PTNErrorCodeInvalidURL url:url]];
      return nil;
    }

    if (![self directoryExistsAtURL:url]) {
      [subscriber sendError:[NSError lt_errorWithCode:PTNErrorCodeAlbumNotFound url:url]];
      return nil;
    }

    id<PTNDescriptor> album = [[PTNFileSystemDirectoryDescriptor alloc]
                               initWithPath:url.ptn_fileSystemAlbumPath];

    [subscriber sendNext:album];
    [subscriber sendCompleted];
    return nil;
  }];
}

- (RACSignal *)fetchKeyAssetForDirectoryURL:(NSURL *)url {
  return [[self fetchAlbumWithURL:url] flattenMap:^(PTNAlbumChangeset *changeset) {
    PTNFileSystemFileDescriptor *keyAsset = changeset.afterAlbum.assets.lastObject;
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
                                options:(PTNImageFetchOptions __unused *)options {
  if (![descriptor isKindOfClass:[PTNFileSystemFileDescriptor class]] &&
      ![descriptor isKindOfClass:[PTNFileSystemDirectoryDescriptor class]]) {
    return [RACSignal error:[NSError ptn_errorWithCode:PTNErrorCodeInvalidDescriptor
                                  associatedDescriptor:descriptor]];
  }

  if ([descriptor isKindOfClass:[PTNFileSystemDirectoryDescriptor class]]) {
    return [[self fetchKeyAssetForDirectoryURL:descriptor.ptn_identifier]
        flattenMap:^(PTNFileSystemFileDescriptor *file) {
          return [self imageAssetForDescriptor:file resizingStrategy:resizingStrategy];
        }];
  }

  return [self imageAssetForDescriptor:descriptor resizingStrategy:resizingStrategy];
}

- (RACSignal *)imageAssetForDescriptor:(id<PTNDescriptor>)descriptor
                      resizingStrategy:(id<PTNResizingStrategy>)resizingStrategy {
  @weakify(self);
  return [RACSignal defer:^RACSignal *{
    @strongify(self);
    LTPath *filePath = descriptor.ptn_identifier.ptn_fileSystemAssetPath;
    if (![self nonDirectoryExistsAtURL:descriptor.ptn_identifier]) {
      NSError *error = [NSError ptn_errorWithCode:PTNErrorCodeAssetNotFound
                             associatedDescriptor:descriptor];
      return [RACSignal error:error];
    }

    if ([descriptor.descriptorTraits containsObject:kPTNDescriptorTraitAudiovisualKey]) {
      return [self imageForVideoAssetWithDescriptor:descriptor resizingStrategy:resizingStrategy];
    }

    PTNFileBackedImageAsset *imageAsset =
        [[PTNFileBackedImageAsset alloc] initWithFilePath:filePath imageResizer:self.imageResizer
                                         resizingStrategy:resizingStrategy];

    return [RACSignal return:[[PTNProgress alloc] initWithResult:imageAsset]];
  }];
}

- (RACSignal *)imageForVideoAssetWithDescriptor:(id<PTNDescriptor>)descriptor
                               resizingStrategy:(id<PTNResizingStrategy>)resizingStrategy {
  LTPath *filePath = descriptor.ptn_identifier.ptn_fileSystemAssetPath;
  AVAsset *videoAsset = [AVAsset assetWithURL:filePath.url];
  PTNAVImageAsset *imageAsset =
      [[PTNAVImageAsset alloc] initWithAsset:videoAsset resizingStrategy:resizingStrategy];
  return [RACSignal return:[[PTNProgress alloc] initWithResult:imageAsset]];
}

- (BOOL)nonDirectoryExistsAtURL:(NSURL *)url {
  BOOL isDirectory;
  BOOL fileExists = [self.fileManager fileExistsAtPath:url.ptn_fileSystemAssetPath.path
                                           isDirectory:&isDirectory];
  return fileExists && !isDirectory;
}

- (BOOL)directoryExistsAtURL:(NSURL *)url {
  BOOL isDirectory;
  BOOL fileExists = [self.fileManager fileExistsAtPath:url.ptn_fileSystemAlbumPath.path
                                           isDirectory:&isDirectory];
  return fileExists && isDirectory;
}

#pragma mark -
#pragma mark AVAsset fetching
#pragma mark -

- (RACSignal *)fetchAVAssetWithDescriptor:(id<PTNDescriptor>)descriptor
                                  options:(PTNAVAssetFetchOptions __unused *)options {
  @weakify(self);
  return [RACSignal defer:^RACSignal *{
    @strongify(self);
    LTPath *filePath = descriptor.ptn_identifier.ptn_fileSystemAssetPath;
    if (![self nonDirectoryExistsAtURL:descriptor.ptn_identifier]) {
      NSError *error = [NSError ptn_errorWithCode:PTNErrorCodeAssetNotFound
                             associatedDescriptor:descriptor];
      return [RACSignal error:error];
    }

    if (![descriptor.descriptorTraits containsObject:kPTNDescriptorTraitAudiovisualKey]) {
      NSError *error = [NSError ptn_errorWithCode:PTNErrorCodeInvalidDescriptor
                             associatedDescriptor:descriptor];
      return [RACSignal error:error];
    }

    PTNAudiovisualAsset *videoAsset =
        [[PTNAudiovisualAsset alloc] initWithAVAsset:[AVAsset assetWithURL:filePath.url]];
    return [RACSignal return:[[PTNProgress alloc] initWithResult:videoAsset]];
  }];
}

#pragma mark -
#pragma mark Image data fetching
#pragma mark -

- (RACSignal *)fetchImageDataWithDescriptor:(id<PTNDescriptor>)descriptor {
  if (![descriptor isKindOfClass:[PTNFileSystemFileDescriptor class]]) {
    return [RACSignal error:[NSError ptn_errorWithCode:PTNErrorCodeInvalidDescriptor
                                  associatedDescriptor:descriptor]];
  }

  return [self imageDataAssetForDescriptor:descriptor];
}

- (RACSignal *)imageDataAssetForDescriptor:(id<PTNDescriptor>)descriptor {
  @weakify(self);
  return [RACSignal defer:^RACSignal *{
    @strongify(self);
    LTPath *filePath = descriptor.ptn_identifier.ptn_fileSystemAssetPath;
    if (![self nonDirectoryExistsAtURL:descriptor.ptn_identifier]) {
      NSError *error = [NSError ptn_errorWithCode:PTNErrorCodeAssetNotFound
                             associatedDescriptor:descriptor];
      return [RACSignal error:error];
    }

    if ([descriptor.descriptorTraits containsObject:kPTNDescriptorTraitAudiovisualKey]) {
      return [self imageForVideoAssetWithDescriptor:descriptor
                                   resizingStrategy:[PTNResizingStrategy identity]];
    }

    PTNFileBackedImageAsset *imageAsset =
        [[PTNFileBackedImageAsset alloc] initWithFilePath:filePath imageResizer:self.imageResizer
                                         resizingStrategy:nil];

    return [RACSignal return:[[PTNProgress alloc] initWithResult:imageAsset]];
  }];
}

#pragma mark -
#pragma mark AV preview fetching
#pragma mark -

- (RACSignal *)fetchAVPreviewWithDescriptor:(id<PTNDescriptor>)descriptor
                                    options:(PTNAVAssetFetchOptions __unused *)options {
  @weakify(self);
  return [RACSignal defer:^RACSignal *{
    @strongify(self);
    LTPath *filePath = descriptor.ptn_identifier.ptn_fileSystemAssetPath;
    if (![self nonDirectoryExistsAtURL:descriptor.ptn_identifier]) {
      NSError *error = [NSError ptn_errorWithCode:PTNErrorCodeAssetNotFound
                             associatedDescriptor:descriptor];
      return [RACSignal error:error];
    }

    if (![descriptor.descriptorTraits containsObject:kPTNDescriptorTraitAudiovisualKey]) {
      NSError *error = [NSError ptn_errorWithCode:PTNErrorCodeInvalidDescriptor
                             associatedDescriptor:descriptor];
      return [RACSignal error:error];
    }

    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:filePath.url];
    return [RACSignal return:[[PTNProgress alloc] initWithResult:playerItem]];
  }];
}

#pragma mark -
#pragma mark AV data fetching
#pragma mark -

- (RACSignal<PTNProgress<id<PTNAVDataAsset>> *>*)
    fetchAVDataWithDescriptor:(id<PTNDescriptor>)descriptor {
  @weakify(self);
  return [RACSignal defer:^RACSignal *{
    @strongify(self);
    LTPath *filePath = descriptor.ptn_identifier.ptn_fileSystemAssetPath;
    if (![self nonDirectoryExistsAtURL:descriptor.ptn_identifier]) {
      NSError *error = [NSError ptn_errorWithCode:PTNErrorCodeAssetNotFound
                             associatedDescriptor:descriptor];
      return [RACSignal error:error];
    }

    if (![descriptor.descriptorTraits containsObject:kPTNDescriptorTraitAudiovisualKey]) {
      NSError *error = [NSError ptn_errorWithCode:PTNErrorCodeInvalidDescriptor
                             associatedDescriptor:descriptor];
      return [RACSignal error:error];
    }

    auto asset = [[PTNFileBackedAVAsset alloc] initWithFilePath:filePath];
    return [RACSignal return:[[PTNProgress alloc] initWithResult:asset]];
  }];
}

@end

NS_ASSUME_NONNULL_END
