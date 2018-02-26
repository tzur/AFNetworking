// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Daniel Hadar.

#import "HUIDocument.h"

#import <LTKit/NSBundle+Path.h>

#import "HUIItem.h"
#import "HUISection.h"
#import "HUISettings.h"

SpecBegin(HUIDocument)
__block HUIDocument *document;
__block NSError *error;

context(@"document deserialization", ^{
  beforeEach(^{
    auto dict = @{
      @"title": @"title",
      @"sections": @[
        @{
          @"key": @"key1",
          @"title": @"title1",
          @"items": @[
            @{
              @"type": @"text",
              @"text": @"text1",
              @"associated_feature_item_titles": @[@"title1", @"title2"]
            }]
        },
        @{
          @"key": @"key2",
          @"title": @"title2",
          @"items": @[@{@"type": @"text", @"text": @"text2"}]
        },
        @{
          @"key": @"key3",
          @"title": @"title3",
          @"items": @[
             @{
               @"type": @"image",
               @"image": @"image1",
               @"associated_feature_item_titles": @[@"title3"]
             },
             @{@"type": @"video", @"video": @"video1"},
             @{@"type": @"slideshow", @"images": @[@"slideshow1", @"slideshow2"]}]
        }
      ]
    };
    document = [MTLJSONAdapter modelOfClass:HUIDocument.class fromJSONDictionary:dict error:&error];
  });

  it(@"should deserialize without errors", ^{
    expect(error).to.beNil();
    expect(document).toNot.beNil();
  });

  it(@"should deserialize correctly", ^{
    expect(document.title).to.equal(@"title");
    expect(document.sections).to.haveCountOf(3);
    expect(document.featureItemTitles).notTo.beNil();
    auto expectedTitles = [NSSet setWithArray:@[@"title1", @"title2", @"title3"]];
    expect(document.featureItemTitles).to.equal(expectedTitles);
  });
});

context(@"sections", ^{
  it(@"should find by key", ^{
    auto dict = @{
      @"title": @"title",
      @"sections": @[
        @{@"key": @"key1", @"title": @"title1", @"items": @[]},
        @{@"key": @"key2", @"title": @"title2", @"items": @[]}
      ]
    };
    document = [MTLJSONAdapter modelOfClass:HUIDocument.class fromJSONDictionary:dict error:&error];

    expect([[document sectionForKey:@"key1"] key]).to.equal(@"key1");
    expect([[document sectionForKey:@"key2"] key]).to.equal(@"key2");
  });

  it(@"should return nil for wrong key", ^{
    auto dict = @{@"title": @"title", @"sections": @[@{@"key": @"key1", @"items": @[]}]};
    document = [MTLJSONAdapter modelOfClass:HUIDocument.class fromJSONDictionary:dict error:&error];

    expect([document sectionForKey:@"no such key"]).to.beNil();
  });

  context(@"finding sections by feature hierarchy path", ^{
    beforeEach(^{
      auto dict = @{
        @"title": @"title",
        @"sections": @[
          @{
            @"key": @"key1",
            @"items": @[
              @{
                @"type": @"text",
                @"text": @"text1",
                @"associated_feature_item_titles": @[@"title1"]
              }]
          },
          @{
            @"key": @"key2",
            @"items": @[
              @{
                @"type": @"image",
                @"image": @"image2",
                @"associated_feature_item_titles": @[@"title2"]
              }]
          }]
      };
    document = [MTLJSONAdapter modelOfClass:HUIDocument.class fromJSONDictionary:dict error:&error];
    });

    it(@"should find section by hierarchy path it matches", ^{
      expect([document sectionKeyForPath:@"title1"]).to.equal(@"key1");
      expect([document sectionKeyForPath:@"no such title/title1"]).to.equal(@"key1");
      expect([document sectionKeyForPath:@"title1/no such title"]).to.equal(@"key1");
    });

    it(@"should find the first section matches a feature hierarchy path", ^{
      expect([document sectionKeyForPath:@"title2/title1"]).to.equal(@"key2");
      expect([document sectionKeyForPath:@"title1/title2"]).to.equal(@"key1");
    });

    it(@"should return nil for a feature hierarchy path that doesn't match no section", ^{
      expect([document sectionKeyForPath:@"no such/title"]).to.beNil();
    });
  });
});

