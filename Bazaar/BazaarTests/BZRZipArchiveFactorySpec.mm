// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "BZRZipArchiveFactory.h"

#import "BZRZipArchiver.h"
#import "BZRZipUnarchiver.h"

SpecBegin(BZRZipArchiveFactory)

__block BZRZipArchiveFactory *factory;

beforeEach(^{
  factory = [[BZRZipArchiveFactory alloc] init];
});

it(@"should return a zip archiver", ^{
  NSString *archivePath = @"/foo.zip";
  NSString *password = @"foobar";
  id archiverMock = OCMClassMock([BZRZipArchiver class]);
  OCMExpect([archiverMock zipArchiverWithPath:archivePath password:password
                                        error:[OCMArg anyObjectRef]]).andReturn(archiverMock);

  NSError *error;
  BZRZipArchiver *archiver = [factory zipArchiverAtPath:archivePath withPassword:password
                                                  error:&error];

  expect(error).to.beNil();
  expect(archiver).toNot.beNil();
  OCMVerifyAll(archiverMock);
});

it(@"should return nil and propagate error", ^{
  NSString *archivePath = @"/foo.zip";
  NSString *password = @"foobar";
  NSError *error = [NSError lt_errorWithCode:1337];
  id archiverMock = OCMClassMock([BZRZipArchiver class]);
  OCMStub([archiverMock zipArchiverWithPath:archivePath password:password
                                      error:[OCMArg setTo:error]]);

  NSError *reportedError;
  BZRZipArchiver *archiver = [factory zipArchiverAtPath:archivePath withPassword:password
                                                  error:&reportedError];

  expect(reportedError).to.equal(error);
  expect(archiver).to.beNil();
});

it(@"should create an archive object for unarchiving", ^{
  NSString *archivePath = @"/foo.zip";
  NSString *password = @"foobar";
  NSError *error;
  BZRZipUnarchiver *unarchiver = [factory zipUnarchiverAtPath:archivePath withPassword:password
                                                        error:&error];

  expect(error).to.beNil();
  expect(unarchiver).toNot.beNil();
  expect(unarchiver.path).to.equal(archivePath);
  expect(unarchiver.password).to.equal(password);
});

SpecEnd
