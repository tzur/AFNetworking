// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNFileSystemAssetManager.h"

#import "NSError+Photons.h"
#import "PTNFileSystemAlbum.h"
#import "PTNFileSystemDirectoryDescriptor.h"
#import "PTNFileSystemFakeFileManager.h"
#import "PTNFileSystemFileDescriptor.h"
#import "PTNFileSystemTestUtils.h"
#import "PTNImageContainer.h"
#import "PTNImageResizer.h"

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
    [[PTNFileSystemFakeFileManagerFile alloc] initWithName:@"foo.tiff" path:@"/baz" isDirectory:NO],
    [[PTNFileSystemFakeFileManagerFile alloc] initWithName:@"foo.jpeg" path:@"/baz" isDirectory:NO],
    [[PTNFileSystemFakeFileManagerFile alloc] initWithName:@"foo.zip" path:@"/" isDirectory:NO],
    [[PTNFileSystemFakeFileManagerFile alloc] initWithName:@"qux" path:@"/" isDirectory:YES]
  ]];
  imageResizer = OCMClassMock([PTNImageResizer class]);
  manager = [[PTNFileSystemAssetManager alloc] initWithFileManager:fileManager
                                                      imageResizer:imageResizer];
});

context(@"album fetching", ^{
  it(@"should fetch current results of an album", ^{
    NSURL *url = [NSURL ptn_fileSystemAlbumURLWithPath:PTNFileSystemPathFromString(@"/")];
    RACSignal *values = [manager fetchAlbumWithURL:url];
    NSArray *directories = @[
      PTNFileSystemDirectoryFromString(@"baz"),
      PTNFileSystemDirectoryFromString(@"qux")
    ];
    NSArray *files = @[
      PTNFileSystemFileFromString(@"foo.jpg"),
      PTNFileSystemFileFromString(@"bar.jpg")
    ];
    id<PTNAlbum> album = [[PTNFileSystemAlbum alloc] initWithPath:url subdirectories:directories
                                                            files:files];

    expect(values).will.sendValues(@[[PTNAlbumChangeset changesetWithAfterAlbum:album]]);
  });

  it(@"should only fetch files of type {'jpg', 'png', 'jpeg', 'tiff'}", ^{
    NSURL *url = [NSURL ptn_fileSystemAlbumURLWithPath:PTNFileSystemPathFromString(@"baz")];
    RACSignal *values = [manager fetchAlbumWithURL:url];
    NSArray *files = @[
      PTNFileSystemFileFromString(@"baz/foo.jpg"),
      PTNFileSystemFileFromString(@"baz/foo.png"),
      PTNFileSystemFileFromString(@"baz/foo.tiff"),
      PTNFileSystemFileFromString(@"baz/foo.jpeg")
    ];
    id<PTNAlbum> album = [[PTNFileSystemAlbum alloc] initWithPath:url
                                                   subdirectories:@[]
                                                            files:files];

    expect(values).will.sendValues(@[[PTNAlbumChangeset changesetWithAfterAlbum:album]]);
  });

  context(@"thread transitions", ^{
    it(@"should not operate on the main thread", ^{
      NSURL *url = [NSURL ptn_fileSystemAlbumURLWithPath:PTNFileSystemPathFromString(@"")];
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
      NSURL *url = [NSURL ptn_fileSystemAlbumURLWithPath:PTNFileSystemPathFromString(@"bar")];

      expect([manager fetchAlbumWithURL:url]).will.matchError(^BOOL(NSError *error) {
        return error.code == PTNErrorCodeAlbumNotFound;
      });
    });

    it(@"should error on non directory file", ^{
      NSURL *url = [NSURL ptn_fileSystemAlbumURLWithPath:PTNFileSystemPathFromString(@"foo.jpg")];

      expect([manager fetchAlbumWithURL:url]).will.matchError(^BOOL(NSError *error) {
        return error.code == PTNErrorCodeAlbumNotFound;
      });
    });
  });
});

