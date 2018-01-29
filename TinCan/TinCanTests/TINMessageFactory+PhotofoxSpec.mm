// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Shachar Langbeheim.

#import "TINMessageFactory+Photofox.h"

#import <LTKitTestUtils/LTTestUtils.h>
#import <MobileCoreServices/MobileCoreServices.h>

#import "NSErrorCodes+TinCan.h"
#import "TINMessage+UserInfo.h"

SpecBegin(TINMessageFactory_Photofox)

static NSString * const kTINSourceScheme = @"SourceScheme";

__block NSData *data;
__block NSURL *dataURL;
__block TINMessageFactory *factory;

beforeEach(^{
  data = [@"foo" dataUsingEncoding:NSUTF8StringEncoding];
  dataURL = [NSURL fileURLWithPath:LTTemporaryPath(@"temp.txt")];
  auto fileManager = [NSFileManager defaultManager];
  factory = [TINMessageFactory messageFactoryWithSourceScheme:kTINSourceScheme
                                                  fileManager:fileManager
                                                   appGroupID:kTINTestHostAppGroupID];
});

afterEach(^{
  TINCleanupTestHostAppGroupDirectory();
});

it(@"should create image request message for photofox", ^{
  auto context = @{@"hi": @"ho"};
  auto appDisplayName = @"foo";
  NSError *error;
  auto _Nullable message =
      [factory en_imageEditingRequestWithData:data uti:(__bridge NSString *)kUTTypePNG
                                  context:context appDisplayName:appDisplayName error:&error];

  expect(message).notTo.beNil();
  expect(message.targetScheme).to.equal(kTINPhotofoxScheme);
  expect(message.type).to.equal($(TINMessageTypeRequest));
  expect(message.action).to.equal(kTINPhotofoxImageEditAction);
  expect(message.en_appDisplayName).to.equal(appDisplayName);
  expect(message.context).to.equal(context);

  expect(error).to.beNil();

  auto restoredData = [NSData dataWithContentsOfURL:nn(message.fileURLs.firstObject)];
  expect(restoredData).to.equal(data);
});

it(@"should report error when inoked with unknown UTI", ^{
  NSError *error;
  auto _Nullable message =
  [factory en_imageEditingRequestWithData:data uti:[NSUUID UUID].UUIDString context:@{}
                           appDisplayName:@"foo" error:&error];
  expect(message).to.beNil();
  expect(error.code).to.equal(TINErrorCodeInvalidUTI);
});

SpecEnd
