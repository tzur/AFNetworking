// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Michael Kimyagarov.

#import "TINMessageFactory.h"

#import <LTKit/NSFileManager+LTKit.h>
#import <LTKitTestUtils/LTTestUtils.h>
#import <LTKitTests/NSFileManagerTestUtils.h>
#import <MobileCoreServices/MobileCoreServices.h>

#import "NSErrorCodes+TinCan.h"
#import "NSURL+TinCan.h"
#import "TINMessage.h"
#import "TINMessage+UserInfo.h"

/// Returns \c UIImage of the given \c size with the given \c fillColor.
static UIImage *TINUIImage(CGSize size, UIColor *fillColor) {
  UIGraphicsBeginImageContext(size);
  CGContextRef context = UIGraphicsGetCurrentContext();

  CGContextSetFillColorWithColor(context, [fillColor CGColor]);
  CGContextFillRect(context, CGRectMake(0, 0, size.width, size.height));

  UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();

  return image;
}

/// Removes the contents of an application group directory associated with
/// \c kTINTestHostAppGroupID, if it exists.
static void TINCleanupTestHostAppGroupDirectory() {
  auto _Nullable url = [NSURL tin_appGroupDirectoryURL:kTINTestHostAppGroupID];
  if (!url) {
    return;
  }
  LTAssert(url.path, @"Failed obtainig the path of url: %@", url);

  auto fileManager = [NSFileManager defaultManager];
  NSError *error;
  for (NSString *itemName in [fileManager contentsOfDirectoryAtPath:nn(url.path) error:&error]) {
    auto _Nullable itemURL = [url URLByAppendingPathComponent:itemName];
    LTAssert(itemURL, @"Failed appending: %@ to url: %@", itemName, url);
    auto success = [fileManager removeItemAtURL:nn(itemURL) error:&error];
    LTAssert(success && !error, @"Error: %@ when removing item: %@", error, itemURL);
  }
}

SpecBegin(TINMessageFactory)

static NSString * const kTINTargetScheme = @"TargetScheme";
static NSString * const kTINSourceScheme = @"SourceScheme";

__block NSData *data;
__block NSURL *dataURL;
__block NSFileManager *fileManager;
__block TINMessageFactory *factory;

beforeEach(^{
  data = [@"foo" dataUsingEncoding:NSUTF8StringEncoding];
  dataURL = [NSURL fileURLWithPath:LTTemporaryPath(@"temp.txt")];
});

