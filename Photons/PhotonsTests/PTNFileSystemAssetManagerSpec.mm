// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNFileSystemAssetManager.h"

#import <AVFoundation/AVFoundation.h>
#import <LTKit/LTPath.h>
#import <LTKit/LTRandomAccessCollection.h>
#import <LTKit/NSBundle+Path.h>

#import "NSError+Photons.h"
#import "NSURL+FileSystem.h"
#import "PTNAVAssetFetchOptions.h"
#import "PTNAVImageAsset.h"
#import "PTNAlbum.h"
#import "PTNAlbumChangeset.h"
#import "PTNAudiovisualAsset.h"
#import "PTNFileBackedAVAsset.h"
#import "PTNFileBackedImageAsset.h"
#import "PTNFileSystemDirectoryDescriptor.h"
#import "PTNFileSystemFakeFileManager.h"
#import "PTNFileSystemFileDescriptor.h"
#import "PTNFileSystemTestUtils.h"
#import "PTNImageFetchOptions.h"
#import "PTNImageResizer.h"
#import "PTNProgress.h"
#import "PTNResizingStrategy.h"

SpecBegin(PTNFileSystemAssetManager)

__block PTNFileSystemAssetManager *manager;
__block id<PTNFileSystemFileManager> fileManager;
__block PTNImageResizer *imageResizer;

beforeEach(^{
  fileManager = [[PTNFileSystemFakeFileManager alloc] initWithFiles:@[
    [[PTNFileSystemFakeFileManagerFile alloc] initWithName:@"/" path:@"" isDirectory:YES],
    [[PTNFileSystemFakeFileManagerFile alloc] initWithName:@"foo.jpg" path:@"/" isDirectory:NO],
    [[PTNFileSystemFakeFileManagerFile alloc] initWithName:@"bar.jpg" path:@"/" isDirectory:NO],
    [[PTNFileSystemFakeFileManagerFile alloc] initWithName:@"foo.jpg" path:@"/baz" isDirectory:NO],
    [[PTNFileSystemFakeFileManagerFile alloc] initWithName:@"baz" path:@"/" isDirectory:YES],
    [[PTNFileSystemFakeFileManagerFile alloc] initWithName:@"foo.png" path:@"/baz" isDirectory:NO],
    [[PTNFileSystemFakeFileManagerFile alloc] initWithName:@"foo.xml" path:@"/baz" isDirectory:NO],
    [[PTNFileSystemFakeFileManagerFile alloc] initWithName:@"foo.tiff" path:@"/baz" isDirectory:NO],
    [[PTNFileSystemFakeFileManagerFile alloc] initWithName:@"foo.jpeg" path:@"/baz" isDirectory:NO],
    [[PTNFileSystemFakeFileManagerFile alloc] initWithName:@"foo.zip" path:@"/" isDirectory:NO],
    [[PTNFileSystemFakeFileManagerFile alloc] initWithName:@"qux" path:@"/" isDirectory:YES],
    [[PTNFileSystemFakeFileManagerFile alloc] initWithName:@"foo.mp4" path:@"/" isDirectory:NO],
    [[PTNFileSystemFakeFileManagerFile alloc] initWithName:@"foo.mp4" path:@"/baz" isDirectory:NO],
    [[PTNFileSystemFakeFileManagerFile alloc] initWithName:@"foo.mov" path:@"/baz" isDirectory:NO],
    [[PTNFileSystemFakeFileManagerFile alloc] initWithName:@"foo.m4v" path:@"/baz" isDirectory:NO],
    [[PTNFileSystemFakeFileManagerFile alloc] initWithName:@"foo.qt" path:@"/baz" isDirectory:NO],
    [[PTNFileSystemFakeFileManagerFile alloc] initWithName:@"baz1" path:@"/" isDirectory:YES],
    [[PTNFileSystemFakeFileManagerFile alloc] initWithName:@"foo1.jpg" path:@"/baz1"
                                               isDirectory:NO],
    [[PTNFileSystemFakeFileManagerFile alloc] initWithName:@"" path:PTNOneSecondVideoPath().path
                                               isDirectory:NO],
  ]];
  imageResizer = OCMClassMock([PTNImageResizer class]);
  manager = [[PTNFileSystemAssetManager alloc] initWithFileManager:fileManager
                                                      imageResizer:imageResizer];
});

