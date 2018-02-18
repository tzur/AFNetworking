// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

#import "INTDeviceInfoObserver.h"

#import <LTKitTestUtils/LTDataHelpers.h>
#import <LTKitTestUtils/LTFakeKeyValuePersistentStorage.h>

#import "INTDeviceInfo.h"
#import "INTFakeDeviceInfoSource.h"

@interface INTFakeDeviceInfoObserverDelegate : NSObject <INTDeviceInfoObserverDelegate>
@property (strong, nonatomic) INTDeviceInfoObserver *reportingDeviceInfoObserver;
@property (strong, nonatomic) INTDeviceInfo *reportedDeviceInfo;
@property (strong, nonatomic) NSUUID *reportedDeviceInfoRevisionID;
@property (nonatomic) BOOL reportedIsNewRevision;
@property (strong, nonatomic, nullable) NSData *reportedDeviceToken;
@property (strong, nonatomic, nullable) NSNumber *reportedAppRunCount;
@end

@implementation INTFakeDeviceInfoObserverDelegate

- (void)deviceInfoObserver:(INTDeviceInfoObserver *)deviceInfoObserver
          loadedDeviceInfo:(INTDeviceInfo *)deviceInfo
      deviceInfoRevisionID:(NSUUID *)deviceInfoRevisionID
             isNewRevision:(BOOL)isNewRevision {
  self.reportingDeviceInfoObserver = deviceInfoObserver;
  self.reportedDeviceInfo = deviceInfo;
  self.reportedDeviceInfoRevisionID = deviceInfoRevisionID;
  self.reportedIsNewRevision = isNewRevision;
}

- (void)deviceTokenDidChange:(nullable NSData *)deviceToken {
  self.reportedDeviceToken = deviceToken;
}

- (void)appRunCountUpdated:(NSNumber *)appRunCount {
  self.reportedAppRunCount = appRunCount;
}

@end

INTDeviceInfo *INTFakeDeviceInfo() {
  return [[INTDeviceInfo alloc] initWithIdentifierForVendor:[NSUUID UUID]
                                              advertisingID:[NSUUID UUID]
                                 advertisingTrackingEnabled:YES deviceKind:@"foo" iosVersion:@"foo"
                                                 appVersion:@"foo" appVersionShort:@"foo"
                                                   timeZone:@"foo" country:@"foo"
                                          preferredLanguage:@"foo" currentAppLanguage:@"foo"
                                            purchaseReceipt:[NSData data] appStoreCountry:nil
                                             inLowPowerMode:@NO firmwareID:@"foo"];
}

SpecBegin(INTDeviceInfoObserver)

__block INTDeviceInfoObserver *observer;
__block INTFakeDeviceInfoSource *source;
__block INTFakeDeviceInfoObserverDelegate *delegate;
__block LTFakeKeyValuePersistentStorage *storage;

beforeEach(^{
  source = [[INTFakeDeviceInfoSource alloc] init];
  source.deviceInfoTemplate = [INTFakeDeviceInfo() dictionaryValue];
  delegate = [[INTFakeDeviceInfoObserverDelegate alloc] init];
  storage = [[LTFakeKeyValuePersistentStorage alloc] init];
  observer = [[INTDeviceInfoObserver alloc] initWithDeviceInfoSource:source storage:storage
                                                            delegate:delegate];
});

it(@"should report a new device info if none was stored", ^{
  expect(delegate.reportingDeviceInfoObserver).to.equal(observer);
  expect(delegate.reportedDeviceInfo.dictionaryValue).to.equal(source.deviceInfoTemplate);
  expect(delegate.reportedDeviceInfoRevisionID).to.beKindOf(NSUUID.class);
  expect(delegate.reportedIsNewRevision).to.equal(YES);
});

it(@"should persist device info over instances", ^{
  auto revisionID = delegate.reportedDeviceInfoRevisionID;
  observer = [[INTDeviceInfoObserver alloc] initWithDeviceInfoSource:source storage:storage
                                                            delegate:delegate];

  expect(delegate.reportingDeviceInfoObserver).to.equal(observer);
  expect(delegate.reportedDeviceInfo.dictionaryValue).to.equal(source.deviceInfoTemplate);
  expect(delegate.reportedDeviceInfoRevisionID).to.equal(revisionID);
  expect(delegate.reportedIsNewRevision).to.equal(NO);
});

it(@"should call delegate with new device info if new app store coutry is set", ^{
  auto revisionID = delegate.reportedDeviceInfoRevisionID;
  [observer setAppStoreCountry:@"UK"];

  expect(delegate.reportingDeviceInfoObserver).to.equal(observer);
  expect(delegate.reportedDeviceInfo).to.equal([source deviceInfoWithAppStoreCountry:@"UK"]);
  expect(delegate.reportedDeviceInfoRevisionID).notTo.equal(revisionID);
  expect(delegate.reportedIsNewRevision).to.equal(YES);
});

it(@"should call delegate with with new device info if it changes over instances", ^{
  auto revisionID = delegate.reportedDeviceInfoRevisionID;

  source.deviceInfoTemplate = [INTFakeDeviceInfo() dictionaryValue];
  observer = [[INTDeviceInfoObserver alloc] initWithDeviceInfoSource:source storage:storage
                                                          delegate:delegate];

  expect(delegate.reportingDeviceInfoObserver).to.equal(observer);
  expect(delegate.reportedDeviceInfo.dictionaryValue).to.equal(source.deviceInfoTemplate);
  expect(delegate.reportedDeviceInfoRevisionID).notTo.equal(revisionID);
  expect(delegate.reportedIsNewRevision).to.equal(YES);
});

it(@"should report a new device token if none was stored", ^{
  auto deviceToken =
      LTVectorToNSData<unsigned char>({0x01, 0x23, 0x45, 0x67, 0x89, 0xab, 0xcd, 0xef});
  [observer setDeviceToken:deviceToken];
  expect(delegate.reportedDeviceToken).to.equal(deviceToken);
});

it(@"should persist device token over instances", ^{
  auto deviceToken =
      LTVectorToNSData<unsigned char>({0x01, 0x23, 0x45, 0x67, 0x89, 0xab, 0xcd, 0xef});
  [observer setDeviceToken:deviceToken];
  delegate = [[INTFakeDeviceInfoObserverDelegate alloc] init];
  observer = [[INTDeviceInfoObserver alloc] initWithDeviceInfoSource:source storage:storage
                                                            delegate:delegate];
  [observer setDeviceToken:deviceToken];

  expect(delegate.reportedDeviceToken).to.beNil();
});

it(@"should report changes to the device token", ^{
  auto deviceToken =
      LTVectorToNSData<unsigned char>({0x01, 0x23, 0x45, 0x67, 0x89, 0xab, 0xcd, 0xef});
  [observer setDeviceToken:deviceToken];
  expect(delegate.reportedDeviceToken).to.equal(deviceToken);

  [observer setDeviceToken:nil];
  expect(delegate.reportedDeviceToken).to.beNil();

  [observer setDeviceToken:deviceToken];
  expect(delegate.reportedDeviceToken).to.equal(deviceToken);
});

it(@"should report first launch if none is stored", ^{
  expect(delegate.reportedAppRunCount).to.equal(@1);
});

it(@"should increment app run count when run count exists in a given storage", ^{
  observer = [[INTDeviceInfoObserver alloc] initWithDeviceInfoSource:source storage:storage
                                                            delegate:delegate];
  expect(delegate.reportedAppRunCount).to.equal(@2);
});

SpecEnd
