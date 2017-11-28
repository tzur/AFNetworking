// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Michael Kimyagarov.

#import "TINMessage.h"

#import "NSURL+TinCan.h"

SpecBegin(TINMessage)

__block TINMessage *message;

context(@"message", ^{
  __block NSString *appGroupID;
  __block NSString *sourceScheme, *targetScheme;
  __block NSDictionary *info;
  __block NSUUID *identifier;

  beforeEach(^{
    info = @{@"foo": @"bar"};
    appGroupID = @"appGroupID";
    sourceScheme = @"sourceScheme";
    targetScheme = @"targetScheme";
    identifier = [NSUUID UUID];
    message = [TINMessage messageWithAppGroupID:appGroupID sourceScheme:sourceScheme
                                   targetScheme:targetScheme identifier:identifier userInfo:info];
  });

  it(@"should initialize properly", ^{
    expect(message.appGroupID).to.equal(appGroupID);
    expect(message.sourceScheme).to.equal(sourceScheme);
    expect(message.targetScheme).to.equal(targetScheme);
    expect(message.identifier).to.equal(identifier);
    expect(message.userInfo).to.equal(info);
  });

  it(@"should archive and unarchive properly", ^{
    auto mutableData = [NSMutableData data];
    auto archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:mutableData];
    archiver.requiresSecureCoding = YES;
    [archiver encodeObject:message forKey:@"root"];
    [archiver finishEncoding];
    expect(mutableData.length).to.beGreaterThan(0);

    auto unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:mutableData];
    unarchiver.requiresSecureCoding = YES;
    TINMessage *restoredMessage = [unarchiver decodeObjectOfClass:TINMessage.class forKey:@"root"];
    expect(restoredMessage).notTo.beNil();
    expect(restoredMessage).to.equal(message);
  });

  it(@"should raise when archiving userInfo with inappropriate content", ^{
    auto message = [TINMessage messageWithAppGroupID:appGroupID sourceScheme:sourceScheme
                                        targetScheme:targetScheme identifier:identifier userInfo:@{
      @"bundle": (id<NSSecureCoding>)[NSBundle mainBundle]
    }];
    auto mutableData = [NSMutableData data];
    auto archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:mutableData];
    archiver.requiresSecureCoding = YES;

    expect(^{
      [archiver encodeObject:message forKey:@"root"];
    }).to.raise(NSInvalidUnarchiveOperationException);
  });
});

context(@"url", ^{
  beforeEach(^{
    message = [TINMessage messageWithAppGroupID:kTINTestHostAppGroupID sourceScheme:@"source"
                                   targetScheme:@"target" identifier:[NSUUID UUID] userInfo:@{}];
  });

  it(@"should return nil URL for message directory with invalid app group", ^{
    auto _Nullable url = [NSURL tin_messageDirectoryURLWithAppGroup:@"foo" scheme:@"bar"
                                                         identifier:[NSUUID UUID]];
    expect(url).to.beNil();
  });

  it(@"should return correct directory URL", ^{
    auto _Nullable expectedURL =  [NSURL tin_messageDirectoryURLWithAppGroup:message.appGroupID
                                                                      scheme:message.sourceScheme
                                                                  identifier:message.identifier];
    expect(expectedURL).notTo.beNil();
    expect(message.directoryURL).to.equal(expectedURL);
  });

  it(@"should return correct message URL", ^{
    auto _Nullable dirURL =  [NSURL tin_messageDirectoryURLWithAppGroup:message.appGroupID
                                                                 scheme:message.sourceScheme
                                                             identifier:message.identifier];
    auto _Nullable messageURL = [dirURL URLByAppendingPathComponent:kTINMessageFileName];
    expect(dirURL).notTo.beNil();
    expect(messageURL).notTo.beNil();
    expect(message.url).to.equal(messageURL);
  });
});

SpecEnd
