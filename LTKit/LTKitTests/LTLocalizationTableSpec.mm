// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import "LTLocalizationTable.h"

SpecBegin(LTLocalizationTable)

__block LTLocalizationTable *localizationTable;
__block NSString *testBundlePath;
__block NSBundle *testBundle;

beforeEach(^{
  testBundlePath = [[NSBundle bundleForClass:self.class] pathForResource:@"LocalizationTest"
                                                                  ofType:@"bundle"];
  testBundle = [NSBundle bundleWithPath:testBundlePath];
  LTAssert(testBundle, @"The test target is missing the LocalizationTest bundle");
});

context(@"non existing table", ^{
  beforeEach(^{
    localizationTable = [[LTLocalizationTable alloc] initWithBundle:testBundle
                                                          tableName:@"NonExistingTable"];
  });

  it(@"should return key when table does not exist", ^{
    NSString *localizedString = localizationTable[@"someString"];
    expect(localizedString).to.equal(@"someString");
  });
});

context(@"existing table", ^{
  beforeEach(^{
    localizationTable = [[LTLocalizationTable alloc] initWithBundle:testBundle
                                                          tableName:@"LocalizationTest"];
  });

  it(@"should localize string", ^{
    NSString *localizedString = localizationTable[@"keyString"];
    expect(localizedString).to.equal(@"localizedString");
  });

  it(@"should localize plural strings", ^{
    NSString *localizedString = [NSString stringWithFormat:localizationTable[@"%lu plural"], 0];
    expect(localizedString).to.equal(@"No plurals");

    localizedString = [NSString stringWithFormat:localizationTable[@"%lu plural"], 1];
    expect(localizedString).to.equal(@"A plural");

    localizedString = [NSString stringWithFormat:localizationTable[@"%lu plural"], 12];
    expect(localizedString).to.equal(@"12 plurals");
  });
});

SpecEnd
