// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNDropboxAssetManager.h"

#import <LTKit/LTPath.h>
#import <LTKit/LTRandomAccessCollection.h>

#import "NSError+Photons.h"
#import "NSURL+Dropbox.h"
#import "PTNAVAssetFetchOptions.h"
#import "PTNAlbum.h"
#import "PTNAlbumChangeset.h"
#import "PTNDropboxDirectoryDescriptor.h"
#import "PTNDropboxEntry.h"
#import "PTNDropboxFakeRestClient.h"
#import "PTNDropboxFileDescriptor.h"
#import "PTNDropboxRestClient.h"
#import "PTNDropboxTestUtils.h"
#import "PTNDropboxThumbnail.h"
#import "PTNFileBackedImageAsset.h"
#import "PTNImageAsset.h"
#import "PTNImageFetchOptions.h"
#import "PTNImageResizer.h"
#import "PTNProgress.h"
#import "PTNResizingStrategy.h"

SpecBegin(PTNDropboxAssetManager)

__block PTNDropboxAssetManager *manager;
__block PTNDropboxFakeRestClient *dropboxClient;
__block PTNImageResizer *imageResizer;
__block NSFileManager *fileManager;

static NSString * const kPath = @"/foo";
static NSString * const kRevision = @"bar";

beforeEach(^{
  dropboxClient = [[PTNDropboxFakeRestClient alloc] init];
  imageResizer = OCMClassMock([PTNImageResizer class]);
  fileManager = OCMClassMock([NSFileManager class]);
  manager = [[PTNDropboxAssetManager alloc] initWithDropboxClient:(id)dropboxClient
                                                     imageResizer:imageResizer
                                                      fileManager:fileManager];
});

context(@"album fetching", ^{
  it(@"should fetch current results of an album", ^{
    NSArray *metadataContents = @[
      PTNDropboxCreateDirectoryMetadata(@"qux"),
      PTNDropboxCreateFileMetadata(@"bar", nil),
      PTNDropboxCreateFileMetadata(@"baz", nil)
    ];
    DBMetadata *metadata = PTNDropboxCreateDirectoryMetadataWithContents(kPath, metadataContents);
    [dropboxClient serveMetadataAtPath:kPath revision:nil withMetadata:metadata];
    NSURL *url = [NSURL ptn_dropboxAlbumURLWithEntry:[PTNDropboxEntry entryWithPath:kPath]];

    RACSignal *values = [manager fetchAlbumWithURL:url];
    NSArray *directories = @[
      [[PTNDropboxDirectoryDescriptor alloc] initWithMetadata:metadataContents[0]]
    ];
    NSArray *files = @[
      [[PTNDropboxFileDescriptor alloc] initWithMetadata:metadataContents[1]],
      [[PTNDropboxFileDescriptor alloc] initWithMetadata:metadataContents[2]]
    ];
    id<PTNAlbum> album = [[PTNAlbum alloc] initWithURL:url subalbums:directories assets:files];

    expect(values).will.sendValues(@[[PTNAlbumChangeset changesetWithAfterAlbum:album]]);
  });

  context(@"fetching errors", ^{
    it(@"should error on invalid URL", ^{
      NSURL *url = [NSURL URLWithString:@"http://www.foo.com"];

      expect([manager fetchAlbumWithURL:url]).will.matchError(^BOOL(NSError *error) {
        return error.code == PTNErrorCodeInvalidURL;
      });
    });

    it(@"should error when dropbox client errs", ^{
      NSURL *url = [NSURL ptn_dropboxAlbumURLWithEntry:[PTNDropboxEntry entryWithPath:kPath]];
      [dropboxClient serveMetadataAtPath:kPath revision:nil
                               withError:[NSError lt_errorWithCode:1337]];

      expect([manager fetchAlbumWithURL:url]).will.matchError(^BOOL(NSError *error) {
        return error.code == PTNErrorCodeAlbumNotFound;
      });
    });

    it(@"should error on non directory file", ^{
      NSURL *url = [NSURL ptn_dropboxAlbumURLWithEntry:[PTNDropboxEntry entryWithPath:kPath]];
      [dropboxClient serveMetadataAtPath:kPath revision:nil
                            withMetadata:PTNDropboxCreateFileMetadata(kPath, nil)];

      expect([manager fetchAlbumWithURL:url]).will.matchError(^BOOL(NSError *error) {
        return error.code == PTNErrorCodeAlbumNotFound;
      });
    });

    it(@"should error when not authorized", ^{
      NSURL *url = [NSURL ptn_dropboxAlbumURLWithEntry:[PTNDropboxEntry entryWithPath:kPath]];
      [dropboxClient serveMetadataAtPath:kPath revision:nil
                               withError:[NSError lt_errorWithCode:PTNErrorCodeNotAuthorized]];

      expect([manager fetchAlbumWithURL:url]).will.matchError(^BOOL(NSError *error) {
        return error.code == PTNErrorCodeNotAuthorized;
      });
    });
  });
});

