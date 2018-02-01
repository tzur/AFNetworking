// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Daniel Hadar.

#import "HUISection.h"

#import "HUIItem.h"

SpecBegin(HUISection)

context(@"initialization", ^{
  __block HUIItem *item1;
  __block HUIItem *item2;
  __block HUIItem *item3;
  __block HUISection *section;

  beforeEach(^{
    item1 = OCMClassMock(HUIItem.class);
    item2 = OCMClassMock(HUIItem.class);
    item3 = OCMClassMock(HUIItem.class);
    section = [[HUISection alloc] initWithKey:@"key" title:@"title" items:@[item1, item2, item3]];
  });

  it(@"should initialize correctly", ^{
    expect(section.key).to.equal(@"key");
    expect(section.title).to.equal(@"title");
    expect(section.items).to.haveACountOf(3);
  });

  it(@"should have valid properties after initialization", ^{
    OCMStub([item1 associatedFeatureItemTitles]).andReturn(@[@"feature1"]);
    OCMStub([item2 associatedFeatureItemTitles]).andReturn(@[@"feature2"]);
    NSSet *expectedTitles = [NSSet setWithArray:@[@"feature1", @"feature2"]];

    expect([section hasTitle]).to.beTruthy();
    expect([section featureItemTitles]).to.equal(expectedTitles);
  });
});

context(@"deserialization", ^{
  __block HUISection *sectionWithTitle;
  __block NSError *errorForSectionWithTitle;
  __block HUISection *sectionWithoutTitle;
  __block NSError *errorForSectionWithoutTitle;

  beforeEach(^{
    NSDictionary *dictWithTitle = @{
      @"key": @"sectionWithTitle",
      @"title": @"title",
      @"items": @[],
    };

    NSDictionary *dictWithoutTitle = @{
      @"key": @"sectionWithoutTitle",
      @"items": @[],
    };

    sectionWithTitle = [MTLJSONAdapter modelOfClass:HUISection.class
                                 fromJSONDictionary:dictWithTitle
                                              error:&errorForSectionWithTitle];
    sectionWithoutTitle = [MTLJSONAdapter modelOfClass:HUISection.class
                                    fromJSONDictionary:dictWithoutTitle
                                                 error:&errorForSectionWithoutTitle];
  });

  it(@"should deserialize without errors", ^{
    expect(errorForSectionWithTitle).to.beNil();
    expect(errorForSectionWithoutTitle).to.beNil();
  });

  it(@"should deserialize correctly", ^{
    expect(sectionWithTitle.key).to.equal(@"sectionWithTitle");
    expect(sectionWithTitle.title).to.equal(@"title");
    expect(sectionWithoutTitle.key).to.equal(@"sectionWithoutTitle");
    expect(sectionWithoutTitle.title).to.beNil();
  });

  it(@"should have valid properties after deserialization", ^{
    expect([sectionWithTitle hasTitle]).to.beTruthy();
    expect([sectionWithoutTitle hasTitle]).to.beFalsy();
    expect([sectionWithTitle featureItemTitles]).to.equal([NSSet set]);
    expect([sectionWithoutTitle featureItemTitles]).to.equal([NSSet set]);
  });
});

context(@"localization", ^{
  beforeEach(^{
    HUIModelSettings.localizationBlock = ^NSString * _Nullable(NSString *) {
      return @"localized title";
    };
  });

  afterEach(^{
    HUIModelSettings.localizationBlock = nil;
  });

  it(@"should localize title with localizationBlock when section created from dictionary", ^{
    NSError *error;
    NSDictionary *dict = @{
      @"title": @"title1",
    };
    HUISection *sectionFromDictionary = [MTLJSONAdapter modelOfClass:HUISection.class
                                                  fromJSONDictionary:dict error:&error];
    expect(sectionFromDictionary.title).to.equal(@"localized title");
  });

  it(@"should localize title with localizationBlock when section created from initializer", ^{
    HUISection *sectionFromInitializer = [[HUISection alloc] initWithKey:@"key" title:@"title"
                                                                   items:@[]];
    expect(sectionFromInitializer.title).to.equal(@"localized title");
  });
});

SpecEnd
