// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTMMInputFile.h"

#import <sys/mman.h>

SpecBegin(LTMMInputFile)

context(@"valid file", ^{
  __block NSError *error;
  __block LTMMInputFile *inputFile;
  __block NSString *path;

  beforeEach(^{
    path = [[NSBundle bundleForClass:[self class]] executablePath];
    inputFile = [[LTMMInputFile alloc] initWithPath:path error:&error];
  });

  it(@"should initialize correctly", ^{
    expect(inputFile).notTo.beNil();
    expect(error).to.beNil();
    expect(inputFile.path).to.equal(path);
  });

  it(@"should have valid size and data pointer", ^{
    NSData *fileData = [NSData dataWithContentsOfFile:path];
    expect(inputFile.size).to.equal(fileData.length);

    NSData *mappedData = [NSData dataWithBytesNoCopy:(void *)inputFile.data length:inputFile.size
                                        freeWhenDone:NO];
    expect(fileData).to.equal(mappedData);
  });

  it(@"should unmap file from memory", ^{
    void *data;

    @autoreleasepool {
      LTMMInputFile *inputFile = [[LTMMInputFile alloc] initWithPath:path error:&error];
      data = (void *)inputFile.data;
    }

    // Try to sync the first page of the memory mapped file, which should fail.
    expect(msync(data, 1, 0)).to.equal(-1);
    expect(errno).to.equal(ENOMEM);
  });

  it(@"should read from the same file when it is mapped more than once", ^{
    NSError *otherError;
    LTMMInputFile *otherInputFile = [[LTMMInputFile alloc] initWithPath:path error:&otherError];

    expect(otherError).to.beNil();
    expect(otherInputFile).notTo.beNil();

    expect(inputFile.size).to.equal(otherInputFile.size);
    expect(inputFile.path).to.equal(otherInputFile.path);

    expect(memcmp(inputFile.data, otherInputFile.data, inputFile.size)).to.equal(0);
  });
});

context(@"invalid file", ^{
  it(@"should error when trying to open an invalid file", ^{
    NSError *error;
    LTMMInputFile *inputFile = [[LTMMInputFile alloc] initWithPath:@"/baz/bar" error:&error];

    expect(inputFile).to.beNil();
    expect(error).notTo.beNil();
  });
});

SpecEnd