context(@"asset fetching", ^{
  it(@"should fetch asset with no revision", ^{
    DBMetadata *metadata = PTNDropboxCreateFileMetadata(kPath, nil);
    NSURL *url = [NSURL ptn_dropboxAssetURLWithEntry:[PTNDropboxEntry entryWithPath:kPath]];
    [dropboxClient serveMetadataAtPath:kPath revision:nil withMetadata:metadata];

    expect([manager fetchDescriptorWithURL:url]).will.sendValues(@[
      [[PTNDropboxFileDescriptor alloc] initWithMetadata:metadata]
    ]);
  });

  it(@"should fetch asset with revision", ^{
    DBMetadata *metadata = PTNDropboxCreateFileMetadata(kPath, kRevision);
    NSURL *url = [NSURL ptn_dropboxAssetURLWithEntry:[PTNDropboxEntry entryWithPath:kPath
                                                                        andRevision:kRevision]];
    [dropboxClient serveMetadataAtPath:kPath revision:kRevision withMetadata:metadata];

    expect([manager fetchDescriptorWithURL:url]).will.sendValues(@[
      [[PTNDropboxFileDescriptor alloc] initWithMetadata:metadata]
    ]);
  });

  it(@"should error when dropbox client errs", ^{
    NSURL *url = [NSURL ptn_dropboxAssetURLWithEntry:[PTNDropboxEntry entryWithPath:kPath]];
    [dropboxClient serveMetadataAtPath:kPath revision:nil
                             withError:[NSError lt_errorWithCode:1337]];

    expect([manager fetchDescriptorWithURL:url]).will.matchError(^BOOL(NSError *error) {
      return error.code == PTNErrorCodeAssetLoadingFailed;
    });
  });

  it(@"should error on invalid URL", ^{
    NSURL *url = [NSURL URLWithString:@"http://www.foo.com"];

    expect([manager fetchDescriptorWithURL:url]).will.matchError(^BOOL(NSError *error) {
      return error.code == PTNErrorCodeInvalidURL;
    });
  });

  it(@"should error when not authorized", ^{
    NSURL *url = [NSURL ptn_dropboxAssetURLWithEntry:[PTNDropboxEntry entryWithPath:kPath]];
    [dropboxClient serveMetadataAtPath:kPath revision:nil
                             withError:[NSError lt_errorWithCode:PTNErrorCodeNotAuthorized]];

    expect([manager fetchDescriptorWithURL:url]).will.matchError(^BOOL(NSError *error) {
      return error.code == PTNErrorCodeNotAuthorized;
    });
  });
});