context(@"album fetching", ^{
 it(@"should fetch current results of an album", ^{
    NSURL *url = [NSURL ptn_fileSystemAlbumURLWithPath:[LTPath pathWithPath:@"/"]];
    RACSignal *values = [manager fetchAlbumWithURL:url];
    NSArray *directories = @[
      PTNFileSystemDirectoryFromString(@"baz"),
      PTNFileSystemDirectoryFromString(@"qux"),
      PTNFileSystemDirectoryFromString(@"baz1")
    ];
    NSArray *files = @[
      PTNFileSystemFileFromString(@"foo.jpg"),
      PTNFileSystemFileFromString(@"bar.jpg"),
      PTNFileSystemFileFromString(@"foo.mp4"),
    ];
    id<PTNAlbum> album = [[PTNAlbum alloc] initWithURL:url subalbums:directories assets:files];

    expect(values).will.sendValues(@[[PTNAlbumChangeset changesetWithAfterAlbum:album]]);
  });

  it(@"should only fetch supported UTI files", ^{
    NSURL *url = [NSURL ptn_fileSystemAlbumURLWithPath:[LTPath pathWithPath:@"baz"]];
    RACSignal *values = [manager fetchAlbumWithURL:url];
    NSArray *files = @[
      PTNFileSystemFileFromString(@"baz/foo.jpg"),
      PTNFileSystemFileFromString(@"baz/foo.png"),
      PTNFileSystemFileFromString(@"baz/foo.tiff"),
      PTNFileSystemFileFromString(@"baz/foo.jpeg"),
      PTNFileSystemFileFromString(@"baz/foo.mp4"),
      PTNFileSystemFileFromString(@"baz/foo.mov"),
      PTNFileSystemFileFromString(@"baz/foo.m4v"),
      PTNFileSystemFileFromString(@"baz/foo.qt")
    ];
    id<PTNAlbum> album = [[PTNAlbum alloc] initWithURL:url subalbums:@[] assets:files];

    expect(values).will.sendValues(@[[PTNAlbumChangeset changesetWithAfterAlbum:album]]);
  });

  context(@"thread transitions", ^{
    it(@"should not operate on the main thread", ^{
      NSURL *url = [NSURL ptn_fileSystemAlbumURLWithPath:[LTPath pathWithPath:@""]];
      RACSignal *values = [manager fetchAlbumWithURL:url];

      expect(values).will.sendValuesWithCount(1);
      expect(values).willNot.deliverValuesOnMainThread();
    });
  });

  context(@"fetching errors", ^{
    it(@"should error on invalid URL", ^{
      NSURL *url = [NSURL URLWithString:@"http://www.foo.com"];

      expect([manager fetchAlbumWithURL:url]).will.matchError(^BOOL(NSError *error) {
        return error.code == PTNErrorCodeInvalidURL;
      });
    });

    it(@"should error on non existing file", ^{
      NSURL *url = [NSURL ptn_fileSystemAlbumURLWithPath:[LTPath pathWithPath:@"bar"]];

      expect([manager fetchAlbumWithURL:url]).will.matchError(^BOOL(NSError *error) {
        return error.code == PTNErrorCodeAlbumNotFound;
      });
    });

    it(@"should error on non directory file", ^{
      NSURL *url = [NSURL ptn_fileSystemAlbumURLWithPath:[LTPath pathWithPath:@"foo.jpg"]];

      expect([manager fetchAlbumWithURL:url]).will.matchError(^BOOL(NSError *error) {
        return error.code == PTNErrorCodeAlbumNotFound;
      });
    });
  });
});