context(@"asset fetching", ^{
  it(@"should fetch asset with URL", ^{
    NSURL *url = [NSURL ptn_fileSystemAssetURLWithPath:PTNFileSystemPathFromString(@"baz/foo.jpg")];

    expect([manager fetchAssetWithURL:url]).will.sendValues(@[
      PTNFileSystemFileFromString(@"baz/foo.jpg")
    ]);
  });

  it(@"should error on non-existing asset", ^{
    NSURL *url = [NSURL ptn_fileSystemAssetURLWithPath:PTNFileSystemPathFromString(@"baz/qux.jpg")];

    expect([manager fetchAssetWithURL:url]).will.matchError(^BOOL(NSError *error) {
      return error.code == PTNErrorCodeAssetNotFound;
    });
  });

  it(@"should error on directory URL", ^{
    NSURL *url = [NSURL ptn_fileSystemAlbumURLWithPath:PTNFileSystemPathFromString(@"baz")];

    expect([manager fetchAssetWithURL:url]).will.matchError(^BOOL(NSError *error) {
      return error.code == PTNErrorCodeInvalidURL;
    });
  });

  it(@"should error on invalid URL", ^{
    NSURL *url = [NSURL URLWithString:@"http://www.foo.com"];

    expect([manager fetchAssetWithURL:url]).will.matchError(^BOOL(NSError *error) {
      return error.code == PTNErrorCodeInvalidURL;
    });
  });

  context(@"thread transitions", ^{
    it(@"should not operate on the main thread", ^{
      NSURL *url = [NSURL ptn_fileSystemAssetURLWithPath:PTNFileSystemPathFromString(@"foo.jpg")];
      RACSignal *values = [manager fetchAssetWithURL:url];

      expect(values).will.sendValuesWithCount(1);
      expect(values).willNot.deliverValuesOnMainThread();
    });
  });
});

