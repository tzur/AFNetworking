// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "PTNFileSystemFileDescriptor.h"

#import <LTKit/LTPath.h>

#import "NSURL+FileSystem.h"

SpecBegin(PTNFileSystemFileDescriptor)

static NSString * const kPath = @"/foo";

it(@"should initialize with path", ^{
  LTPath *path = [LTPath pathWithBaseDirectory:LTPathBaseDirectoryTemp
                               andRelativePath:kPath];
  PTNFileSystemFileDescriptor *descriptor = [[PTNFileSystemFileDescriptor alloc] initWithPath:path];
  NSURL *identifier = descriptor.ptn_identifier;

  expect(identifier.ptn_fileSystemURLType).to.equal(PTNFileSystemURLTypeAsset);
  expect(identifier.ptn_fileSystemAssetPath).to.equal(path);
  expect(descriptor.creationDate).to.beNil();
  expect(descriptor.modificationDate).to.beNil();
});

it(@"should use last path component for localized title", ^{
  LTPath *path = [LTPath pathWithBaseDirectory:LTPathBaseDirectoryTemp
                               andRelativePath:@"/foo/bar.jpg"];
  PTNFileSystemFileDescriptor *descriptor = [[PTNFileSystemFileDescriptor alloc]
                                             initWithPath:path];
  
  expect(descriptor.localizedTitle).to.equal(@"bar.jpg");
});

it(@"should initialize with path and creation and modification dates", ^{
  LTPath *path = [LTPath pathWithBaseDirectory:LTPathBaseDirectoryTemp
                               andRelativePath:kPath];
  NSDate *creationDate = [[NSDate alloc] init];
  NSDate *modificationDate = [[NSDate alloc] init];
  PTNFileSystemFileDescriptor *descriptor =
      [[PTNFileSystemFileDescriptor alloc] initWithPath:path creationDate:creationDate
                                       modificationDate:modificationDate];
  NSURL *identifier = descriptor.ptn_identifier;

  expect(identifier.ptn_fileSystemURLType).to.equal(PTNFileSystemURLTypeAsset);
  expect(identifier.ptn_fileSystemAssetPath).to.equal(path);
  expect(descriptor.creationDate).to.equal(creationDate);
  expect(descriptor.modificationDate).to.equal(modificationDate);
});

context(@"equality", ^{
  __block PTNFileSystemFileDescriptor *firstFile;
  __block PTNFileSystemFileDescriptor *secondFile;

  beforeEach(^{
    id path = OCMClassMock([LTPath class]);

    firstFile = [[PTNFileSystemFileDescriptor alloc] initWithPath:path];
    secondFile = [[PTNFileSystemFileDescriptor alloc] initWithPath:path];
  });

  it(@"should handle isEqual correctly", ^{
    expect(firstFile).to.equal(secondFile);
    expect(secondFile).to.equal(firstFile);
  });

  it(@"should create proper hash", ^{
    expect(firstFile.hash).to.equal(secondFile.hash);
  });
});

SpecEnd