context(@"asset fetching", ^{
  it(@"should fetch asset with URL", ^{
    NSURL *url = [NSURL ptn_fileSystemAssetURLWithPath:[LTPath pathWithPath:@"baz/foo.jpg"]];

    expect([manager fetchDescriptorWithURL:url]).will.sendValues(@[
      PTNFileSystemFileFromString(@"baz/foo.jpg")
    ]);
  });

  it(@"should error on non-existing asset", ^{
    NSURL *url = [NSURL ptn_fileSystemAssetURLWithPath:[LTPath pathWithPath:@"baz/qux.jpg"]];

    expect([manager fetchDescriptorWithURL:url]).will.matchError(^BOOL(NSError *error) {
      return error.code == PTNErrorCodeAssetNotFound;
    });
  });

  it(@"should verify file existence on subscription", ^{
    NSURL *url = [NSURL ptn_fileSystemAssetURLWithPath:[LTPath pathWithPath:@"baz/qux.jpg"]];
    RACSignal *values = [manager fetchDescriptorWithURL:url];

    PTNFileSystemFakeFileManager *fakeFileManager = (PTNFileSystemFakeFileManager *)fileManager;
    auto fakeFile = [[PTNFileSystemFakeFileManagerFile alloc] initWithName:@"qux.jpg"
                                                                      path:@"/baz"
                                                               isDirectory:NO];
    fakeFileManager.files = [fakeFileManager.files arrayByAddingObject:fakeFile];

    expect(values).will.complete();
  });

  it(@"should fetch directory descriptor for directory URL", ^{
    NSURL *url = [NSURL ptn_fileSystemAlbumURLWithPath:[LTPath pathWithPath:@"baz"]];

    expect([manager fetchDescriptorWithURL:url]).will.sendValues(@[
      PTNFileSystemDirectoryFromString(@"baz")
    ]);
  });

  it(@"should error when fetching asset of non-directory with directory descriptor URL", ^{
    NSURL *url = [NSURL ptn_fileSystemAlbumURLWithPath:[LTPath pathWithPath:@"foo.jpg"]];

    expect([manager fetchDescriptorWithURL:url]).will.matchError(^BOOL(NSError *error) {
      return error.code == PTNErrorCodeAlbumNotFound;
    });
  });

  it(@"should error on invalid URL", ^{
    NSURL *url = [NSURL URLWithString:@"http://www.foo.com"];

    expect([manager fetchDescriptorWithURL:url]).will.matchError(^BOOL(NSError *error) {
      return error.code == PTNErrorCodeInvalidURL;
    });
  });

  context(@"thread transitions", ^{
    it(@"should not operate on the main thread", ^{
      NSURL *url = [NSURL ptn_fileSystemAssetURLWithPath:[LTPath pathWithPath:@"foo.jpg"]];
      RACSignal *values = [manager fetchDescriptorWithURL:url];

      expect(values).will.sendValuesWithCount(1);
      expect(values).willNot.deliverValuesOnMainThread();
    });
  });
});

