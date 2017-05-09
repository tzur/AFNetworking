// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "BZRLocalContentFetcherParameters.h"

SpecBegin(BZRLocalContentFetcherParameters)

context(@"conversion" , ^{
  __block NSString *localFilePath;
  __block NSURL *localFileURL;

  beforeEach(^{
    localFilePath = @"file:///foo/file.zip";
    localFileURL = [NSURL URLWithString:localFilePath];
  });

  it(@"should correctly convert BZRLocalContentFetcherParameters instance to JSON dictionary", ^{
    NSDictionary *dictionaryValue = @{
      @instanceKeypath(BZRLocalContentFetcherParameters, URL): localFileURL,
    };

    NSError *error;
    BZRLocalContentFetcherParameters *parameters =
        [[BZRLocalContentFetcherParameters alloc] initWithDictionary:dictionaryValue error:&error];
    expect(error).to.beNil();

    NSDictionary *JSONDictionary = [MTLJSONAdapter JSONDictionaryFromModel:parameters];

    expect(JSONDictionary[@instanceKeypath(BZRLocalContentFetcherParameters, URL)]).to
        .equal(localFilePath);
  });

  it(@"should correctly convert from JSON dictionary to BZRLocalContentFetcherParameters", ^{
    NSDictionary *JSONDictionary = @{
      @"type": @"BZRLocalContentFetcherParameters",
      @"URL": localFilePath
    };

    NSError *error;
    BZRLocalContentFetcherParameters *parameters =
        [MTLJSONAdapter modelOfClass:[BZRLocalContentFetcherParameters class]
                  fromJSONDictionary:JSONDictionary error:&error];
    expect(error).to.beNil();
    expect(parameters.URL).to.equal(localFileURL);
  });
});

SpecEnd
