// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "LTPath.h"

#import "NSFileManager+LTKit.h"

SpecBegin(LTPath)

static NSString * const kPath = @"/foo/bar";

context(@"no base path", ^{
  __block LTPath *path;

  beforeEach(^{
    path = [LTPath pathWithBaseDirectory:LTPathBaseDirectoryNone andRelativePath:kPath];
  });

  it(@"should initialize with no base path", ^{
    expect(path.baseDirectory).to.equal(LTPathBaseDirectoryNone);
    expect(path.relativePath).to.equal(kPath);
    expect(path.path).to.equal(kPath);
    expect(path.url.path).to.equal(kPath);
  });

  it(@"should serialize and deserialize", ^{
    expect([LTPath pathWithRelativeURL:path.relativeURL]).to.equal(path);
  });
});

context(@"temp base path", ^{
  __block LTPath *path;

  beforeEach(^{
    path = [LTPath pathWithBaseDirectory:LTPathBaseDirectoryTemp andRelativePath:kPath];
  });

  it(@"should initialize with temp base path", ^{
    expect(path.baseDirectory).to.equal(LTPathBaseDirectoryTemp);
    expect(path.relativePath).to.equal(kPath);

    NSString *expectedPath = [NSTemporaryDirectory() stringByAppendingPathComponent:kPath];
    expect(path.path).to.equal(expectedPath);
    expect(path.url).to.equal([NSURL fileURLWithPath:expectedPath]);
  });

  it(@"should serialize and deserialize", ^{
    expect([LTPath pathWithRelativeURL:path.relativeURL]).to.equal(path);
  });
});

context(@"documents base path", ^{
  __block LTPath *path;

  beforeEach(^{
    path = [LTPath pathWithBaseDirectory:LTPathBaseDirectoryDocuments andRelativePath:kPath];
  });

  it(@"should initialize with documents base path", ^{
    expect(path.baseDirectory).to.equal(LTPathBaseDirectoryDocuments);
    expect(path.relativePath).to.equal(kPath);

    NSString *expectedPath =
    [[NSFileManager lt_documentsDirectory] stringByAppendingPathComponent:kPath];
    expect(path.path).to.equal(expectedPath);
    expect(path.url).to.equal([NSURL fileURLWithPath:expectedPath]);
  });

  it(@"should serialize and deserialize", ^{
    expect([LTPath pathWithRelativeURL:path.relativeURL]).to.equal(path);
  });
});

context(@"main bundle base path", ^{
  __block LTPath *path;

  beforeEach(^{
    path = [LTPath pathWithBaseDirectory:LTPathBaseDirectoryMainBundle andRelativePath:kPath];
  });

  it(@"should initialize with main bundle base path", ^{
    expect(path.baseDirectory).to.equal(LTPathBaseDirectoryMainBundle);
    expect(path.relativePath).to.equal(kPath);

    NSString *expectedPath = [[[NSBundle mainBundle] bundlePath]
                              stringByAppendingPathComponent:kPath];
    expect(path.path).to.equal(expectedPath);
    expect(path.url).to.equal([NSURL fileURLWithPath:expectedPath]);
  });

  it(@"should serialize and deserialize", ^{
    expect([LTPath pathWithRelativeURL:path.relativeURL]).to.equal(path);
  });
});

context(@"caches base path", ^{
  __block LTPath *path;

  beforeEach(^{
    path = [LTPath pathWithBaseDirectory:LTPathBaseDirectoryCaches andRelativePath:kPath];
  });

  it(@"should initialize with caches base path", ^{
    expect(path.baseDirectory).to.equal(LTPathBaseDirectoryCaches);
    expect(path.relativePath).to.equal(kPath);

    NSString *expectedPath =
    [[NSFileManager lt_cachesDirectory] stringByAppendingPathComponent:kPath];
    expect(path.path).to.equal(expectedPath);
    expect(path.url).to.equal([NSURL fileURLWithPath:expectedPath]);
  });

  it(@"should serialize and deserialize", ^{
    expect([LTPath pathWithRelativeURL:path.relativeURL]).to.equal(path);
  });
});

context(@"application support base path", ^{
  __block LTPath *path;

  beforeEach(^{
    path = [LTPath pathWithBaseDirectory:LTPathBaseDirectoryApplicationSupport
                         andRelativePath:kPath];
  });

  it(@"should initialize with application support base path", ^{
    expect(path.baseDirectory).to.equal(LTPathBaseDirectoryApplicationSupport);
    expect(path.relativePath).to.equal(kPath);

    NSString *expectedPath =
        [[NSFileManager lt_applicationSupportDirectory] stringByAppendingPathComponent:kPath];
    expect(path.path).to.equal(expectedPath);
    expect(path.url).to.equal([NSURL fileURLWithPath:expectedPath]);
  });

  it(@"should serialize and deserialize", ^{
    expect([LTPath pathWithRelativeURL:path.relativeURL]).to.equal(path);
  });
});

context(@"path operations", ^{
  it(@"should append path component", ^{
    LTPath *path = [LTPath pathWithBaseDirectory:LTPathBaseDirectoryTemp andRelativePath:kPath];
    LTPath *newPath = [path pathByAppendingPathComponent:@"gaz"];
    expect(newPath.path).to.equal([path.path stringByAppendingPathComponent:@"gaz"]);
    expect(newPath.baseDirectory).to.equal(path.baseDirectory);
    newPath = [path pathByAppendingPathComponent:@"/gaz"];
    expect(newPath.path).to.equal([path.path stringByAppendingPathComponent:@"/gaz"]);
    expect(newPath.baseDirectory).to.equal(path.baseDirectory);
  });

  it(@"should append path extension", ^{
    LTPath *path = [LTPath pathWithBaseDirectory:LTPathBaseDirectoryTemp andRelativePath:kPath];
    LTPath *newPath = [path pathByAppendingPathExtension:@"gaz"];
    expect(newPath.path).to.equal([path.path stringByAppendingPathExtension:@"gaz"]);
    expect(newPath.baseDirectory).to.equal(path.baseDirectory);
    newPath = [path pathByAppendingPathExtension:@".gaz"];
    expect(newPath.path).to.equal([path.path stringByAppendingPathExtension:@".gaz"]);
    expect(newPath.baseDirectory).to.equal(path.baseDirectory);
  });
});

SpecEnd