context(@"image fetching", ^{
  __block id<PTNResizingStrategy> resizingStrategy;
  __block PTNImageFetchOptions *options;
  __block id<PTNImageAsset> imageAsset;
  __block id<PTNDescriptor> asset;

  beforeEach(^{
    resizingStrategy = [PTNResizingStrategy identity];
    options = [PTNImageFetchOptions optionsWithDeliveryMode:PTNImageDeliveryModeFast
                                                 resizeMode:PTNImageResizeModeFast
                                            includeMetadata:NO];
    imageAsset = [[PTNFileBackedImageAsset alloc] initWithFilePath:[LTPath pathWithPath:@"foo.jpg"]
                                                       fileManager:fileManager
                                                      imageResizer:imageResizer
                                                  resizingStrategy:resizingStrategy];
    asset = PTNFileSystemFileFromString(@"foo.jpg");
  });

  context(@"fetch image of asset", ^{
    it(@"should fetch image", ^{
      RACSignal *values = [manager fetchImageWithDescriptor:asset
                                           resizingStrategy:resizingStrategy
                                                    options:options];
      expect(values).will.sendValues(@[[[PTNProgress alloc] initWithResult:imageAsset]]);
    });

    it(@"should complete after fetching an image", ^{
      RACSignal *values = [manager fetchImageWithDescriptor:asset resizingStrategy:resizingStrategy
                                                    options:options];

      expect(values).will.sendValuesWithCount(1);
      expect(values).will.complete();
    });

    it(@"should error on non-existing assets", ^{
      asset = PTNFileSystemFileFromString(@"/foo/bar/baz.jpg");
      RACSignal *values = [manager fetchImageWithDescriptor:asset resizingStrategy:resizingStrategy
                                                    options:options];

      expect(values).will.matchError(^BOOL(NSError *error) {
        return error.code == PTNErrorCodeAssetNotFound;
      });
    });

    it(@"should verify file existence on subscription", ^{
      asset = PTNFileSystemFileFromString(@"/foo/bar/baz.jpg");
      RACSignal *values = [manager fetchImageWithDescriptor:asset resizingStrategy:resizingStrategy
                                                    options:options];

      PTNFileSystemFakeFileManager *fakeFileManager = (PTNFileSystemFakeFileManager *)fileManager;
      auto fakeFile = [[PTNFileSystemFakeFileManagerFile alloc] initWithName:@"baz.jpg"
                                                                        path:@"/foo/bar"
                                                                 isDirectory:NO];
      fakeFileManager.files = [fakeFileManager.files arrayByAddingObject:fakeFile];

      expect(values).will.complete();
    });
  });

  context(@"fetch image of asset collection", ^{
    beforeEach(^{
      imageAsset =
          [[PTNFileBackedImageAsset alloc] initWithFilePath:[LTPath pathWithPath:@"baz1/foo1.jpg"]
                                                fileManager:fileManager
                                               imageResizer:imageResizer
                                           resizingStrategy:resizingStrategy];
    });

    it(@"should fetch asset collection representative image", ^{
      id<PTNDescriptor> directoryDesc = PTNFileSystemDirectoryFromString(@"baz1");
      RACSignal *values = [manager fetchImageWithDescriptor:directoryDesc
                                           resizingStrategy:resizingStrategy
                                                    options:options];
      expect(values).will.sendValues(@[[[PTNProgress alloc] initWithResult:imageAsset]]);
    });

    it(@"should error on non-existing key assets", ^{
      RACSignal *values = [manager fetchImageWithDescriptor:PTNFileSystemDirectoryFromString(@"qux")
                                           resizingStrategy:resizingStrategy
                                                    options:options];

      expect(values).will.matchError(^BOOL(NSError *error) {
        return error.code == PTNErrorCodeKeyAssetsNotFound;
      });
    });

    it(@"should error on invalid directories", ^{
      RACSignal *values = [manager fetchImageWithDescriptor:PTNFileSystemDirectoryFromString(@"bar")
                                           resizingStrategy:resizingStrategy
                                                    options:options];

      expect(values).will.matchError(^BOOL(NSError *error) {
        return error.code == PTNErrorCodeAlbumNotFound;
      });
    });

    it(@"should error on non-File-System asset", ^{
      id invalidAsset = OCMProtocolMock(@protocol(PTNDescriptor));
      RACSignal *values = [manager fetchImageWithDescriptor:invalidAsset
                                           resizingStrategy:resizingStrategy
                                                    options:options];

      expect(values).will.matchError(^BOOL(NSError *error) {
        return error.code == PTNErrorCodeInvalidDescriptor;
      });
    });
  });

  it(@"should fetch image from video descriptor", ^{
    id<PTNDescriptor> descriptor =
        [[PTNFileSystemFileDescriptor alloc]
         initWithPath:[LTPath pathWithPath:PTNOneSecondVideoPath().path]];

    id<PTNResizingStrategy> resizing = [PTNResizingStrategy identity];
    PTNImageFetchOptions *imageOptions =
        [PTNImageFetchOptions optionsWithDeliveryMode:PTNImageDeliveryModeHighQuality
                                           resizeMode:PTNImageResizeModeFast
                                      includeMetadata:NO];

    RACSignal *values = [manager fetchImageWithDescriptor:descriptor resizingStrategy:resizing
                                                  options:imageOptions];
    AVAsset *videoAsset =
        [AVAsset assetWithURL:descriptor.ptn_identifier.ptn_fileSystemAssetPath.url];
    PTNAVImageAsset *expectedImage = [[PTNAVImageAsset alloc]
                                      initWithAsset:videoAsset
                                      resizingStrategy:resizing];
    expect(values).to.sendValues(@[[[PTNProgress alloc] initWithResult:expectedImage]]);
  });
});