context(@"image fetching", ^{
  __block id<PTNResizingStrategy> resizingStrategy;
  __block PTNImageFetchOptions *options;
  __block UIImage *image;
  __block id<PTNDescriptor> asset;

  beforeEach(^{
    resizingStrategy = [PTNResizingStrategy identity];
    options = [PTNImageFetchOptions optionsWithDeliveryMode:PTNImageDeliveryModeFast
                                                 resizeMode:PTNImageResizeModeFast
                                              fetchMetadata:NO];
    NSURL *fileURL = [NSURL fileURLWithPath:@"/foo.jpg"];
    image = [[UIImage alloc] init];

    OCMStub([imageResizer resizeImageAtURL:fileURL resizingStrategy:resizingStrategy])
        .andReturn([RACSignal return:image]);
    asset = PTNFileSystemFileFromString(@"foo.jpg");
  });

  context(@"fetch image of asset", ^{
    it(@"should fetch image", ^{
      expect([manager fetchImageWithDescriptor:asset
                              resizingStrategy:resizingStrategy
                                       options:options]).will.sendValues(@[
        [[PTNProgress alloc] initWithResult:[[PTNImageContainer alloc] initWithImage:image]]
      ]);
    });

    it(@"should complete after fetching an image", ^{
      RACSignal *values = [manager fetchImageWithDescriptor:asset resizingStrategy:resizingStrategy
                                                    options:options];

      expect(values).will.sendValuesWithCount(1);
      expect(values).will.complete();
    });

    it(@"should error on non-existing assets", ^{
      asset = PTNFileSystemFileFromString(@"/foo/bar/baz.jpg");
      NSURL *fileURL = [NSURL fileURLWithPath:@"/foo/bar/baz.jpg"];
      OCMStub([imageResizer resizeImageAtURL:fileURL resizingStrategy:resizingStrategy])
          .andReturn([RACSignal error:[NSError lt_errorWithCode:1337]]);
      RACSignal *values = [manager fetchImageWithDescriptor:asset resizingStrategy:resizingStrategy
                                                    options:options];

      expect(values).will.matchError(^BOOL(NSError *error) {
        return error.code == PTNErrorCodeAssetLoadingFailed && error.lt_underlyingError;
      });
    });

    context(@"thread transitions", ^{
      it(@"should not operate on the main thread", ^{
        RACSignal *values = [manager fetchImageWithDescriptor:asset
                                             resizingStrategy:resizingStrategy
                                                      options:options];

        expect(values).will.sendValuesWithCount(1);
        expect(values).willNot.deliverValuesOnMainThread();
      });
    });
  });

  context(@"fetch image of asset collection", ^{
    beforeEach(^{
      NSURL *fileURL = [NSURL fileURLWithPath:@"/baz/foo.jpg"];
      OCMStub([imageResizer resizeImageAtURL:fileURL resizingStrategy:resizingStrategy])
          .andReturn([RACSignal return:image]);
    });

    it(@"should fetch asset collection representative image", ^{
      expect([manager fetchImageWithDescriptor:PTNFileSystemDirectoryFromString(@"baz")
                              resizingStrategy:resizingStrategy
                                       options:options]).will.sendValues(@[
        [[PTNProgress alloc] initWithResult:[[PTNImageContainer alloc] initWithImage:image]]
      ]);
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

  context(@"metadata fetching", ^{
    __block PTNImageFetchOptions *fetchMetadataOptions;

    beforeEach(^{
      fetchMetadataOptions = [PTNImageFetchOptions optionsWithDeliveryMode:PTNImageDeliveryModeFast
                                                                resizeMode:PTNImageResizeModeFast
                                                             fetchMetadata:YES];
      NSURL *metadataURL =
          [[NSBundle bundleForClass:[self class]] URLForResource:@"PTNImageMetadataImage"
                                                   withExtension:@"jpg"];
      OCMStub([imageResizer resizeImageAtURL:metadataURL resizingStrategy:resizingStrategy])
          .andReturn([RACSignal return:image]);
      asset = PTNFileSystemFileFromString(metadataURL.path);
    });

    it(@"should fetch metadata", ^{
      RACSignal *values = [manager fetchImageWithDescriptor:asset resizingStrategy:resizingStrategy
                                                    options:fetchMetadataOptions];

      expect(values).will.matchValue(0, ^BOOL(PTNProgress<PTNImageContainer *> *progress) {
        return [progress.result.image isEqual:image] && progress.result.metadata;
      });
    });

    it(@"should complete after fetching an image", ^{
      RACSignal *values = [manager fetchImageWithDescriptor:asset resizingStrategy:resizingStrategy
                                                    options:fetchMetadataOptions];

      expect(values).will.sendValuesWithCount(1);
      expect(values).will.complete();
    });

    it(@"should err when file metadata creation fails", ^{
      asset = PTNFileSystemFileFromString(@"foo.jpg");
      RACSignal *values = [manager fetchImageWithDescriptor:asset resizingStrategy:resizingStrategy
                                                    options:fetchMetadataOptions];

      expect(values).will.matchError(^BOOL(NSError *error) {
        return error.code == PTNErrorCodeAssetMetadataLoadingFailed && error.lt_underlyingError;
      });
    });

    it(@"should err when requesting metadata of non existing asset", ^{
      asset = PTNFileSystemFileFromString(@"/foo/bar/baz.jpg");
      NSURL *fileURL = [NSURL fileURLWithPath:@"/foo/bar/baz.jpg"];
      OCMStub([imageResizer resizeImageAtURL:fileURL resizingStrategy:resizingStrategy])
          .andReturn([RACSignal error:[NSError lt_errorWithCode:1337]]);
      RACSignal *values = [manager fetchImageWithDescriptor:asset resizingStrategy:resizingStrategy
                                                    options:fetchMetadataOptions];

      expect(values).will.matchError(^BOOL(NSError *error) {
        return error.code == PTNErrorCodeAssetLoadingFailed && error.lt_underlyingError;
      });
    });
  });
});

SpecEnd