context(@"image fetching", ^{
  __block id<PTNResizingStrategy> resizingStrategy;
  __block PTNImageFetchOptions *options;
  __block DBMetadata *metadata;
  __block id<PTNDescriptor> asset;
  __block id<PTNImageAsset> imageAsset;
  __block id<PTNImageAsset> thumbnailImageAsset;

  static NSString * const kAssetPath = @"foo.jpg";
  static NSString * const kImageLocalPath = @"tmp/foo.jpg";
  static NSString * const kThumbnailLocalPath = @"tmp/foo-thumbnai.jpg";

  beforeEach(^{
    resizingStrategy = OCMProtocolMock(@protocol(PTNResizingStrategy));
    options = [PTNImageFetchOptions optionsWithDeliveryMode:PTNImageDeliveryModeHighQuality
                                                 resizeMode:PTNImageResizeModeFast];
    metadata = PTNDropboxCreateFileMetadata(kAssetPath, nil);
    asset = [[PTNDropboxFileDescriptor alloc] initWithMetadata:metadata];

    LTPath *imagePath = [LTPath pathWithPath:kImageLocalPath];
    imageAsset = [[PTNFileBackedImageAsset alloc] initWithFilePath:imagePath
                                                       fileManager:fileManager
                                                      imageResizer:imageResizer
                                                  resizingStrategy:resizingStrategy];
    LTPath *thumbnailPath = [LTPath pathWithPath:kThumbnailLocalPath];
    thumbnailImageAsset = [[PTNFileBackedImageAsset alloc] initWithFilePath:thumbnailPath
                                                                fileManager:fileManager
                                                               imageResizer:imageResizer
                                                           resizingStrategy:resizingStrategy];
  });

  context(@"fetch image of asset", ^{
    it(@"should fetch image without revision", ^{
      [dropboxClient serveFileAtPath:kAssetPath revision:nil withProgress:nil
                           localPath:kImageLocalPath];

      RACSignal *values = [manager fetchImageWithDescriptor:asset
                                           resizingStrategy:resizingStrategy
                                                    options:options];

      expect(values).will.sendValues(@[[[PTNProgress alloc] initWithResult:imageAsset]]);
    });

    it(@"should fetch image with revision", ^{
      [dropboxClient serveFileAtPath:kAssetPath revision:kRevision withProgress:nil
                           localPath:kImageLocalPath];
      metadata = PTNDropboxCreateFileMetadata(kAssetPath, kRevision);
      asset = [[PTNDropboxFileDescriptor alloc] initWithMetadata:metadata];

      RACSignal *values = [manager fetchImageWithDescriptor:asset
                                           resizingStrategy:resizingStrategy
                                                    options:options];

      expect(values).will.sendValues(@[[[PTNProgress alloc] initWithResult:imageAsset]]);
    });

    it(@"should fetch image with progress", ^{
      [dropboxClient serveFileAtPath:kAssetPath revision:nil
                        withProgress:@[@0.25, @0.5, @0.75]
                           localPath:kImageLocalPath];

      expect([manager fetchImageWithDescriptor:asset
                              resizingStrategy:resizingStrategy
                                       options:options]).will.sendValues(@[
        [[PTNProgress alloc] initWithProgress:@0.25],
        [[PTNProgress alloc] initWithProgress:@0.5],
        [[PTNProgress alloc] initWithProgress:@0.75],
        [[PTNProgress alloc] initWithResult:imageAsset]
      ]);
    });

    it(@"should complete after fetching an image", ^{
      [dropboxClient serveFileAtPath:kAssetPath revision:nil withProgress:nil
                           localPath:kImageLocalPath];

      RACSignal *values = [manager fetchImageWithDescriptor:asset resizingStrategy:resizingStrategy
                                                    options:options];

      expect(values).will.sendValuesWithCount(1);
      expect(values).will.complete();
    });

    it(@"should use thumbnail when delivery mode is fast", ^{
      options = [PTNImageFetchOptions optionsWithDeliveryMode:PTNImageDeliveryModeFast
                                                   resizeMode:PTNImageResizeModeFast];
      PTNDropboxThumbnailType *type =
          [PTNDropboxThumbnailType enumWithValue:PTNDropboxThumbnailTypeExtraSmall];
      [dropboxClient serveThumbnailAtPath:kAssetPath type:type withLocalPath:kThumbnailLocalPath];

      RACSignal *values = [manager fetchImageWithDescriptor:asset
                                           resizingStrategy:resizingStrategy
                                                    options:options];

      expect(values).will.sendValues(@[[[PTNProgress alloc] initWithResult:thumbnailImageAsset]]);
    });

    it(@"should not use thumbnail when delivery mode is fast if a specific revision is required", ^{
      options = [PTNImageFetchOptions optionsWithDeliveryMode:PTNImageDeliveryModeFast
                                                   resizeMode:PTNImageResizeModeFast];
      [dropboxClient serveFileAtPath:kAssetPath revision:kRevision withProgress:nil
                           localPath:kImageLocalPath];
      metadata = PTNDropboxCreateFileMetadata(kAssetPath, kRevision);
      asset = [[PTNDropboxFileDescriptor alloc] initWithMetadata:metadata];

      RACSignal *values = [manager fetchImageWithDescriptor:asset
                                           resizingStrategy:resizingStrategy
                                                    options:options];

      expect(values).will.sendValues(@[[[PTNProgress alloc] initWithResult:imageAsset]]);
    });

    it(@"should error when dropbox client errs", ^{
      [dropboxClient serveFileAtPath:kAssetPath revision:nil withProgress:nil
                        finallyError:[NSError lt_errorWithCode:1337]];

      expect([manager fetchImageWithDescriptor:asset resizingStrategy:resizingStrategy
                                       options:options]).will.matchError(^BOOL(NSError *error) {
        return error.code == PTNErrorCodeAssetLoadingFailed;
      });
    });
  });

  it(@"should error on non-Dropbox asset", ^{
    id invalidAsset = OCMProtocolMock(@protocol(PTNDescriptor));
    RACSignal *values = [manager fetchImageWithDescriptor:invalidAsset
                                         resizingStrategy:resizingStrategy
                                                  options:options];

    expect(values).will.matchError(^BOOL(NSError *error) {
      return error.code == PTNErrorCodeInvalidDescriptor;
    });
  });

  context(@"fetch image of asset collection", ^{
    it(@"should fetch asset collection representative image", ^{
      DBMetadata *directoryMetadata =
          PTNDropboxCreateDirectoryMetadataWithContents(kRevision, @[metadata]);
      asset = [[PTNDropboxDirectoryDescriptor alloc] initWithMetadata:directoryMetadata];
      [dropboxClient serveMetadataAtPath:kRevision revision:nil withMetadata:directoryMetadata];
      [dropboxClient serveFileAtPath:kAssetPath revision:nil withProgress:nil
                           localPath:kImageLocalPath];

      RACSignal *values = [manager fetchImageWithDescriptor:asset
                                           resizingStrategy:resizingStrategy
                                                    options:options];

      expect(values).will.sendValues(@[[[PTNProgress alloc] initWithResult:imageAsset]]);
    });

    it(@"should error on non-existing key assets", ^{
      DBMetadata *directoryMetadata = PTNDropboxCreateDirectoryMetadata(kRevision);
      asset = [[PTNDropboxDirectoryDescriptor alloc] initWithMetadata:directoryMetadata];
      [dropboxClient serveMetadataAtPath:kRevision revision:nil withMetadata:directoryMetadata];

      RACSignal *values = [manager fetchImageWithDescriptor:asset
                                           resizingStrategy:resizingStrategy
                                                    options:options];

      expect(values).will.matchError(^BOOL(NSError *error) {
        return error.code == PTNErrorCodeKeyAssetsNotFound;
      });
    });

    it(@"should error on invalid directories", ^{
      DBMetadata *directoryMetadata = PTNDropboxCreateDirectoryMetadata(kRevision);
      asset = [[PTNDropboxDirectoryDescriptor alloc] initWithMetadata:directoryMetadata];
      [dropboxClient serveMetadataAtPath:kRevision revision:nil
                               withError:[NSError lt_errorWithCode:1337]];

      RACSignal *values = [manager fetchImageWithDescriptor:asset
                                           resizingStrategy:resizingStrategy
                                                    options:options];

      expect(values).will.matchError(^BOOL(NSError *error) {
        return error.code == PTNErrorCodeAlbumNotFound;
      });
    });

    it(@"should error when not authorized", ^{
      [dropboxClient serveFileAtPath:kAssetPath revision:nil withProgress:nil
                        finallyError:[NSError lt_errorWithCode:PTNErrorCodeNotAuthorized]];

      RACSignal *values = [manager fetchImageWithDescriptor:asset
                                           resizingStrategy:resizingStrategy
                                                    options:options];

      expect(values).will.matchError(^BOOL(NSError *error) {
        return error.code == PTNErrorCodeNotAuthorized;
      });
    });
  });

  context(@"opportunistic delivery mode", ^{
    __block RACSubject *thumbnailSubject;
    __block RACSubject *imageSubject;

    beforeEach(^{
      options = [PTNImageFetchOptions optionsWithDeliveryMode:PTNImageDeliveryModeOpportunistic
                                                   resizeMode:PTNImageResizeModeFast];
      thumbnailSubject = [[RACSubject alloc] init];
      imageSubject = [[RACSubject alloc] init];
      PTNDropboxRestClient *client = OCMClassMock([PTNDropboxRestClient class]);
      manager = [[PTNDropboxAssetManager alloc] initWithDropboxClient:client
                                                         imageResizer:imageResizer
                                                          fileManager:fileManager];
      OCMStub([client fetchThumbnail:kAssetPath type:OCMOCK_ANY]).andReturn(thumbnailSubject);
      OCMStub([client fetchFile:kAssetPath revision:nil]).andReturn(imageSubject);
    });

    it(@"should use both thumbnail and regular image", ^{
      LLSignalTestRecorder *values = [[manager fetchImageWithDescriptor:asset
                                                       resizingStrategy:resizingStrategy
                                                                options:options] testRecorder];

      [thumbnailSubject sendNext:kThumbnailLocalPath];
      [thumbnailSubject sendCompleted];
      expect(values).will.sendValuesWithCount(1);

      [imageSubject sendNext:[[PTNProgress alloc] initWithResult:kImageLocalPath]];
      [imageSubject sendCompleted];
      expect(values).will.complete();

      expect(values).to.sendValues(@[
        [[PTNProgress alloc] initWithResult:thumbnailImageAsset],
        [[PTNProgress alloc] initWithResult:imageAsset]
      ]);
    });

    it(@"should use just regular image if image arrives first", ^{
      LLSignalTestRecorder *values = [[manager fetchImageWithDescriptor:asset
                                 resizingStrategy:resizingStrategy
                                          options:options] testRecorder];

      [imageSubject sendNext:[[PTNProgress alloc] initWithResult:kImageLocalPath]];
      [imageSubject sendCompleted];
      expect(values).will.sendValuesWithCount(1);

      [thumbnailSubject sendNext:kThumbnailLocalPath];
      expect(values).will.complete();
      expect(values).will.sendValues(@[
        [[PTNProgress alloc] initWithResult:imageAsset]
      ]);
    });
  });
});

