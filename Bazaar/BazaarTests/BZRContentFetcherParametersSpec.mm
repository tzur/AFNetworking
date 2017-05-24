// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "BZRContentFetcherParameters.h"

#import "BZRDummyContentFetcher.h"
#import "BZRProductContentFetcher.h"

SpecBegin(BZRContentFetcherParameters)

context(@"conversion" , ^{
  it(@"should correctly return the parameters class for parsing", ^{
    NSDictionary *JSONDictionary = @{
      @"type": @"BZRDummyContentFetcher"
    };

    Class classForParsing =
        [BZRContentFetcherParameters classForParsingJSONDictionary:JSONDictionary];
    expect(classForParsing).to.equal([BZRDummyContentFetcher expectedParametersClass]);
  });

  it(@"should return nil if the class does not conforms to the fetcher protocol", ^{
    NSDictionary *JSONDictionary = @{
      @"type": @"InvalidFetcher"
    };

    Class classForParsing =
        [BZRContentFetcherParameters classForParsingJSONDictionary:JSONDictionary];
    expect(classForParsing).to.beNil();
  });

  it(@"should return if the key type is missing in the json", ^{
    NSDictionary *JSONDictionary = @{};

    Class classForParsing =
        [BZRContentFetcherParameters classForParsingJSONDictionary:JSONDictionary];
    expect(classForParsing).to.beNil();
  });
});

SpecEnd
