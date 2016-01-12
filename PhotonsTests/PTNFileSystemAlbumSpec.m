// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "PTNFileSystemAlbum.h"

#import <LTKit/LTPath.h>

#import "PTNFileSystemDirectoryDescriptor.h"
#import "PTNFileSystemFileDescriptor.h"

SpecBegin(PTNFileSystemAlbum)

it(@"should initialize with path, subdirectories and files", ^{
  LTPath *path = [LTPath pathWithBaseDirectory:LTPathBaseDirectoryTemp andRelativePath:@"/foo"];

  LTPath *subdirectoryPath1 = [LTPath pathWithBaseDirectory:LTPathBaseDirectoryNone
                                            andRelativePath:@"/foo/bar"];
  LTPath *subdirectoryPath2 = [LTPath pathWithBaseDirectory:LTPathBaseDirectoryNone
                                            andRelativePath:@"/foo/baz"];
  PTNFileSystemSubdirectories *subdirectories = @[
    [[PTNFileSystemDirectoryDescriptor alloc] initWithPath:subdirectoryPath1],
    [[PTNFileSystemDirectoryDescriptor alloc] initWithPath:subdirectoryPath2]
  ];

  LTPath *filePath1 = [LTPath pathWithBaseDirectory:LTPathBaseDirectoryNone
                                    andRelativePath:@"/foo/a.jpg"];
  LTPath *filePath2 = [LTPath pathWithBaseDirectory:LTPathBaseDirectoryNone
                                    andRelativePath:@"/foo/b.jpg"];
  PTNFileSystemFiles *files = @[
    [[PTNFileSystemFileDescriptor alloc] initWithPath:filePath1],
    [[PTNFileSystemFileDescriptor alloc] initWithPath:filePath2]
  ];

  PTNFileSystemAlbum *album = [[PTNFileSystemAlbum alloc] initWithPath:path.url
                                                        subdirectories:subdirectories files:files];

  expect(album.url).to.equal(path.url);
  expect(album.subalbums).to.equal(subdirectories);
  expect(album.assets).to.equal(files);
});

context(@"equality", ^{
  __block PTNFileSystemAlbum *firstAlbum;
  __block PTNFileSystemAlbum *secondAlbum;

  beforeEach(^{
    id path = [LTPath pathWithPath:@"foo/bar"];
    id files = @[
      [[PTNFileSystemDirectoryDescriptor alloc] initWithPath:[LTPath pathWithPath:@"/foo/bar"]],
      [[PTNFileSystemDirectoryDescriptor alloc] initWithPath:[LTPath pathWithPath:@"/foo/baz"]]
    ];
    id subdirectories = @[
      [[PTNFileSystemFileDescriptor alloc] initWithPath:[LTPath pathWithPath:@"foo/a.jpg"]],
      [[PTNFileSystemFileDescriptor alloc] initWithPath:[LTPath pathWithPath:@"foo/b.jpg"]]
    ];

    firstAlbum = [[PTNFileSystemAlbum alloc] initWithPath:path subdirectories:subdirectories
                                                    files:files];
    secondAlbum = [[PTNFileSystemAlbum alloc] initWithPath:path subdirectories:subdirectories
                                                     files:files];
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
