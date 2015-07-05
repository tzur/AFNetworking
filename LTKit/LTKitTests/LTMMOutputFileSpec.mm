// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTMMOutputFile.h"

#import "LTMMInputFile.h"

LTSpecBegin(LTMMOutputFile)

__block NSError *error;
__block LTMMOutputFile *outputFile;
__block NSString *path;

static const size_t kFileSize = 1337;
static const mode_t kFileMode = 0644;

context(@"valid file", ^{
  beforeEach(^{
    LTCreateTemporaryDirectory();
    path = LTTemporaryPath(@"LTMMOutputFile.test");

    outputFile = [[LTMMOutputFile alloc] initWithPath:path size:kFileSize mode:kFileMode
                                                error:&error];
  });

  afterEach(^{
    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
  });

  it(@"should initialize correctly", ^{
    expect(outputFile).notTo.beNil();
    expect(error).to.beNil();
    expect(outputFile.path).to.equal(path);
  });

  it(@"should have valid size and data pointer", ^{
    expect(outputFile.size).to.equal(kFileSize);
    expect(outputFile.finalSize).to.equal(kFileSize);
    expect(outputFile.data).notTo.beNil();
  });

  it(@"should create file with valid size and mode", ^{
    outputFile = nil;

    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:path
                                                                                error:nil];
    expect(attributes.fileSize).to.equal(kFileSize);
    expect(attributes.filePosixPermissions).to.equal(kFileMode);
  });

  it(@"should write contents to file", ^{
    @autoreleasepool {
      LTMMOutputFile *outputFile = [[LTMMOutputFile alloc] initWithPath:path size:kFileSize
                                                                   mode:kFileMode error:&error];
      memset(outputFile.data, 7, kFileSize);
    }

    NSData *contents = [NSData dataWithContentsOfFile:path];
    NSMutableData *expectedContents = [[NSMutableData alloc] initWithLength:kFileSize];
    memset(expectedContents.mutableBytes, 7, kFileSize);

    expect(contents.length).to.equal(kFileSize);
    expect(contents).to.equal(expectedContents);
  });

  it(@"should truncate file to given size", ^{
    static const size_t kFinalSize = 337;

    @autoreleasepool {
      LTMMOutputFile *outputFile = [[LTMMOutputFile alloc] initWithPath:path size:kFileSize
                                                                   mode:kFileMode error:&error];
      memset(outputFile.data, 7, kFileSize);
      outputFile.finalSize = kFinalSize;
    }

    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:path
                                                                                error:nil];
    expect(attributes.fileSize).to.equal(kFinalSize);

    NSData *contents = [NSData dataWithContentsOfFile:path];
    NSMutableData *expectedContents = [[NSMutableData alloc] initWithLength:kFinalSize];
    memset(expectedContents.mutableBytes, 7, kFinalSize);
    expect(contents).to.equal(expectedContents);
  });

  it(@"should share changes across two output mapped files that map the same file", ^{
    NSError *otherError;
    LTMMOutputFile *otherOutputFile = [[LTMMOutputFile alloc] initWithPath:path
                                                                      size:kFileSize
                                                                      mode:kFileMode
                                                                     error:&otherError];

    expect(otherOutputFile).notTo.beNil();
    expect(otherError).to.beNil();
    expect(otherOutputFile.path).to.equal(outputFile.path);

    std::vector<char> buffer(kFileSize);
    std::fill(buffer.begin(), buffer.end(), 7);

    memcpy(outputFile.data, buffer.data(), buffer.size());
    expect(memcmp(otherOutputFile.data, buffer.data(), buffer.size())).to.equal(0);
  });

  it(@"should not share changes across input and output mapped file that map the same file", ^{
    NSError *otherError;
    LTMMInputFile *inputFile = [[LTMMInputFile alloc] initWithPath:path error:&otherError];

    expect(inputFile).notTo.beNil();
    expect(otherError).to.beNil();
    expect(inputFile.path).to.equal(outputFile.path);

    std::vector<char> buffer(kFileSize);
    std::fill(buffer.begin(), buffer.end(), 7);

    memcpy(outputFile.data, buffer.data(), buffer.size());
    expect(memcmp(inputFile.data, buffer.data(), buffer.size())).notTo.equal(0);
  });
});

context(@"invalid file", ^{
  it(@"should error when trying to open an invalid file", ^{
    NSError *error;
    outputFile = [[LTMMOutputFile alloc] initWithPath:@"/baz/bar" size:kFileSize mode:kFileMode
                                                error:&error];

    expect(outputFile).to.beNil();
    expect(error).notTo.beNil();
  });
});

LTSpecEnd
