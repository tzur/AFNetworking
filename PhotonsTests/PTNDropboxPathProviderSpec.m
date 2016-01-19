// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNDropboxPathProvider.h"

SpecBegin(PTNDropboxPathProvider)

__block PTNDropboxPathProvider *pathProvider;
__block NSString *firstPath;
__block NSString *secondPath;

beforeEach(^{
  pathProvider = [[PTNDropboxPathProvider alloc] init];
});

it(@"should conserve file name extension", ^{
  firstPath = [pathProvider localPathForFileInPath:@"foo/bar.jpg" revision:nil];

  expect([firstPath pathExtension]).to.equal(@"jpg");
});

it(@"should give equal local paths for equal paths", ^{
  firstPath = [pathProvider localPathForFileInPath:@"foo/bar.jpg" revision:nil];
  secondPath = [pathProvider localPathForFileInPath:@"foo/bar.jpg" revision:nil];

  expect(firstPath).to.equal(secondPath);
});

it(@"should give different local paths for different paths", ^{
  firstPath = [pathProvider localPathForFileInPath:@"foo/bar.jpg" revision:nil];
  secondPath = [pathProvider localPathForFileInPath:@"bar/baz.jpg" revision:nil];

  expect(firstPath).toNot.equal(secondPath);
});

context(@"thumbnails", ^{
  __block CGSize thumbnailSize;

  beforeEach(^{
    thumbnailSize = CGSizeMake(20, 10);
  });

  it(@"should give equal local paths for thumbnails of equal path and size", ^{
    firstPath = [pathProvider localPathForThumbnailInPath:@"foo/bar" size:thumbnailSize];
    firstPath = [pathProvider localPathForThumbnailInPath:@"foo/bar" size:thumbnailSize];

    expect(firstPath).toNot.equal(secondPath);
  });

  it(@"should give different local paths for thumbnails of equal paths and different size", ^{
    firstPath = [pathProvider localPathForThumbnailInPath:@"foo/bar" size:thumbnailSize];
    firstPath = [pathProvider localPathForThumbnailInPath:@"foo/bar" size:thumbnailSize];

    expect(firstPath).toNot.equal(secondPath);
  });
});

context(@"revision", ^{
  it(@"should conserve file name extension", ^{
    firstPath = [pathProvider localPathForFileInPath:@"foo/bar.jpg" revision:@"baz"];

    expect([firstPath pathExtension]).to.equal(@"jpg");
  });

  it(@"should give equal local paths for equal paths and revisions", ^{
    firstPath = [pathProvider localPathForFileInPath:@"foo/bar.jpg" revision:@"baz"];
    secondPath = [pathProvider localPathForFileInPath:@"foo/bar.jpg" revision:@"baz"];

    expect(firstPath).to.equal(secondPath);
  });

  it(@"should give different local paths for different paths and equal revisions", ^{
    firstPath = [pathProvider localPathForFileInPath:@"foo/bar.jpg" revision:@"baz"];
    secondPath = [pathProvider localPathForFileInPath:@"bar/baz.jpg" revision:@"baz"];

    expect(firstPath).toNot.equal(secondPath);
  });

  it(@"should give different local paths for equal paths and different revisions", ^{
    firstPath = [pathProvider localPathForFileInPath:@"foo/bar.jpg" revision:@"baz"];
    secondPath = [pathProvider localPathForFileInPath:@"bar/baz.jpg" revision:@"qux"];

    expect(firstPath).toNot.equal(secondPath);
  });
});

SpecEnd