context(@"AVAsset fetching", ^{
  __block PTNAVAssetFetchOptions *options;
  __block id<PTNDescriptor> descriptor;
  __block PTNAudiovisualAsset *expectedAsset;

  beforeEach(^{
    options = [PTNAVAssetFetchOptions optionsWithDeliveryMode:PTNAVAssetDeliveryModeAutomatic];
    descriptor = PTNFileSystemFileFromFileURL(PTNOneSecondVideoPath());
    AVAsset *underlyingAsset = [AVAsset assetWithURL:PTNOneSecondVideoPath()];
    expectedAsset = [[PTNAudiovisualAsset alloc] initWithAVAsset:underlyingAsset];
  });

  it(@"should fetch AVAsset", ^{
    RACSignal *values = [manager fetchAVAssetWithDescriptor:descriptor options:options];
    expect(values).to.sendValues(@[[[PTNProgress alloc] initWithResult:expectedAsset]]);
  });

  it(@"should complete after fetching an AVAsset", ^{
    RACSignal *values = [manager fetchAVAssetWithDescriptor:descriptor options:options];
    expect(values).will.sendValuesWithCount(1);
    expect(values).will.complete();
  });

  it(@"should error on non audiovisual descriptor", ^{
    descriptor = PTNFileSystemFileFromString(@"/foo.jpg");
    RACSignal *values = [manager fetchAVAssetWithDescriptor:descriptor options:options];
    expect(values).will.matchError(^BOOL(NSError *error) {
      return error.code == PTNErrorCodeInvalidDescriptor;
    });
  });

  it(@"should error on non-existing assets", ^{
    descriptor = PTNFileSystemFileFromString(@"/foo/bar/baz.mp4");
    RACSignal *values = [manager fetchAVAssetWithDescriptor:descriptor options:options];

    expect(values).will.matchError(^BOOL(NSError *error) {
      return error.code == PTNErrorCodeAssetNotFound;
    });
  });

  it(@"should verify file existence on subscription", ^{
    descriptor = PTNFileSystemFileFromString(@"/foo/bar/baz.mp4");
    RACSignal *values = [manager fetchAVAssetWithDescriptor:descriptor options:options];

    PTNFileSystemFakeFileManager *fakeFileManager = (PTNFileSystemFakeFileManager *)fileManager;
    auto fakeFile = [[PTNFileSystemFakeFileManagerFile alloc] initWithName:@"baz.mp4"
                                                                      path:@"/foo/bar"
                                                               isDirectory:NO];
    fakeFileManager.files = [fakeFileManager.files arrayByAddingObject:fakeFile];

    expect(values).will.complete();
  });
});