context(@"unit tests", ^{
  beforeEach(^{
    fileManager = OCMClassMock([NSFileManager class]);
    factory = [TINMessageFactory messageFactoryWithSourceScheme:kTINSourceScheme
                                                    fileManager:fileManager
                                                     appGroupID:kTINTestHostAppGroupID];
  });

  it(@"should initialize properly", ^{
    expect(factory.fileManager).to.equal(fileManager);
    expect(factory.sourceScheme).to.equal(kTINSourceScheme);
  });

  it(@"should invoke the block with correct message directory", ^{
    __block NSURL *actualMessageDirectory;
    auto _Nullable __unused message =
        [factory messageWithTargetScheme:kTINTargetScheme
                                   block:^NSDictionary *(NSURL *messageDirectory, NSError **) {
      actualMessageDirectory = messageDirectory;
      return nil;
    } error:nil];
    auto url = [NSURL tin_messageDirectoryURLWithAppGroup:kTINTestHostAppGroupID
                                                   scheme:kTINTargetScheme
                                               identifier:[NSUUID UUID]];
    auto expectedURLPrefix = [url URLByDeletingLastPathComponent];
    expect([actualMessageDirectory.path hasPrefix:nn(expectedURLPrefix.path)]).to.beTruthy();
  });

  it(@"should return nil message if block returns nil", ^{
    __block BOOL blockRun = NO;
    auto _Nullable message = [factory messageWithTargetScheme:kTINTargetScheme
                                                        block:^NSDictionary *(NSURL *, NSError **) {
      blockRun = YES;
      return nil;
    } error:nil];
    expect(blockRun).to.beTruthy();
    expect(message).to.beNil();
  });

  it(@"should not run the block if app doesn't have an entitlement to access app group", ^{
    auto factory = [TINMessageFactory messageFactoryWithSourceScheme:kTINSourceScheme
                                                         fileManager:fileManager
                                                          appGroupID:@"foo"];
    __block BOOL blockRun = NO;
    auto _Nullable __unused message = [factory messageWithTargetScheme:kTINTargetScheme
                                                                 block:^NSDictionary *(NSURL *,
                                                                                       NSError **) {
      blockRun = YES;
      return nil;
    } error:nil];
    expect(blockRun).to.beFalsy();
  });

  it(@"should init message's userInfo with block's returned dictionary", ^{
    auto _Nullable message =
        [factory messageWithTargetScheme:kTINTargetScheme
                                   block:^NSDictionary *(NSURL *, NSError **) {
      return @{@"foo": @"bar"};
    } error:nil];
    expect(message.userInfo).to.equal(@{@"foo": @"bar"});
  });

  it(@"should forward errors set within the block", ^{
    NSError *error;
    auto _Nullable message =
        [factory messageWithTargetScheme:kTINTargetScheme
                                   block:^NSDictionary *(NSURL *, NSError **blockError) {
      *blockError = [NSError lt_errorWithCode:123];
      return nil;
    } error:&error];
    expect(message).to.beNil();
    expect(error.code).to.equal(123);
  });

  it(@"should report error when failed creaing message directory", ^{
    OCMStub([fileManager createDirectoryAtURL:OCMOCK_ANY withIntermediateDirectories:YES
                                   attributes:OCMOCK_ANY
                                        error:[OCMArg anyObjectRef]]).andReturn(NO);
    NSError *error;
    auto message = [factory messageWithTargetScheme:kTINTargetScheme userInfo:@{} data:data
                                                uti:(__bridge NSString *)kUTTypePNG error:&error];
    expect(message).to.beNil();
  });

  it(@"should report error when inoked with unknown UTI", ^{
    OCMStub([fileManager createDirectoryAtURL:OCMOCK_ANY withIntermediateDirectories:YES
                                   attributes:OCMOCK_ANY
                                        error:[OCMArg anyObjectRef]]).andReturn(YES);
    NSError *error;
    auto message = [factory messageWithTargetScheme:kTINTargetScheme userInfo:@{} data:data
                                                uti:[NSUUID UUID].UUIDString error:&error];
    expect(message).to.beNil();
    expect(error.code).to.equal(TINErrorCodeInvalidUTI);
  });

  it(@"should report error when failed writing the data", ^{
    OCMStub([fileManager lt_writeData:OCMOCK_ANY toFile:OCMOCK_ANY options:NSDataWritingAtomic
                                error:[OCMArg anyObjectRef]]).andReturn(NO);
    NSError *error;
    auto message = [factory messageWithTargetScheme:kTINTargetScheme userInfo:@{} data:data
                                                uti:(__bridge NSString *)kUTTypePNG error:&error];
    expect(message).to.beNil();
    expect(error.code).to.equal(LTErrorCodeObjectCreationFailed);
  });

  it(@"should report error when failed moving message's attached file", ^{
    OCMStub([fileManager lt_fileExistsAtPath:OCMOCK_ANY]).andReturn(YES);
    OCMStub([fileManager moveItemAtURL:OCMOCK_ANY toURL:OCMOCK_ANY error:[OCMArg anyObjectRef]])
        .andReturn(NO);

    NSError *error;
    auto message = [factory messageWithTargetScheme:kTINTargetScheme userInfo:@{} fileURL:dataURL
                                          operation:$(TINMessageFileOperationMove) error:&error];
    expect(message).to.beNil();
    expect(error.code).to.equal(LTErrorCodeObjectCreationFailed);
  });

  it(@"should report error when failed copying message's attached file", ^{
    OCMStub([fileManager lt_fileExistsAtPath:OCMOCK_ANY]).andReturn(YES);
    OCMStub([fileManager copyItemAtURL:OCMOCK_ANY toURL:OCMOCK_ANY error:[OCMArg anyObjectRef]])
        .andReturn(NO);

    NSError *error;
    auto message = [factory messageWithTargetScheme:kTINTargetScheme userInfo:@{} fileURL:dataURL
                                          operation:$(TINMessageFileOperationCopy) error:&error];
    expect(message).to.beNil();
    expect(error.code).to.equal(LTErrorCodeObjectCreationFailed);
  });
});

