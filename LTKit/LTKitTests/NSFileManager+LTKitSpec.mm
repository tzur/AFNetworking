// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "NSFileManager+LTKit.h"

#import "NSFileManagerTestUtils.h"

SpecBegin(NSFileManager_LTKit)

__block id fileManager;

beforeEach(^{
  fileManager = [NSFileManager defaultManager];
});

context(@"plist dictionaries", ^{
  static NSString * const kPath = @"/a/b/file";
  static NSError * const kError = [NSError lt_errorWithCode:1337];

  __block id mockedManager;
  __block NSError *error;
  __block NSDictionary *validDictionary;
  __block NSDictionary *invalidDictionary;

  beforeEach(^{
    mockedManager = OCMPartialMock(fileManager);

    validDictionary = @{
      @"bool": @YES,
      @"number": @2,
      @"string": @"string",
      @"array": @[@YES, @2],
      @"dictionary": @{
        @"dictionary.bool": @YES,
        @"dictionary.number": @2
      }
    };

    invalidDictionary = @{
      @"bool": @YES,
      @"number": @2,
      @"string": @"string",
      @"invalid": [NSValue valueWithCGPoint:CGPointZero]
    };
  });

  afterEach(^{
    mockedManager = nil;
    error = nil;
  });

  it(@"should write a dictionary containing a valid plist in binary format", ^{
    OCMExpect([mockedManager lt_writeData:[OCMArg checkWithBlock:^BOOL(NSData *data) {
      NSError *error;
      NSPropertyListFormat format;
      NSDictionary *dictionary = [NSPropertyListSerialization
                                  propertyListWithData:data options:NSPropertyListImmutable
                                  format:&format error:&error];
      return [dictionary isEqual:validDictionary] && !error &&
      format == NSPropertyListBinaryFormat_v1_0;
    }] toFile:kPath options:NSDataWritingAtomic error:[OCMArg anyObjectRef]]).andReturn(YES);

    BOOL success = [fileManager lt_writeDictionary:validDictionary toFile:kPath
                                            format:NSPropertyListBinaryFormat_v1_0 error:&error];

    expect(success).to.beTruthy();
    expect(error).to.beNil();
    OCMVerifyAll(mockedManager);
  });

  it(@"should write a dictionary containing a valid plist in XML format by default", ^{
    OCMExpect([mockedManager lt_writeData:[OCMArg checkWithBlock:^BOOL(NSData *data) {
      NSError *error;
      NSPropertyListFormat format;
      NSDictionary *dictionary = [NSPropertyListSerialization
                                  propertyListWithData:data options:NSPropertyListImmutable
                                  format:&format error:&error];
      return [dictionary isEqual:validDictionary] && !error &&
          format == NSPropertyListXMLFormat_v1_0;
    }] toFile:kPath options:NSDataWritingAtomic error:[OCMArg anyObjectRef]]).andReturn(YES);

    BOOL success = [fileManager lt_writeDictionary:validDictionary toFile:kPath error:&error];

    expect(success).to.beTruthy();
    expect(error).to.beNil();
    OCMVerifyAll(mockedManager);
  });

  it(@"should return no and populate error when trying to write an invalid dictionary", ^{
    [[mockedManager reject] lt_writeData:[OCMArg any] toFile:kPath
                        options:NSDataWritingAtomic error:[OCMArg anyObjectRef]];

    BOOL success = [fileManager lt_writeDictionary:invalidDictionary toFile:kPath error:&error];

    expect(success).to.beFalsy();
    expect(error).notTo.beNil();
    OCMVerifyAll(mockedManager);
  });

  it(@"should return no and populate error if failed to write a valid dictionary", ^{
    OCMExpect([mockedManager lt_writeData:[OCMArg any] toFile:kPath options:NSDataWritingAtomic
                           error:[OCMArg setTo:kError]]).andReturn(NO);

    BOOL success = [fileManager lt_writeDictionary:validDictionary toFile:kPath error:&error];

    expect(success).to.beFalsy();
    expect(error).notTo.beNil();
    expect(error.lt_underlyingError).to.beIdenticalTo(kError);
    OCMVerifyAll(mockedManager);
  });

  it(@"should read a file containing a valid plist in XML format", ^{
    __block NSData *serializedData;
    OCMExpect([mockedManager lt_writeData:[OCMArg checkWithBlock:^BOOL(NSData *data) {
      serializedData = data;
      return YES;
    }] toFile:kPath options:NSDataWritingAtomic error:[OCMArg anyObjectRef]]).andReturn(YES);
    [fileManager lt_writeDictionary:validDictionary toFile:kPath error:&error];
    expect(serializedData).notTo.beNil();
    OCMVerifyAll(mockedManager);

    OCMExpect([mockedManager lt_dataWithContentsOfFile:kPath options:NSDataReadingUncached
                                        error:[OCMArg anyObjectRef]]).andReturn(serializedData);

    NSDictionary *dictionary = [fileManager lt_dictionaryWithContentsOfFile:kPath error:&error];

    expect(dictionary).to.equal(validDictionary);
    expect(error).to.beNil();
    OCMVerifyAll(mockedManager);
  });

  it(@"should read a file containing a valid plist in binary format", ^{
    __block NSData *serializedData;
    OCMExpect([mockedManager lt_writeData:[OCMArg checkWithBlock:^BOOL(NSData *data) {
      serializedData = data;
      return YES;
    }] toFile:kPath options:NSDataWritingAtomic error:[OCMArg anyObjectRef]]).andReturn(YES);
    [fileManager lt_writeDictionary:validDictionary toFile:kPath
                             format:NSPropertyListBinaryFormat_v1_0 error:&error];
    expect(serializedData).notTo.beNil();
    OCMVerifyAll(mockedManager);

    OCMExpect([mockedManager lt_dataWithContentsOfFile:kPath options:NSDataReadingUncached
                                                 error:[OCMArg anyObjectRef]])
        .andReturn(serializedData);

    NSDictionary *dictionary = [fileManager lt_dictionaryWithContentsOfFile:kPath error:&error];

    expect(dictionary).to.equal(validDictionary);
    expect(error).to.beNil();
    OCMVerifyAll(mockedManager);
  });

  it(@"should return nil and populate error if failed to read the file at the given path", ^{
    OCMExpect([mockedManager lt_dataWithContentsOfFile:kPath options:NSDataReadingUncached
                                        error:[OCMArg setTo:kError]]);

    NSDictionary *dictionary = [fileManager lt_dictionaryWithContentsOfFile:kPath error:&error];

    expect(dictionary).to.beNil();
    expect(error).notTo.beNil();
    expect(error.lt_underlyingError).to.beIdenticalTo(kError);
    OCMVerifyAll(mockedManager);
  });

  it(@"should return nil and populate error if failed to deserialize the file into a dictionary", ^{
    NSData *invalidData = [@"<xml><a></b></xml>" dataUsingEncoding:NSUTF8StringEncoding];
    OCMExpect([mockedManager lt_dataWithContentsOfFile:kPath options:NSDataReadingUncached
                                      error:[OCMArg anyObjectRef]]).andReturn(invalidData);

    NSDictionary *dictionary = [fileManager lt_dictionaryWithContentsOfFile:kPath error:&error];

    expect(dictionary).to.beNil();
    expect(error).notTo.beNil();
    OCMVerifyAll(mockedManager);
  });
});

