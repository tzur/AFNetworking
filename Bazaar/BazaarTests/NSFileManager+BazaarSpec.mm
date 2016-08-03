// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "NSFileManager+Bazaar.h"

#import <LTKit/NSArray+Functional.h>

#import "NSErrorCodes+Bazaar.h"

/// Fake directory enumerator used for testing \c NSFileManager+Bazaar.
@interface BZRFakeDirectoryEnumerator : NSDirectoryEnumerator

/// All objects returned by this enumerator.
@property (readonly, nonatomic) NSArray<NSString *> *allObjects;

/// Index of the next item to be returned by the enumerator.
@property (nonatomic) NSUInteger nextIndex;

@end

@implementation BZRFakeDirectoryEnumerator

- (instancetype)initWithItems:(NSArray<NSString *> *)items {
  if (self = [super init]) {
    _allObjects = [items copy];
  }
  return self;
}

- (NSString *)nextObject {
  NSUInteger currentIndex = self.nextIndex;
  if (currentIndex >= self.allObjects.count) {
    return nil;
  }

  self.nextIndex = self.nextIndex + 1;
  return self.allObjects[currentIndex];
}

@end

SpecBegin(NSFileManager_Bazaar)

__block id fileManager;

beforeEach(^{
  fileManager = OCMPartialMock([[NSFileManager alloc] init]);
});

context(@"files attributes retrieval", ^{
  __block NSArray<NSString *> *filePaths;
  __block NSString *nonExistingFilePath;
  __block NSDictionary<NSString *, NSDictionary *> *fileAttributes;

  beforeEach(^{
    fileAttributes = @{
      @"foo": @{NSFileSize: @13, NSFileType: NSFileTypeRegular},
      @"bar": @{NSFileSize: @37, NSFileType: NSFileTypeRegular},
      @"baz": @{NSFileType: NSFileTypeDirectory}
    };
    filePaths = [fileAttributes.allKeys lt_filter:^BOOL(NSString *fileName) {
      return [fileAttributes[fileName][NSFileType] isEqualToString:NSFileTypeRegular];
    }];

    for (NSString *path in fileAttributes.allKeys) {
      OCMStub([fileManager attributesOfItemAtPath:path error:[OCMArg anyObjectRef]])
          .andReturn(fileAttributes[path]);
    }

    nonExistingFilePath = @"/foo/bar/baz";
    NSError *nonExistingFileError = OCMClassMock([NSError class]);
    OCMStub([fileManager attributesOfItemAtPath:nonExistingFilePath
                                          error:[OCMArg setTo:nonExistingFileError]]);
  });

  it(@"should send no values if given empty array of files", ^{
    RACSignal *signal = [fileManager bzr_retrieveFilesSizes:@[]];
    LLSignalTestRecorder *recorder = [signal testRecorder];

    expect(recorder).will.complete();
    expect(recorder).to.sendValuesWithCount(0);
  });

  it(@"should send the file sizes for all the specified files", ^{
    NSArray<RACTuple *> *expectedValues = [filePaths lt_map:^RACTuple *(NSString *filePath) {
      NSNumber *fileSize = fileAttributes[filePath][NSFileSize];
      return [RACTuple tupleWithObjects:filePath, fileSize, nil];
    }];
    RACSignal *signal = [fileManager bzr_retrieveFilesSizes:filePaths];
    LLSignalTestRecorder *recorder = [signal testRecorder];

    expect(recorder).will.complete();
    expect(recorder).to.sendValues(expectedValues);
  });

  it(@"should err if failed to retreive the attrbiutes of one of the files", ^{
    NSArray<NSString *> *failingFilePaths = [filePaths arrayByAddingObject:nonExistingFilePath];
    RACSignal *signal = [fileManager bzr_retrieveFilesSizes:failingFilePaths];

    expect(signal).will.matchError(^BOOL(NSError *error) {
      return error.lt_isLTDomain && error.code == BZRErrorCodeFileAttributesRetrievalFailed &&
          [error.lt_path isEqualToString:nonExistingFilePath] && error.lt_underlyingError != nil;
    });
  });

  it(@"should err if one of the files specified is a directory", ^{
    NSArray<NSString *> *failingFilePaths = [filePaths arrayByAddingObject:@"baz"];
    RACSignal *signal = [fileManager bzr_retrieveFilesSizes:failingFilePaths];

    expect(signal).will.matchError(^BOOL(NSError *error) {
      return error.lt_isLTDomain && error.code == BZRErrorCodeFileAttributesRetrievalFailed &&
          [error.lt_path isEqualToString:@"baz"];
    });
  });

  it(@"should not deliver values on the main thread", ^{
    RACSignal *signal = [fileManager bzr_retrieveFilesSizes:filePaths];
    expect(signal).willNot.deliverValuesOnMainThread();
  });
});

