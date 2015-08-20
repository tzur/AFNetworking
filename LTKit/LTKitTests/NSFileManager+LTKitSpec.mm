// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "NSFileManager+LTKit.h"

LTSpecBegin(NSFileManager_LTKit)

__block id fileManager;

beforeEach(^{
  fileManager = [NSFileManager defaultManager];
});

it(@"should write dictionary", ^{
  NSString *path = @"MyFile";
  id dictionary = OCMClassMock([NSDictionary class]);
  [fileManager lt_writeDictionary:dictionary toFile:path];
  OCMVerify([(NSDictionary *)dictionary writeToFile:path atomically:YES]);
});

it(@"should read dictionary", ^{
  NSString *path = @"MyFile";
  NSDictionary *dictionary = @{@"a": @"b"};
  id mock = OCMClassMock([NSDictionary class]);
  OCMExpect([mock dictionaryWithContentsOfFile:path]).andReturn(dictionary);
  expect([fileManager lt_dictionaryWithContentsOfFile:path]).to.equal(dictionary);
  OCMVerifyAll(mock);
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

LTSpecEnd
