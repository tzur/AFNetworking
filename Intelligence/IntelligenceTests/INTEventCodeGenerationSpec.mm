// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

#import <LTKit/NSDateFormatter+Formatters.h>

#import "INTAnalytricksFakeBase.h"
#import "INTAnalytricksFakeCommon.h"
#import "INTAnalytricksFakeConcrete.h"
#import "INTFakeInternalEvent.h"

SpecBegin(INTEventCodeGeneration)

static NSUUID * const kUUID = [NSUUID UUID];
static NSDate * const kDate = [NSDate date];

it(@"should initialize and serialize internal genereted event", ^{
  auto event = [[INTFakeInternalEvent alloc] initWithStringProperty:@"foo" uuidProperty:kUUID
                                                     numberProperty:@2.3 integerProperty:3
                                                    booleanProperty:YES dateProperty:kDate
                                                     nullableString:nil];

  expect(event.stringProperty).to.equal(@"foo");
  expect(event.uuidProperty).to.equal(kUUID);
  expect(event.integerProperty).to.equal(3);
  expect(event.numberProperty).to.equal(@2.3);
  expect(event.booleanProperty).to.equal(YES);
  expect(event.dateProperty).to.equal(kDate);
  expect(event.nullableString).to.beNil();

  NSDictionary *expectedDictionary = @{
    @"string_property": @"foo",
    @"uuid_property": kUUID.UUIDString,
    @"number_property": @2.3,
    @"integer_property": @(3),
    @"boolean_property": @(YES),
    @"date_property": [[NSDateFormatter lt_UTCDateFormatter] stringFromDate:kDate],
    @"nullable_string": [NSNull null]
  };

  expect(event.properties).to.equal(expectedDictionary);

  event = [[INTFakeInternalEvent alloc] initWithStringProperty:@"foo" uuidProperty:kUUID
                                                numberProperty:@2.3 integerProperty:3
                                               booleanProperty:YES dateProperty:kDate
                                                nullableString:@"bar"];

  expect(event.nullableString).to.equal(@"bar");

  expectedDictionary = @{
    @"string_property": @"foo",
    @"uuid_property": kUUID.UUIDString,
    @"number_property": @2.3,
    @"integer_property": @(3),
    @"boolean_property": @(YES),
    @"date_property": [[NSDateFormatter lt_UTCDateFormatter] stringFromDate:kDate],
    @"nullable_string": @"bar"
  };

  expect(event.properties).to.equal(expectedDictionary);
});

it(@"should initialize and serialize analytricks common genereted class", ^{
  auto common = [[INTAnalytricksFakeCommon alloc] initWithStringProperty:@"foo" uuidProperty:kUUID
                                                         numberProperty:@2.3 integerProperty:3
                                                        booleanProperty:YES dateProperty:kDate
                                                         nullableString:nil];

  expect(common.stringProperty).to.equal(@"foo");
  expect(common.uuidProperty).to.equal(kUUID);
  expect(common.integerProperty).to.equal(3);
  expect(common.numberProperty).to.equal(@2.3);
  expect(common.booleanProperty).to.equal(YES);
  expect(common.dateProperty).to.equal(kDate);
  expect(common.nullableString).to.beNil();

  NSDictionary *expectedDictionary = @{
    @"string_property": @"foo",
    @"uuid_property": kUUID.UUIDString,
    @"number_property": @2.3,
    @"integer_property": @(3),
    @"boolean_property": @(YES),
    @"date_property": [[NSDateFormatter lt_UTCDateFormatter] stringFromDate:kDate],
    @"nullable_string": [NSNull null]
  };

  expect(common.properties).to.equal(expectedDictionary);

  common = [[INTAnalytricksFakeCommon alloc] initWithStringProperty:@"foo" uuidProperty:kUUID
                                                    numberProperty:@2.3 integerProperty:3
                                                   booleanProperty:YES dateProperty:kDate
                                                    nullableString:@"bar"];

  expect(common.nullableString).to.equal(@"bar");

  expectedDictionary = @{
    @"string_property": @"foo",
    @"uuid_property": kUUID.UUIDString,
    @"number_property": @2.3,
    @"integer_property": @(3),
    @"boolean_property": @(YES),
    @"date_property": [[NSDateFormatter lt_UTCDateFormatter] stringFromDate:kDate],
    @"nullable_string": @"bar"
  };

  expect(common.properties).to.equal(expectedDictionary);
});

it(@"should initialize and serialize analytricks concrete analytricks event genereted class", ^{
  auto concrete = [[INTAnalytricksFakeConcrete alloc] initWithFoo:kUUID];

  expect(concrete.foo).to.equal(kUUID);

  NSDictionary *expectedDictionary = @{
    @"foo": kUUID.UUIDString,
    @"event": @"fake_concrete"
  };

  expect(concrete.properties).to.equal(expectedDictionary);
});

it(@"should initialize and serialize analytricks abstract event generated class", ^{
  auto concrete = [[INTAnalytricksFakeConcrete alloc] initWithFoo:kUUID];
  auto common = [[INTAnalytricksFakeCommon alloc] initWithStringProperty:@"bar" uuidProperty:kUUID
                                                         numberProperty:@2.3 integerProperty:3
                                                        booleanProperty:YES dateProperty:kDate
                                                         nullableString:nil];

  auto analytricksEvent = [[INTAnalytricksFakeBase alloc] initWithDataProvider:concrete
                                                      INTAnalytricksFakeCommon:common];

  expect(analytricksEvent.INTAnalytricksFakeCommon).to.equal(common);
  expect(analytricksEvent.dataProvider).to.equal(concrete);

  NSDictionary *expectedDictionary = @{
    @"foo": kUUID.UUIDString,
    @"event": @"fake_concrete",
    @"string_property": @"bar",
    @"uuid_property": kUUID.UUIDString,
    @"number_property": @2.3,
    @"integer_property": @(3),
    @"boolean_property": @(YES),
    @"date_property": [[NSDateFormatter lt_UTCDateFormatter] stringFromDate:kDate],
    @"nullable_string": [NSNull null]
  };

  expect(analytricksEvent.properties).to.equal(expectedDictionary);
});

SpecEnd