context(@"empty document", ^{
  __block HUIDocument *document;
  __block NSError *error;

  beforeEach(^{
    auto dict = @{};
    document = [MTLJSONAdapter modelOfClass:HUIDocument.class fromJSONDictionary:dict error:&error];
  });

  it(@"should deserialize without errors", ^{
    expect(error).to.beNil();
  });

  it(@"should deserialize correctly", ^{
    expect(document.sections).toNot.beNil();
    expect(document.sections).to.haveCountOf(0);
    expect(document.featureItemTitles).to.equal([NSSet set]);
  });

  it(@"should have correct associated feature titles", ^{
    expect(document.featureItemTitles).to.equal([NSSet set]);
  });
});

context(@"document initializion from a JSON path", ^{
  it(@"should load correct help document from a JSON path", ^{
    auto expectedDict = @{
      @"title": @"title",
      @"sections": @[
        @{
          @"key": @"key",
          @"items": @[
            @{
               @"type": @"slideshow",
               @"transition": @"curtain",
               @"title": @"title",
               @"body": @"body",
               @"images": @[]
            }
          ]
        }
      ]
    };
    HUIDocument *expectedDocument = [MTLJSONAdapter modelOfClass:HUIDocument.class
                                              fromJSONDictionary:expectedDict error:nil];
    auto path = [NSBundle lt_pathForResource:@"HelpDocument.json" nearClass:self.class];
    NSError *error;

    auto loadedDocument = [HUIDocument helpDocumentForJsonAtPath:path error:&error];

    expect(error).beNil();
    expect(loadedDocument).to.equal(expectedDocument);
  });

  it(@"should report LTErrorCodeFileNotFound when path is nil", ^{
    NSString *nilPath = nil;
    NSError *error;

    HUIDocument *loadedDocument = [HUIDocument helpDocumentForJsonAtPath:nilPath error:&error];

    expect(loadedDocument).to.beNil();
    expect(error.code).to.equal(LTErrorCodeFileNotFound);
  });

  it(@"should report LTErrorCodeFileReadFailed when path is invalid", ^{
    auto invalidPath = [NSBundle lt_testBundle].bundlePath;
    NSError *error;

    auto loadedDocument = [HUIDocument helpDocumentForJsonAtPath:invalidPath error:&error];

    expect(loadedDocument).to.beNil();
    expect(error.code).to.equal(LTErrorCodeFileReadFailed);
  });

  it(@"should report LTErrorCodeFileReadFailed when JSON file is invalid", ^{
    auto path = [NSBundle lt_pathForResource:@"InvalidHelpDocument.json" nearClass:self.class];
    NSError *error;

    auto loadedDocument = [HUIDocument helpDocumentForJsonAtPath:path error:&error];

    expect(loadedDocument).to.beNil();
    expect(error.code).to.equal(LTErrorCodeFileReadFailed);
  });
});

context (@"localization", ^{
  __block HUIDocument *document;
  __block NSError *error;

  beforeEach(^{
    [HUISettings instance].localizationBlock = ^NSString * _Nullable(NSString * _Nonnull) {
      return @"localized title";
    };
    auto dict = @{@"title": @"title"};
    document = [MTLJSONAdapter modelOfClass:HUIDocument.class fromJSONDictionary:dict error:&error];
  });

  it(@"should localize title with localizationBlock", ^{
    expect(document.title).to.equal(@"localized title");
  });

  afterEach(^{
    [HUISettings instance].localizationBlock = nil;
  });
});

SpecEnd