context(@"image data fetching", ^{
  __block id<PTNDescriptor> descriptor;

  it(@"should error on non-existing assets", ^{
    id<PTNDescriptor> descriptor = PTNFileSystemFileFromString(@"/foo/bar/baz.jpg");
    RACSignal *values = [manager fetchImageDataWithDescriptor:descriptor];

    expect(values).will.matchError(^BOOL(NSError *error) {
      return error.lt_isLTDomain && error.code == PTNErrorCodeAssetNotFound;
    });
  });

  it(@"should verify file existence on subscription", ^{
    descriptor = PTNFileSystemFileFromString(@"/foo/bar/baz.mp4");
    RACSignal *values = [manager fetchImageDataWithDescriptor:descriptor];

    PTNFileSystemFakeFileManager *fakeFileManager = (PTNFileSystemFakeFileManager *)fileManager;
    auto fakeFile = [[PTNFileSystemFakeFileManagerFile alloc] initWithName:@"baz.mp4"
                                                                      path:@"/foo/bar"
                                                               isDirectory:NO];
    fakeFileManager.files = [fakeFileManager.files arrayByAddingObject:fakeFile];

    expect(values).will.complete();
  });

  it(@"should error on non-File-System asset", ^{
    id<PTNDescriptor> descriptor = OCMProtocolMock(@protocol(PTNDescriptor));
    RACSignal *values = [manager fetchImageDataWithDescriptor:descriptor];

    expect(values).will.matchError(^BOOL(NSError *error) {
      return error.lt_isLTDomain && error.code == PTNErrorCodeInvalidDescriptor;
    });
  });

  it(@"should fetch image data from image descriptor", ^{
    id<PTNDescriptor> descriptor = PTNFileSystemFileFromString(@"foo.jpg");
    RACSignal *values = [manager fetchImageDataWithDescriptor:descriptor];

    PTNFileBackedImageAsset *imageAsset = [[PTNFileBackedImageAsset alloc]
                                           initWithFilePath:[LTPath pathWithPath:@"foo.jpg"]
                                           fileManager:fileManager
                                           imageResizer:imageResizer
                                           resizingStrategy:[PTNResizingStrategy identity]];

    expect(values).will.sendValues(@[[[PTNProgress alloc] initWithResult:imageAsset]]);
    expect(values).to.complete();
  });

  it(@"should fetch image data from audiovisual descriptor", ^{
    descriptor = [[PTNFileSystemFileDescriptor alloc]
                  initWithPath:[LTPath pathWithPath:PTNOneSecondVideoPath().path]];
    RACSignal *values = [manager fetchImageDataWithDescriptor:descriptor];

    AVAsset *videoAsset =
        [AVAsset assetWithURL:descriptor.ptn_identifier.ptn_fileSystemAssetPath.url];
    PTNAVImageAsset *expectedImage = [[PTNAVImageAsset alloc]
                                      initWithAsset:videoAsset
                                      resizingStrategy:[PTNResizingStrategy identity]];
    expect(values).to.sendValues(@[[[PTNProgress alloc] initWithResult:expectedImage]]);
    expect(values).to.complete();
  });
});

