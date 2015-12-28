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

  __block id mock;
  __block NSError *error;
  __block NSDictionary *validDictionary;
  __block NSDictionary *invalidDictionary;

  beforeEach(^{
    mock = OCMPartialMock(fileManager);

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
    mock = nil;
    error = nil;
  });

  it(@"should write a dictionary containing a valid plist", ^{
    OCMExpect([mock lt_writeData:[OCMArg checkWithBlock:^BOOL(NSData *data) {
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
    OCMVerifyAll(mock);
  });

  it(@"should return no and populate error when trying to write an invalid dictionary", ^{
    [[mock reject] lt_writeData:[OCMArg any] toFile:kPath
                        options:NSDataWritingAtomic error:[OCMArg anyObjectRef]];

    BOOL success = [fileManager lt_writeDictionary:invalidDictionary toFile:kPath error:&error];

    expect(success).to.beFalsy();
    expect(error).notTo.beNil();
    OCMVerifyAll(mock);
  });

  it(@"should return no and populate error if failed to write a valid dictionary", ^{
    OCMExpect([mock lt_writeData:[OCMArg any] toFile:kPath options:NSDataWritingAtomic
                           error:[OCMArg setTo:kError]]).andReturn(NO);

    BOOL success = [fileManager lt_writeDictionary:validDictionary toFile:kPath error:&error];

    expect(success).to.beFalsy();
    expect(error).notTo.beNil();
    expect(error.lt_underlyingError).to.beIdenticalTo(kError);
    OCMVerifyAll(mock);
  });

  it(@"should read a file containing a valid plist", ^{
    __block NSData *serializedData;
    OCMExpect([mock lt_writeData:[OCMArg checkWithBlock:^BOOL(NSData *data) {
      serializedData = data;
      return YES;
    }] toFile:kPath options:NSDataWritingAtomic error:[OCMArg anyObjectRef]]).andReturn(YES);
    [fileManager lt_writeDictionary:validDictionary toFile:kPath error:&error];
    expect(serializedData).notTo.beNil();
    OCMVerifyAll(mock);

    OCMExpect([mock lt_dataWithContentsOfFile:kPath options:NSDataReadingUncached
                                        error:[OCMArg anyObjectRef]]).andReturn(serializedData);

    NSDictionary *dictionary = [fileManager lt_dictionaryWithContentsOfFile:kPath error:&error];

    expect(dictionary).to.equal(validDictionary);
    expect(error).to.beNil();
    OCMVerifyAll(mock);
  });

  it(@"should return nil and populate error if failed to read the file at the given path", ^{
    OCMExpect([mock lt_dataWithContentsOfFile:kPath options:NSDataReadingUncached
                                        error:[OCMArg setTo:kError]]);

    NSDictionary *dictionary = [fileManager lt_dictionaryWithContentsOfFile:kPath error:&error];

    expect(dictionary).to.beNil();
    expect(error).notTo.beNil();
    expect(error.lt_underlyingError).to.beIdenticalTo(kError);
    OCMVerifyAll(mock);
  });

  it(@"should return nil and populate error if failed to deserialize the file into a dictionary", ^{
    NSData *invalidData = [@"<xml><a></b></xml>" dataUsingEncoding:NSUTF8StringEncoding];
    OCMExpect([mock lt_dataWithContentsOfFile:kPath options:NSDataReadingUncached
                                      error:[OCMArg anyObjectRef]]).andReturn(invalidData);

    NSDictionary *dictionary = [fileManager lt_dictionaryWithContentsOfFile:kPath error:&error];

    expect(dictionary).to.beNil();
    expect(error).notTo.beNil();
    OCMVerifyAll(mock);
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
  NSString *path = [[NSBundle bundleForClass:[self class]] executablePath];

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
});

SpecEnd
