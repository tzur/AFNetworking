// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "PTNFileSystemDirectoryDescriptor.h"

#import <LTKit/LTPath.h>

#import "NSURL+FileSystem.h"

SpecBegin(PTNFileSystemDirectoryDescriptor)

static NSString * const kPath = @"/foo";

it(@"should initialize with path", ^{
  LTPath *path = [LTPath pathWithBaseDirectory:LTPathBaseDirectoryTemp
                               andRelativePath:kPath];
  PTNFileSystemDirectoryDescriptor *descriptor = [[PTNFileSystemDirectoryDescriptor alloc]
                                                  initWithPath:path];
  NSURL *identifier = descriptor.ptn_identifier;

  expect(identifier.ptn_fileSystemURLType).to.equal(PTNFileSystemURLTypeAlbum);
  expect(identifier.ptn_fileSystemAlbumPath).to.equal(path);
  expect(descriptor.descriptorCapabilities).to.equal(PTNDescriptorCapabilityNone);
  expect(descriptor.albumDescriptorCapabilities).to.equal(PTNAlbumDescriptorCapabilityNone);
  expect(descriptor.descriptorTraits).to.equal([NSSet set]);
});

it(@"should use last path component for localized title", ^{
  LTPath *path = [LTPath pathWithBaseDirectory:LTPathBaseDirectoryTemp
                               andRelativePath:@"/foo/bar/"];
  PTNFileSystemDirectoryDescriptor *descriptor = [[PTNFileSystemDirectoryDescriptor alloc]
                                                  initWithPath:path];

  expect(descriptor.localizedTitle).to.equal(@"bar");
});

context(@"equality", ^{
  __block PTNFileSystemDirectoryDescriptor *firstDirectory;
  __block PTNFileSystemDirectoryDescriptor *secondDirectory;

  beforeEach(^{
    id path = OCMClassMock([LTPath class]);

    firstDirectory = [[PTNFileSystemDirectoryDescriptor alloc] initWithPath:path];
    secondDirectory = [[PTNFileSystemDirectoryDescriptor alloc] initWithPath:path];
  });

  it(@"should handle isEqual correctly", ^{
    expect(firstDirectory).to.equal(secondDirectory);
    expect(secondDirectory).to.equal(firstDirectory);
  });

  it(@"should create proper hash", ^{
    expect(firstDirectory.hash).to.equal(secondDirectory.hash);
  });
});

SpecEnd
