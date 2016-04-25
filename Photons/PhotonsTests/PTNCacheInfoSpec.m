// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNCacheInfo.h"

SpecBegin(PTNCacheInfo)

__block NSDate *responseTime;
__block NSString *etag;

static const NSTimeInterval kMaxAge = 10.0;

beforeEach(^{
  responseTime = [[NSDate alloc] initWithTimeIntervalSince1970:1337];
  etag = @"foo";
});

context(@"creation", ^{
  it(@"should initialize with response time, max age and entity tag", ^{
    PTNCacheInfo *info = [[PTNCacheInfo alloc] initWithMaxAge:kMaxAge responseTime:responseTime
                                                    entityTag:etag];
    expect(info.maxAge).to.equal(kMaxAge);
    expect(info.responseTime).to.equal(responseTime);
    expect(info.entityTag).to.equal(etag);
  });

  it(@"should initialize with max age and entity tag", ^{
    NSDate *dateBeforeCreation = [NSDate date];
    PTNCacheInfo *info = [[PTNCacheInfo alloc] initWithMaxAge:kMaxAge entityTag:etag];
    NSDate *dateAfterCreation = [NSDate date];

    expect(info.maxAge).to.equal(kMaxAge);
    expect(info.entityTag).to.equal(etag);

    expect(info.responseTime).to.beGreaterThanOrEqualTo(dateBeforeCreation);
    expect(info.responseTime).to.beLessThanOrEqualTo(dateAfterCreation);
  });

  it(@"should initialize cache info by resetting response time", ^{
    PTNCacheInfo *info = [[PTNCacheInfo alloc] initWithMaxAge:kMaxAge responseTime:responseTime
                                                    entityTag:etag];

    PTNCacheInfo *resetInfo = [info refreshedCacheInfo];
    expect(resetInfo.maxAge).to.equal(kMaxAge);
    expect([resetInfo.responseTime compare:info.responseTime]).to.equal(NSOrderedDescending);
    expect(resetInfo.entityTag).to.equal(etag);
  });
});

it(@"should correctly calculate freshness for given date", ^{
    PTNCacheInfo *info = [[PTNCacheInfo alloc] initWithMaxAge:kMaxAge responseTime:responseTime
                                                    entityTag:etag];
    expect([info isFreshComparedTo:[NSDate distantFuture]]).to.beFalsy();
    expect([info isFreshComparedTo:[NSDate distantPast]]).to.beTruthy();
    expect([info isFreshComparedTo:responseTime]).to.beTruthy();
    expect([info isFreshComparedTo:[responseTime dateByAddingTimeInterval:11]]).to.beFalsy();
});

it(@"should correctly calculate freshness from current time", ^{
  PTNCacheInfo *info = [[PTNCacheInfo alloc] initWithMaxAge:kMaxAge responseTime:responseTime
                                                  entityTag:etag];
  expect([info isFresh]).to.beFalsy();
});

context(@"equality", ^{
  __block PTNCacheInfo *firstInfo;
  __block PTNCacheInfo *secondInfo;
  __block PTNCacheInfo *otherInfo;

  beforeEach(^{
    firstInfo = [[PTNCacheInfo alloc] initWithMaxAge:kMaxAge responseTime:responseTime
                                           entityTag:etag];
    secondInfo = [[PTNCacheInfo alloc] initWithMaxAge:kMaxAge responseTime:responseTime
                                            entityTag:etag];
    otherInfo = [[PTNCacheInfo alloc] initWithMaxAge:1338 responseTime:responseTime
                                           entityTag:@"bar"];
  });

  it(@"should handle isEqual correctly", ^{
    expect(firstInfo).to.equal(secondInfo);
    expect(secondInfo).to.equal(firstInfo);

    expect(firstInfo).notTo.equal(otherInfo);
    expect(secondInfo).notTo.equal(otherInfo);
  });

  it(@"should create proper hash", ^{
    expect(firstInfo.hash).to.equal(secondInfo.hash);
  });
});

context(@"serializing", ^{
  it(@"should serialize and deserialize", ^{
    PTNCacheInfo *info = [[PTNCacheInfo alloc] initWithMaxAge:kMaxAge responseTime:responseTime
                                                    entityTag:etag];
    PTNCacheInfo *decodedInfo = [[PTNCacheInfo alloc] initWithDictionary:info.dictionary];
    expect(decodedInfo.maxAge).to.equal(info.maxAge);
    expect(decodedInfo.responseTime).to.equal(info.responseTime);
    expect(decodedInfo.entityTag).to.equal(info.entityTag);
  });

  it(@"should serialize and deserialize with nil values", ^{
    PTNCacheInfo *info = [[PTNCacheInfo alloc] initWithMaxAge:kMaxAge responseTime:responseTime
                                                    entityTag:nil];
    PTNCacheInfo *decodedInfo = [[PTNCacheInfo alloc] initWithDictionary:info.dictionary];
    expect(decodedInfo.maxAge).to.equal(info.maxAge);
    expect(decodedInfo.responseTime).to.equal(info.responseTime);
    expect(decodedInfo.entityTag).to.equal(info.entityTag);
  });

  it(@"should return nil for dictionaries with wrong model version", ^{
    PTNCacheInfo *info = [[PTNCacheInfo alloc] initWithMaxAge:kMaxAge responseTime:responseTime
                                                    entityTag:etag];

    NSMutableDictionary *invalidModelDictionary = [info.dictionary mutableCopy];
    invalidModelDictionary[@"version"] = @(-1);

    PTNCacheInfo *decodedInfo = [[PTNCacheInfo alloc] initWithDictionary:invalidModelDictionary];
    expect(decodedInfo).to.equal(nil);
  });

  it(@"should return nil for unrecognized dictionaries", ^{
    PTNCacheInfo *decodedInfo = [[PTNCacheInfo alloc] initWithDictionary:@{@"foo": @"bar"}];
    expect(decodedInfo).to.equal(nil);
  });
});

SpecEnd
