// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNDropboxAlbum.h"

#import "PTNDropboxDirectoryDescriptor.h"
#import "PTNDropboxEntry.h"
#import "PTNDropboxFileDescriptor.h"
#import "PTNDropboxTestUtils.h"

SpecBegin(PTNDropboxAlbum)

it(@"should initialize with path, subdirectories and files", ^{
  PTNDropboxEntry *entry = [PTNDropboxEntry entryWithPath:@"foo/bar" andRevision:@"baz"];

  DBMetadata *directoryMetadata1 = PTNDropboxCreateDirectoryMetadata(@"foo/bar/baz");
  DBMetadata *directoryMetadata2 = PTNDropboxCreateDirectoryMetadata(@"foo/bar/gaz");

  PTNDropboxSubdirectories *subdirectories = @[
    [[PTNDropboxDirectoryDescriptor alloc] initWithMetadata:directoryMetadata1],
    [[PTNDropboxDirectoryDescriptor alloc] initWithMetadata:directoryMetadata2]
  ];

  DBMetadata *fileMetadata1 = PTNDropboxCreateFileMetadata(@"foo/bar/baz.jpg", @"gaz");
  DBMetadata *fileMetadata2 = PTNDropboxCreateFileMetadata(@"foo/bar/gaz.jpg", @"qux");

  PTNDropboxFiles *files = @[
    [[PTNDropboxFileDescriptor alloc] initWithMetadata:fileMetadata1],
    [[PTNDropboxFileDescriptor alloc] initWithMetadata:fileMetadata2]
  ];

  NSURL *url = [NSURL ptn_dropboxAlbumURLWithEntry:entry];
  PTNDropboxAlbum *album = [[PTNDropboxAlbum alloc] initWithPath:url
                                                  subdirectories:subdirectories files:files];

  expect(album.url).to.equal(url);
  expect(album.subalbums).to.equal(subdirectories);
  expect(album.assets).to.equal(files);
});

context(@"equality", ^{
  __block PTNDropboxAlbum *firstAlbum;
  __block PTNDropboxAlbum *secondAlbum;

  beforeEach(^{
    id entry = [PTNDropboxEntry entryWithPath:@"foo/bar" andRevision:@"baz"];
    id directories = @[
      [[PTNDropboxDirectoryDescriptor alloc]
       initWithMetadata:PTNDropboxCreateDirectoryMetadata(@"foo/bar/baz")],
      [[PTNDropboxDirectoryDescriptor alloc]
       initWithMetadata:PTNDropboxCreateDirectoryMetadata(@"foo/bar/gaz")]
    ];
    id files = @[
      [[PTNDropboxFileDescriptor alloc]
       initWithMetadata:PTNDropboxCreateFileMetadata(@"foo/bar/baz.jpg", @"gaz")],
      [[PTNDropboxFileDescriptor alloc]
       initWithMetadata:PTNDropboxCreateFileMetadata(@"foo/bar/gaz.jpg", @"qux")]
    ];

    firstAlbum = [[PTNDropboxAlbum alloc] initWithPath:[NSURL ptn_dropboxAlbumURLWithEntry:entry]
                                        subdirectories:directories files:files];
    secondAlbum = [[PTNDropboxAlbum alloc] initWithPath:[NSURL ptn_dropboxAlbumURLWithEntry:entry]
                                         subdirectories:directories files:files];
  });

  it(@"should handle isEqual correctly", ^{
    expect(firstAlbum).to.equal(secondAlbum);
    expect(secondAlbum).to.equal(firstAlbum);
  });

  it(@"should create proper hash", ^{
    expect(firstAlbum.hash).to.equal(secondAlbum.hash);
  });
});

SpecEnd