context(@"audiovisual fetching", ^{
  __block PTNAVAssetFetchOptions *options;
  __block DBMetadata *metadata;
  __block id<PTNDescriptor> asset;

  static NSString * const kAssetPath = @"foo.jpg";

  beforeEach(^{
    options = [PTNAVAssetFetchOptions optionsWithDeliveryMode:PTNVideoDeliveryModeFastFormat];
    metadata = PTNDropboxCreateFileMetadata(kAssetPath, nil);
    asset = [[PTNDropboxFileDescriptor alloc] initWithMetadata:metadata];
  });

  it(@"should err", ^{
    RACSignal *values = [manager fetchAVAssetWithDescriptor:asset options:options];

    expect(values).will.matchError(^BOOL(NSError *error) {
      return error.code == PTNErrorCodeUnsupportedOperation;
    });
  });
});

it(@"should err when fetching image data", ^{
  DBMetadata *metadata = PTNDropboxCreateFileMetadata(@"foo.jpg", nil);
  id<PTNDescriptor> asset = [[PTNDropboxFileDescriptor alloc] initWithMetadata:metadata];
  RACSignal *values = [manager fetchImageDataWithDescriptor:asset];

  expect(values).will.matchError(^BOOL(NSError *error) {
    return error.code == PTNErrorCodeUnsupportedOperation;
  });
});

SpecEnd
