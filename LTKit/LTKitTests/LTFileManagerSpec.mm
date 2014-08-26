// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTFileManager.h"

#import "LTImage.h"

SpecBegin(LTFileManager)

it(@"should write data", ^{
  id data = [OCMockObject mockForClass:[NSData class]];

  NSString *file = @"MyFile";
  NSDataWritingOptions options = NSDataWritingAtomic;
  NSError *error;

  [[[data expect] andReturnValue:@YES] writeToFile:file options:options
                                             error:(NSError *__autoreleasing *)[OCMArg anyPointer]];

  BOOL succeeded = [[LTFileManager sharedManager] writeData:data toFile:file
                                                    options:options error:&error];
  expect(succeeded).to.beTruthy();
  expect(error).to.beNil();

  [data verify];
});

it(@"should read data from file", ^{
  NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"Gray" ofType:@"jpg"];

  NSError *error;
  NSData *data = [[LTFileManager sharedManager] dataWithContentsOfFile:path options:0 error:&error];

  expect(error).to.beNil();

  NSData *file = [NSData dataWithContentsOfFile:path];
  expect(data).to.equal(file);
});

it(@"should read image from file", ^{
  NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"Gray" ofType:@"jpg"];

  UIImage *image = [[LTFileManager sharedManager] imageWithContentsOfFile:path];
  expect(image).toNot.beNil();

  LTImage *ltImage = [[LTImage alloc] initWithImage:image];
  LTImage *expectedImage = [[LTImage alloc] initWithImage:[UIImage imageWithContentsOfFile:path]];
  expect($(ltImage.mat)).to.equalMat($(expectedImage.mat));
});

SpecEnd
