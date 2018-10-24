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

  it(@"should encode and decode", ^{
    NSData *archive = [NSKeyedArchiver archivedDataWithRootObject:path];

    expect([NSKeyedUnarchiver unarchiveObjectWithData:archive]).to.equal(path);
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

  it(@"should encode and decode", ^{
    NSData *archive = [NSKeyedArchiver archivedDataWithRootObject:path];

    expect([NSKeyedUnarchiver unarchiveObjectWithData:archive]).to.equal(path);
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

  it(@"should encode and decode", ^{
    NSData *archive = [NSKeyedArchiver archivedDataWithRootObject:path];

    expect([NSKeyedUnarchiver unarchiveObjectWithData:archive]).to.equal(path);
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

  it(@"should encode and decode", ^{
    NSData *archive = [NSKeyedArchiver archivedDataWithRootObject:path];

    expect([NSKeyedUnarchiver unarchiveObjectWithData:archive]).to.equal(path);
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

  it(@"should encode and decode", ^{
    NSData *archive = [NSKeyedArchiver archivedDataWithRootObject:path];

    expect([NSKeyedUnarchiver unarchiveObjectWithData:archive]).to.equal(path);
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

  it(@"should encode and decode", ^{
    NSData *archive = [NSKeyedArchiver archivedDataWithRootObject:path];

    expect([NSKeyedUnarchiver unarchiveObjectWithData:archive]).to.equal(path);
  });
});

context(@"library base path", ^{
  __block LTPath *path;

  beforeEach(^{
    path = [LTPath pathWithBaseDirectory:LTPathBaseDirectoryLibrary andRelativePath:kPath];
  });

  it(@"should initialize with library base path", ^{
    expect(path.baseDirectory).to.equal(LTPathBaseDirectoryLibrary);
    expect(path.relativePath).to.equal(kPath);

    NSString *expectedPath =
        [[NSFileManager lt_libraryDirectory] stringByAppendingPathComponent:kPath];
    expect(path.path).to.equal(expectedPath);
    expect(path.url).to.equal([NSURL fileURLWithPath:expectedPath]);
  });

  it(@"should serialize and deserialize", ^{
    expect([LTPath pathWithRelativeURL:path.relativeURL]).to.equal(path);
  });

  it(@"should encode and decode", ^{
    NSData *archive = [NSKeyedArchiver archivedDataWithRootObject:path];

    expect([NSKeyedUnarchiver unarchiveObjectWithData:archive]).to.equal(path);
  });
});

context(@"no relative path", ^{
  __block LTPath *path;

  it(@"should initialize without relative path nor base path", ^{
    path = [LTPath pathWithBaseDirectory:LTPathBaseDirectoryNone andRelativePath:@""];
    expect(path.baseDirectory).to.equal(LTPathBaseDirectoryNone);
    expect(path.relativePath).to.equal(@"/");

    NSString *expectedPath = @"/";
    expect(path.path).to.equal(expectedPath);
    expect(path.url).to.equal([NSURL fileURLWithPath:expectedPath]);
  });

  it(@"should initialize with a base path and without a relative path", ^{
    path = [LTPath pathWithBaseDirectory:LTPathBaseDirectoryDocuments andRelativePath:@""];
    expect(path.baseDirectory).to.equal(LTPathBaseDirectoryDocuments);
    expect(path.relativePath).to.equal(@"/");

    NSString *expectedPath =
        [[NSFileManager lt_documentsDirectory] stringByAppendingPathComponent:@"/"];
    expect(path.path).to.equal(expectedPath);
    expect(path.url).to.equal([NSURL fileURLWithPath:expectedPath]);
  });

  it(@"should encode and decode", ^{
    NSData *archive = [NSKeyedArchiver archivedDataWithRootObject:path];

    expect([NSKeyedUnarchiver unarchiveObjectWithData:archive]).to.equal(path);
  });
});

it(@"should create a file with UUID as file name", ^{
  auto path = [LTPath temporaryPathWithExtension:@"bar"];
  expect(path.baseDirectory).to.equal(LTPathBaseDirectoryTemp);
  auto uuidString = [[path.relativePath lastPathComponent] stringByDeletingPathExtension];
  auto uuid = [[NSUUID alloc] initWithUUIDString:uuidString];
  expect(uuid).notTo.beNil();
  expect([path.relativePath pathExtension]).to.equal(@"bar");
});

context(@"path from URL", ^{
  it(@"should initialize with the path of the URL", ^{
    auto _Nullable path = [LTPath pathWithFileURL:nn([NSURL URLWithString:@"file:///var/foo.bar"])];
    expect(path.baseDirectory).to.equal(LTPathBaseDirectoryNone);
    expect(path.path).to.equal(@"/var/foo.bar");
  });

  it(@"should return the same URL the path was initialized with", ^{
    auto url = [NSURL URLWithString:@"file:///var/foo.bar"];
    auto path = [LTPath pathWithFileURL:url];
    expect(path.url).to.equal(url);
  });

  it(@"should return nil if URL is not file URL", ^{
    auto _Nullable path = [LTPath pathWithFileURL:nn([NSURL URLWithString:@"https://foo/bar"])];
    expect(path).to.beNil();
  });

  it(@"should return nil if URL does not contain a path", ^{
    auto _Nullable path = [LTPath pathWithFileURL:nn([NSURL URLWithString:@"file://"])];
    expect(path).to.beNil();
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

it(@"should not standardize a path", ^{
  expect([LTPath pathWithPath:@"/foo/./bar"].path).to.equal(@"/foo/./bar");
});

SpecEnd