it(@"should write data", ^{
  id data = [OCMockObject mockForClass:[NSData class]];

  NSString *file = @"MyFile";
  NSDataWritingOptions options = NSDataWritingAtomic;
  NSError *error;

  [[[data expect] andReturnValue:@YES] writeToFile:file options:options
                                             error:(NSError *__autoreleasing *)[OCMArg anyPointer]];

  BOOL succeeded = [fileManager lt_writeData:data toFile:file options:options error:&error];
  expect(succeeded).to.beTruthy();
  expect(error).to.beNil();

  OCMVerifyAll(data);
});

it(@"should read data from file", ^{
  NSString *path = [NSBundle.lt_testBundle executablePath];

  NSError *error;
  NSData *data = [fileManager lt_dataWithContentsOfFile:path options:0 error:&error];

  expect(error).to.beNil();

  NSData *file = [NSData dataWithContentsOfFile:path];
  expect(data).to.equal(file);
});

it(@"should not set backup flag for non existing file", ^{
  NSURL *url = [NSURL fileURLWithPath:@"/foo/bar"];
  __block NSError *error;

  expect([fileManager lt_skipBackup:YES forItemAtURL:url error:&error]).to.beFalsy();
  expect(error).notTo.beNil();
});

context(@"globbing", ^{
  static NSString * const kPath = @"/";
  static NSURL * const kPathURL = [NSURL fileURLWithPath:kPath];

  __block id mockedManager;

  beforeEach(^{
    mockedManager = OCMPartialMock(fileManager);
  });

  afterEach(^{
    mockedManager = nil;
  });

  context(@"globbing shallowly", ^{
    beforeEach(^{
      NSArray<NSURL *> *mockedFiles = @[LTCreateFakeURL(@"foo"), LTCreateFakeURL(@"bar")];
      LTStubFileManager(mockedManager, kPathURL, NO, mockedFiles);
    });

    it(@"should glob directory", ^{
      NSError *error;
      NSArray<NSString *> *files = [mockedManager lt_globPath:kPath recursively:NO
                                                withPredicate:[NSPredicate predicateWithValue:YES]
                                                        error:&error];

      expect(files).to.equal(@[@"foo", @"bar"]);
      expect(error).to.beNil();
    });

    it(@"should glob directory with predicate", ^{
      NSError *error;
      NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF == %@", @"bar"];
      NSArray<NSString *> *files = [mockedManager lt_globPath:kPath recursively:NO
                                                withPredicate:predicate error:&error];

      expect(files).to.equal(@[@"bar"]);
      expect(error).to.beNil();
    });
  });

  context(@"globbing recursively", ^{
    beforeEach(^{
      NSArray<NSURL *> *mockedFiles = @[LTCreateFakeURL(@"foo"), LTCreateFakeURL(@"foo/bar")];
      LTStubFileManager(mockedManager, kPathURL, YES, mockedFiles);
    });

    it(@"should glob directory", ^{
      NSError *error;
      NSArray<NSString *> *files = [mockedManager lt_globPath:kPath recursively:YES
                                                withPredicate:[NSPredicate predicateWithValue:YES]
                                                        error:&error];

      expect(files).to.equal(@[@"foo", @"foo/bar"]);
      expect(error).to.beNil();
    });
  });

  context(@"failures", ^{
    it(@"should fail globbing invalid path", ^{
      NSError *error;
      NSArray<NSString *> *files = [fileManager lt_globPath:@"/foo/bar/baz" recursively:NO
                                              withPredicate:[NSPredicate predicateWithValue:YES]
                                                      error:&error];

      expect(files).to.beFalsy();
      expect(error).notTo.beNil();
    });

    it(@"should fail globbing if failed retrieving file name", ^{
      NSError *fakeError = [NSError lt_errorWithCode:LTErrorCodeFileUnknownError];
      NSArray<NSURL *> *mockedFiles = @[LTCreateFakeURL(@"foo"),
                                        LTCreateFakeURLWithError(fakeError)];
      LTStubFileManager(mockedManager, kPathURL, NO, mockedFiles);

      NSError *error;
      NSArray<NSString *> *files = [mockedManager lt_globPath:kPath recursively:NO
                                                withPredicate:[NSPredicate predicateWithValue:YES]
                                                        error:&error];

      expect(files).to.beNil();
      expect(error).notTo.beNil();
    });

    it(@"should fail globbing if enumeration returned an error", ^{
      NSError *fakeError = [NSError lt_errorWithCode:LTErrorCodeFileUnknownError];
      NSArray<NSURL *> *mockedFiles = @[LTCreateFakeURL(@"foo"),
                                        LTCreateFakeURLWithError(fakeError)];
      LTStubFileManagerWithError(mockedManager, kPathURL, NO, mockedFiles, fakeError);

      NSError *error;
      NSArray<NSString *> *files = [mockedManager lt_globPath:kPath recursively:NO
                                                withPredicate:[NSPredicate predicateWithValue:YES]
                                                        error:&error];

      expect(files).to.beNil();
      expect(error).notTo.beNil();
    });
  });
});