context(@"AVPreview fetching", ^{
  __block PTNAVAssetFetchOptions *options;
  __block id<PTNDescriptor> descriptor;
  __block NSURL *assetURL;

  beforeEach(^{
    options = [PTNAVAssetFetchOptions optionsWithDeliveryMode:PTNAVAssetDeliveryModeAutomatic];
    assetURL = PTNOneSecondVideoPath();
    descriptor = PTNFileSystemFileFromFileURL(PTNOneSecondVideoPath());
  });

  it(@"should fetch AVAsset", ^{
    LLSignalTestRecorder *values = [[manager fetchAVPreviewWithDescriptor:descriptor
                                                                  options:options] testRecorder];

    expect(values).will.matchValue(0, ^BOOL(PTNProgress<AVPlayerItem *> *progress) {
      AVPlayerItem *playerItem = progress.result;
      if (![playerItem.asset isKindOfClass:[AVURLAsset class]]) {
        return NO;
      }
      return [((AVURLAsset *)playerItem.asset).URL isEqual:assetURL];
    });
  });

  it(@"should complete after fetching a player item", ^{
    RACSignal *values = [manager fetchAVPreviewWithDescriptor:descriptor options:options];
    expect(values).will.sendValuesWithCount(1);
    expect(values).will.complete();
  });

  it(@"should error on non audiovisual descriptor", ^{
    descriptor = PTNFileSystemFileFromString(@"/foo.jpg");
    RACSignal *values = [manager fetchAVPreviewWithDescriptor:descriptor options:options];
    expect(values).will.matchError(^BOOL(NSError *error) {
      return error.code == PTNErrorCodeInvalidDescriptor;
    });
  });

  it(@"should error on non-existing assets", ^{
    descriptor = PTNFileSystemFileFromString(@"/foo/bar/baz.mp4");
    RACSignal *values = [manager fetchAVPreviewWithDescriptor:descriptor options:options];

    expect(values).will.matchError(^BOOL(NSError *error) {
      return error.code == PTNErrorCodeAssetNotFound;
    });
  });

  it(@"should verify file existence on subscription", ^{
    descriptor = PTNFileSystemFileFromString(@"/foo/bar/baz.mp4");
    RACSignal *values = [manager fetchAVPreviewWithDescriptor:descriptor options:options];

    PTNFileSystemFakeFileManager *fakeFileManager = (PTNFileSystemFakeFileManager *)fileManager;
    auto fakeFile = [[PTNFileSystemFakeFileManagerFile alloc] initWithName:@"baz.mp4"
                                                                      path:@"/foo/bar"
                                                               isDirectory:NO];
    fakeFileManager.files = [fakeFileManager.files arrayByAddingObject:fakeFile];

    expect(values).will.complete();
  });
});

context(@"AV data fetching", ^{
  __block id<PTNDescriptor> descriptor;
  __block NSURL *assetURL;

  beforeEach(^{
    assetURL = PTNOneSecondVideoPath();
    descriptor = PTNFileSystemFileFromFileURL(assetURL);
  });

  it(@"should fetch AV data", ^{
    LLSignalTestRecorder *values = [[manager fetchAVDataWithDescriptor:descriptor] testRecorder];

    PTNFileBackedAVAsset *expectedAsset =
        [[PTNFileBackedAVAsset alloc] initWithFilePath:[LTPath pathWithFileURL:assetURL]];

    expect(values).will.sendValues(@[[[PTNProgress alloc] initWithResult:expectedAsset]]);
    expect(values).will.complete();
  });

  it(@"should error on non audiovisual descriptor", ^{
    descriptor = PTNFileSystemFileFromString(@"/foo.jpg");
    RACSignal *values = [manager fetchAVDataWithDescriptor:descriptor];
    expect(values).will.matchError(^BOOL(NSError *error) {
      return error.code == PTNErrorCodeInvalidDescriptor;
    });
  });

  it(@"should error on non-existing assets", ^{
    descriptor = PTNFileSystemFileFromString(@"/foo/bar/baz.mp4");
    RACSignal *values = [manager fetchAVDataWithDescriptor:descriptor];

    expect(values).will.matchError(^BOOL(NSError *error) {
      return error.code == PTNErrorCodeAssetNotFound;
    });
  });

  it(@"should verify file existence on subscription", ^{
    descriptor = PTNFileSystemFileFromString(@"/foo/bar/baz.mp4");
    RACSignal *values = [manager fetchAVDataWithDescriptor:descriptor];

    PTNFileSystemFakeFileManager *fakeFileManager = (PTNFileSystemFakeFileManager *)fileManager;
    auto fakeFile = [[PTNFileSystemFakeFileManagerFile alloc] initWithName:@"baz.mp4"
                                                                      path:@"/foo/bar"
                                                               isDirectory:NO];
    fakeFileManager.files = [fakeFileManager.files arrayByAddingObject:fakeFile];

    expect(values).will.complete();
  });
});

SpecEnd