context(@"integration tests", ^{
  beforeEach(^{
    fileManager = [NSFileManager defaultManager];
    factory = [TINMessageFactory messageFactoryWithSourceScheme:kTINSourceScheme
                                                    fileManager:fileManager
                                                     appGroupID:kTINTestHostAppGroupID];
  });

  afterEach(^{
    TINCleanupTestHostAppGroupDirectory();
  });

  it(@"should create message with data", ^{
    NSError *error;
    auto _Nullable message = [factory messageWithTargetScheme:kTINTargetScheme userInfo:@{}
                              data:data uti:(__bridge NSString *)kUTTypePNG error:&error];
    expect(error).to.beNil();
    expect([fileManager lt_fileExistsAtPath:nn(message.fileURLs.firstObject.path)]).to.beTruthy();

    auto restoredData = [NSData dataWithContentsOfURL:nn(message.fileURLs.firstObject)];
    expect(restoredData).to.equal(data);
  });

  it(@"should create message with UIImage", ^{
    auto image = TINUIImage(CGSizeMake(3, 3), [UIColor purpleColor]);
    NSError *error;
    auto _Nullable message = [factory messageWithTargetScheme:kTINTargetScheme userInfo:@{}
                                                        image:image error:&error];
    expect(message).notTo.beNil();
    expect(error).to.beNil();

    auto _Nullable imageData = [NSData dataWithContentsOfURL:nn(message.fileURLs.firstObject)];
    expect(imageData).notTo.beNil();

    auto _Nullable restoredImage = [UIImage imageWithData:nn(imageData)];
    expect(restoredImage.size).to.equal(CGSizeMake(3, 3));
  });

  it(@"should fail creating message with malformed image", ^{
    auto badImage = [[UIImage alloc] init];
    NSError *error;
    auto _Nullable message = [factory messageWithTargetScheme:kTINTargetScheme userInfo:@{}
                                                        image:badImage error:&error];
    expect(message).to.beNil();
    expect(error.code).to.equal(LTErrorCodeObjectCreationFailed);
  });

  it(@"should create message with fileURL with copy file operation", ^{
    [data writeToURL:dataURL atomically:YES];

    NSError *error;
    auto _Nullable message = [factory messageWithTargetScheme:kTINTargetScheme userInfo:@{}
                              fileURL:dataURL operation:$(TINMessageFileOperationCopy)
                              error:&error];

    expect(message.fileNames).notTo.beNil();
    expect(message.fileURLs).notTo.beNil();
    expect(error).to.beNil();

    auto restoredData = [NSData dataWithContentsOfURL:nn(message.fileURLs.firstObject)];
    expect(restoredData).to.equal(data);
  });

  it(@"should fail creating message with non existing fileURL", ^{
    auto nonExsitingURL = [NSURL fileURLWithPath:[NSUUID UUID].UUIDString];
    NSError *error;
    auto _Nullable message = [factory messageWithTargetScheme:kTINTargetScheme userInfo:@{}
                              fileURL:nonExsitingURL operation:$(TINMessageFileOperationCopy)
                              error:&error];
    expect(message).to.beNil();
    expect(error.code).to.equal(LTErrorCodeFileNotFound);
  });

  it(@"should preserve the fileURL path extension", ^{
    [data writeToURL:dataURL atomically:YES];

    NSError *error;
    auto _Nullable message = [factory messageWithTargetScheme:kTINTargetScheme userInfo:@{}
                              fileURL:dataURL operation:$(TINMessageFileOperationCopy)
                              error:&error];
    expect(message.fileNames).toNot.beNil();
    expect(message.fileNames.firstObject.pathExtension).to.equal(dataURL.pathExtension);
  });

  it(@"should create message with fileURL with move file operation", ^{
    [data writeToURL:dataURL atomically:YES];

    NSError *error;
    auto _Nullable message = [factory messageWithTargetScheme:kTINTargetScheme userInfo:@{}
                              fileURL:dataURL operation:$(TINMessageFileOperationMove)
                              error:&error];

    expect(message.fileNames).notTo.beNil();
    expect(error).to.beNil();

    auto restoredData = [NSData dataWithContentsOfURL:nn(message.fileURLs.firstObject)];
    expect(restoredData).to.equal(data);

    expect([fileManager lt_fileExistsAtPath:nn(dataURL.path)]).to.beFalsy();
  });
});

SpecEnd