context(@"storage info", ^{
  __block id mockedManager;

  beforeEach(^{
    mockedManager = OCMPartialMock(fileManager);
  });

  afterEach(^{
    mockedManager = nil;
  });

  it(@"should return correct total storage", ^{
    static const uint64_t kExpectedBytes = 123456;
    OCMStub([mockedManager attributesOfFileSystemForPath:OCMOCK_ANY error:[OCMArg anyObjectRef]]).
        andReturn(@{NSFileSystemSize: @(kExpectedBytes)});
    uint64_t totalBytes = [mockedManager lt_totalStorage];
    expect(totalBytes).to.equal(kExpectedBytes);
  });

  it(@"should return correct free storage", ^{
    static const uint64_t kExpectedBytes = 123456;
    OCMStub([mockedManager attributesOfFileSystemForPath:OCMOCK_ANY error:[OCMArg anyObjectRef]]).
        andReturn(@{NSFileSystemFreeSize: @(kExpectedBytes)});
    uint64_t freeBytes = [mockedManager lt_freeStorage];
    expect(freeBytes).to.equal(kExpectedBytes);
  });
});

context(@"common directories", ^{
  it(@"should return the documents directory", ^{
    NSString *path = [NSFileManager lt_documentsDirectory];
    expect(path).to.equal(NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                              NSUserDomainMask, YES).firstObject);
    expect(path).to.endWith(@"Documents");
  });

  it(@"should return the caches directory", ^{
    NSString *path = [NSFileManager lt_cachesDirectory];
    expect(path).to.equal(NSSearchPathForDirectoriesInDomains(NSCachesDirectory,
                                                              NSUserDomainMask, YES).firstObject);
    expect(path).to.endWith(@"Caches");
  });

  it(@"should return the application support directory", ^{
    NSString *path = [NSFileManager lt_applicationSupportDirectory];
    expect(path).to.equal(NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory,
                                                              NSUserDomainMask, YES).firstObject);
    expect(path).to.endWith(@"Application Support");
  });

  it(@"should return YES if file exists at path", ^{
    [fileManager createDirectoryAtPath:LTTemporaryPath() withIntermediateDirectories:YES
                            attributes:nil error:nil];
    [fileManager lt_writeDictionary:@{} toFile:LTTemporaryPath(@"file") error:nil];
    expect([fileManager lt_fileExistsAtPath:LTTemporaryPath(@"file")]).to.beTruthy();

    [fileManager removeItemAtPath:LTTemporaryPath() error:nil];
    expect([fileManager lt_fileExistsAtPath:LTTemporaryPath(@"file")]).to.beFalsy();
  });

  it(@"should return YES if directory exists at path", ^{
    expect([fileManager lt_directoryExistsAtPath:LTTemporaryPath()]).to.beTruthy();

    [fileManager removeItemAtPath:LTTemporaryPath() error:nil];
    expect([fileManager lt_directoryExistsAtPath:LTTemporaryPath()]).to.beFalsy();

    [fileManager createDirectoryAtPath:LTTemporaryPath() withIntermediateDirectories:YES
                            attributes:nil error:nil];
    expect([fileManager lt_directoryExistsAtPath:LTTemporaryPath()]).to.beTruthy();

    [fileManager lt_writeDictionary:@{} toFile:LTTemporaryPath(@"file") error:nil];
    expect([fileManager fileExistsAtPath:LTTemporaryPath(@"file")]).to.beTruthy();
    expect([fileManager lt_directoryExistsAtPath:LTTemporaryPath(@"file")]).to.beFalsy();

    [fileManager removeItemAtPath:LTTemporaryPath() error:nil];
    expect([fileManager lt_directoryExistsAtPath:LTTemporaryPath()]).to.beFalsy();
  });
});

