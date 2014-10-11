// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTFileManager.h"

#import "LTImage.h"

LTSpecBegin(LTFileManager)

__block id nsFileManager;
__block LTFileManager *fileManager;

beforeEach(^{
  nsFileManager = LTMockClass([NSFileManager class]);
  fileManager = [[LTFileManager alloc] init];
});

it(@"should write data", ^{
  id data = [OCMockObject mockForClass:[NSData class]];

  NSString *file = @"MyFile";
  NSDataWritingOptions options = NSDataWritingAtomic;
  NSError *error;

  [[[data expect] andReturnValue:@YES] writeToFile:file options:options
                                             error:(NSError *__autoreleasing *)[OCMArg anyPointer]];

  BOOL succeeded = [fileManager writeData:data toFile:file options:options error:&error];
  expect(succeeded).to.beTruthy();
  expect(error).to.beNil();

  OCMVerifyAll(data);
});

it(@"should read data from file", ^{
  NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"Gray" ofType:@"jpg"];

  NSError *error;
  NSData *data = [fileManager dataWithContentsOfFile:path options:0 error:&error];

  expect(error).to.beNil();

  NSData *file = [NSData dataWithContentsOfFile:path];
  expect(data).to.equal(file);
});

it(@"should create directory", ^{
  static NSString * const kDirectory = @"/foo/bar";

  NSError *error;

  OCMExpect([nsFileManager createDirectoryAtPath:kDirectory
                     withIntermediateDirectories:YES
                                      attributes:OCMOCK_ANY
                                           error:[OCMArg anyObjectRef]]).andReturn(YES);

  BOOL result = [fileManager createDirectoryAtPath:kDirectory withIntermediateDirectories:YES
                                             error:&error];

  expect(result).to.beTruthy();
  OCMVerifyAll(nsFileManager);
});

LTSpecEnd