context(@"file deletion", ^{
  __block NSString *filePath;
  __block NSString *directoryPath;
  __block NSString *nonExistingFilePath;

  beforeEach(^{
    filePath = @"foo";
    directoryPath = @"bar";
    nonExistingFilePath = @"baz";

    OCMStub([fileManager fileExistsAtPath:filePath
                              isDirectory:(BOOL *)[OCMArg setToValue:@NO]]).andReturn(YES);
    OCMStub([fileManager fileExistsAtPath:directoryPath
                              isDirectory:(BOOL *)[OCMArg setToValue:@YES]]).andReturn(YES);
    OCMStub([fileManager fileExistsAtPath:nonExistingFilePath
                              isDirectory:(BOOL *)[OCMArg setToValue:@NO]]).andReturn(NO);
  });

  it(@"should not initiate deletion if the item at the specified does not exist", ^{
    OCMReject([fileManager removeItemAtPath:nonExistingFilePath error:[OCMArg anyObjectRef]]);
    RACSignal *signal = [fileManager bzr_deleteItemAtPathIfExists:nonExistingFilePath];

    expect(signal).will.complete();
  });

  it(@"should delete the item if it is a file", ^{
    OCMExpect([fileManager removeItemAtPath:filePath error:[OCMArg anyObjectRef]])
        .andReturn(YES);
    RACSignal *signal = [fileManager bzr_deleteItemAtPathIfExists:filePath];

    expect(signal).will.complete();
    OCMVerifyAll(fileManager);
  });

  it(@"should delete the item if it is a directory", ^{
    OCMExpect([fileManager removeItemAtPath:directoryPath error:[OCMArg anyObjectRef]])
        .andReturn(YES);
    RACSignal *signal = [fileManager bzr_deleteItemAtPathIfExists:directoryPath];

    expect(signal).will.complete();
  });

  it(@"should err if the deletion failed", ^{
    NSError *underlyingError = [NSError lt_errorWithCode:1337];
    OCMStub([fileManager removeItemAtPath:filePath error:[OCMArg setTo:underlyingError]])
        .andReturn(NO);
    RACSignal *signal = [fileManager bzr_deleteItemAtPathIfExists:filePath];

    expect(signal).will.matchError(^BOOL(NSError *error) {
      return error.lt_isLTDomain && error.code == LTErrorCodeFileRemovalFailed &&
          [error.lt_underlyingError isEqual:underlyingError];
    });
  });

  it(@"should not deliver values on the main thread", ^{
    RACSignal *signal = [fileManager bzr_deleteItemAtPathIfExists:filePath];
    expect(signal).willNot.deliverValuesOnMainThread();
  });
});

context(@"directory enumeration", ^{
  NSString * const kDirectoryPath = @"foo";
  NSString * const kSubDirectory = @"bar";
  NSString * const kNonExistingDirectory = @"baz";
  NSArray<NSString *> * const kDirectoryContent = @[
    @"foo",
    @"bar",
    @"bar/foo",
    @"bar/bar",
    @"bar/baz",
    @"baz"
  ];

  __block id directoryEnumerator;

  beforeEach(^{
    directoryEnumerator = [[BZRFakeDirectoryEnumerator alloc] initWithItems:kDirectoryContent];
    OCMStub([fileManager enumeratorAtPath:kDirectoryPath]).andReturn(directoryEnumerator);

    OCMStub([fileManager fileExistsAtPath:kDirectoryPath
                              isDirectory:(BOOL *)[OCMArg setToValue:@YES]]).andReturn(YES);
    for (NSString *item in kDirectoryContent) {
      NSString *itemPath = [kDirectoryPath stringByAppendingPathComponent:item];
      BOOL isDirectory = [item isEqualToString:kSubDirectory];
      OCMStub([fileManager fileExistsAtPath:itemPath
                                isDirectory:(BOOL *)[OCMArg setToValue:@(isDirectory)]])
          .andReturn(YES);
    }
    OCMStub([fileManager fileExistsAtPath:kNonExistingDirectory
                              isDirectory:(BOOL *)[OCMArg setToValue:@NO]]).andReturn(NO);
  });

  it(@"should err if the directory path does not exist", ^{
    RACSignal *signal = [fileManager bzr_enumerateDirectoryAtPath:kNonExistingDirectory];

    expect(signal).will.matchError(^BOOL(NSError *error) {
      return error.lt_isLTDomain && error.code == BZRErrorCodeDirectoryEnumrationFailed;
    });
  });

  it(@"should err if the path specified exists but it is not a directory", ^{
    RACSignal *signal = [fileManager bzr_enumerateDirectoryAtPath:@"foo/foo"];

    expect(signal).will.matchError(^BOOL(NSError *error) {
      return error.lt_isLTDomain && error.code == BZRErrorCodeDirectoryEnumrationFailed;
    });
  });

  it(@"should deliver the content of the directory excluding sub directories", ^{
    NSArray<RACTuple *> *expectedValues =
        [[kDirectoryContent mtl_arrayByRemovingObject:kSubDirectory]
         lt_map:^RACTuple *(NSString *item) {
           return [RACTuple tupleWithObjects:kDirectoryPath, item, nil];
         }];

    RACSignal *signal = [fileManager bzr_enumerateDirectoryAtPath:kDirectoryPath];
    LLSignalTestRecorder *recorder = [signal testRecorder];

    expect(recorder).will.complete();
    expect(recorder).to.sendValues(expectedValues);
  });

  it(@"should not deliver values on the main thread", ^{
    RACSignal *signal = [fileManager bzr_enumerateDirectoryAtPath:kDirectoryPath];
    expect(signal).willNot.deliverValuesOnMainThread();
  });
});

SpecEnd