context(@"size of directory", ^{
  static NSError * const kError = [NSError lt_errorWithCode:1];

  __block NSArray<NSFileAttributeKey> *keys;
  __block NSFileManager *mockedManager;
  __block NSMutableArray<NSURL *> *fileURLs;
  __block NSURL *path;
  __block NSError *error;

  beforeEach(^{
    keys = @[
      NSURLFileResourceIdentifierKey,
      NSURLFileSizeKey
    ];
    mockedManager = OCMPartialMock(fileManager);
    fileURLs = [NSMutableArray array];
    path = OCMClassMock([NSURL class]);
    OCMStub([path path]).andReturn(@"foo");
    OCMStub([mockedManager lt_directoryExistsAtPath:@"foo"]).andReturn(YES);
  });

  afterEach(^{
    [(id)mockedManager stopMocking];
    mockedManager = nil;
  });

  it(@"should return the correct size of files", ^{
    OCMStub([mockedManager enumeratorAtURL:path includingPropertiesForKeys:keys options:0
                              errorHandler:OCMOCK_ANY]).andReturn(fileURLs);

    NSURL *file1URL = OCMClassMock([NSURL class]);
    OCMStub([file1URL resourceValuesForKeys:keys error:[OCMArg anyObjectRef]]).andReturn((@{
      NSURLFileSizeKey: @2,
      NSURLFileResourceIdentifierKey: @1
    }));
    [fileURLs addObject:file1URL];

    NSURL *file2URL = OCMClassMock([NSURL class]);
    OCMStub([file2URL resourceValuesForKeys:keys error:[OCMArg anyObjectRef]]).andReturn((@{
      NSURLFileSizeKey: @1,
      NSURLFileResourceIdentifierKey: @2
    }));

    [fileURLs addObject:file2URL];

    uint64_t size = [mockedManager lt_sizeOfDirectoryAtPath:path error:&error];

    expect(error).to.beNil();
    expect(size).to.equal(3);
  });

  it(@"should not count hard links twice", ^{
    OCMStub([mockedManager enumeratorAtURL:path includingPropertiesForKeys:keys options:0
                              errorHandler:OCMOCK_ANY]).andReturn(fileURLs);
    NSURL *file1URL = OCMClassMock([NSURL class]);
    NSDictionary<NSURLResourceKey, NSNumber *> *values = @{
      NSURLFileSizeKey: @2,
      NSURLFileResourceIdentifierKey: @1
    };
    OCMStub([file1URL resourceValuesForKeys:keys error:[OCMArg anyObjectRef]]).andReturn(values);
    [fileURLs addObject:file1URL];

    values = @{
      NSURLFileSizeKey: @2,
      NSURLFileResourceIdentifierKey: @1
    };
    NSURL *file2URL = OCMClassMock([NSURL class]);
    OCMStub([file2URL resourceValuesForKeys:keys error:[OCMArg anyObjectRef]]).andReturn(values);
    [fileURLs addObject:file2URL];

    uint64_t size = [mockedManager lt_sizeOfDirectoryAtPath:path error:&error];

    expect(error).to.beNil();
    expect(size).to.equal(2);
  });

  it(@"should pass on errors from getting the enumerator and continue", ^{
    NSURL *fileURL = OCMClassMock([NSURL class]);
    NSDictionary<NSURLResourceKey, NSNumber *> *values = @{
      NSURLFileSizeKey: @5,
      NSURLFileResourceIdentifierKey: @1
    };
    OCMStub([fileURL resourceValuesForKeys:keys error:[OCMArg anyObjectRef]]).andReturn(values);
    [fileURLs addObject:fileURL];

    OCMStub([mockedManager enumeratorAtURL:path includingPropertiesForKeys:keys options:0
                              errorHandler:([OCMArg invokeBlockWithArgs:path, kError, nil])])
        .andReturn(fileURLs);

    uint64_t size = [mockedManager lt_sizeOfDirectoryAtPath:path error:&error];

    expect(error.lt_underlyingErrors.count).to.equal(1);
    expect(error.lt_underlyingErrors[0].lt_underlyingError).to.equal(kError);
    expect(error.lt_underlyingErrors[0].lt_url).to.equal(path);
    expect(size).to.equal(5);
  });

  it(@"should pass on errors from getting resource values and continue", ^{
    OCMStub([mockedManager enumeratorAtURL:path includingPropertiesForKeys:keys options:0
                              errorHandler:OCMOCK_ANY]).andReturn(fileURLs);
    NSURL *file1URL = OCMClassMock([NSURL class]);
    NSDictionary<NSURLResourceKey, NSNumber *> *values = @{
      NSURLFileSizeKey: @1,
      NSURLFileResourceIdentifierKey: @1
    };
    OCMStub([file1URL resourceValuesForKeys:keys error:[OCMArg setTo:kError]]).andReturn(values);
    [fileURLs addObject:file1URL];

    values = @{
      NSURLFileSizeKey: @2,
      NSURLFileResourceIdentifierKey: @2
    };
    NSURL *file2URL = OCMClassMock([NSURL class]);
    OCMStub([file2URL resourceValuesForKeys:keys error:[OCMArg anyObjectRef]]).andReturn(values);
    [fileURLs addObject:file2URL];

    uint64_t size = [mockedManager lt_sizeOfDirectoryAtPath:path error:&error];

    expect(error.lt_underlyingErrors.count).to.equal(1);
    expect(error.lt_underlyingErrors[0].lt_underlyingError).to.equal(kError);
    expect(error.lt_underlyingErrors[0].lt_url).to.beIdenticalTo(file1URL);
    expect(size).to.equal(2);
  });

  it(@"should populate error if file enumeration failed", ^{
    OCMStub([mockedManager enumeratorAtURL:path includingPropertiesForKeys:keys options:0
                              errorHandler:OCMOCK_ANY]);

    uint64_t size = [mockedManager lt_sizeOfDirectoryAtPath:path error:&error];

    expect(error.lt_underlyingErrors).toNot.beNil();
    expect(error).toNot.beNil();
    expect(size).to.equal(0);
  });

  it(@"should populate error if path does not lead to a directory", ^{
    NSURL *errorPath = OCMClassMock([NSURL class]);
    OCMStub([errorPath absoluteString]).andReturn(@"bar");
    OCMStub([mockedManager enumeratorAtURL:errorPath includingPropertiesForKeys:keys options:0
                              errorHandler:OCMOCK_ANY]);

    uint64_t size = [mockedManager lt_sizeOfDirectoryAtPath:errorPath error:&error];

    expect(error.lt_url).to.equal(errorPath);
    expect(size).to.equal(0);
  });
});

SpecEnd
