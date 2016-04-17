// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Alex Gershovich.

#import "NSURL+Query.h"

SpecBegin(NSURL_Query)

context(@"queryDictionary", ^{
  it(@"should return empty dictionary for missing query", ^{
    NSURL *url = [NSURL URLWithString:@"foo/bar"];
    expect(url.queryDictionary).to.equal(@{});
  });

  it(@"should return empty dictionary for empty query", ^{
    NSURL *url = [NSURL URLWithString:@"foo/bar?"];
    expect(url.queryDictionary).to.equal(@{});
  });

  it(@"should contain correct query items with keys and values", ^{
    NSURL *url = [NSURL URLWithString:@"foo/bar?key1=value1&key2=value2"];
    expect(url.queryDictionary).to.equal(@{
      @"key1": @"value1",
      @"key2": @"value2"
    });
  });

  it(@"should return last value for duplicate keys", ^{
    NSURL *url = [NSURL URLWithString:@"foo/bar?key=value1&key=value2"];
    expect(url.queryDictionary[@"key"]).to.equal(@"value2");
  });

  it(@"should return empty string for missing value", ^{
    NSURL *url = [NSURL URLWithString:@"foo/bar?key"];
    expect(url.queryDictionary[@"key"]).to.equal(@"");
  });

  it(@"should return empty string for empty value", ^{
    NSURL *url = [NSURL URLWithString:@"foo/bar?key="];
    expect(url.queryDictionary[@"key"]).to.equal(@"");
  });

  it(@"should return empty key and value for empty item", ^{
    NSURL *url = [NSURL URLWithString:@"foo/bar?&"];
    expect(url.queryDictionary[@""]).to.equal(@"");
  });
});

context(@"queryItems", ^{
  it(@"should return nil for missing query", ^{
    NSURL *url = [NSURL URLWithString:@"foo/bar"];
    expect(url.queryItems).to.beNil();
  });

  it(@"should return empty array for empty query", ^{
    NSURL *url = [NSURL URLWithString:@"foo/bar?"];
    expect(url.queryItems).to.equal(@[]);
  });

  it(@"should contain correct query items with keys and values", ^{
    NSURL *url = [NSURL URLWithString:@"foo/bar?key1=value1&key2=value2"];
    expect(url.queryItems).to.equal(@[
      [NSURLQueryItem queryItemWithName:@"key1" value:@"value1"],
      [NSURLQueryItem queryItemWithName:@"key2" value:@"value2"]
    ]);
  });

  it(@"should contain duplicate query items in correct order for duplicate keys", ^{
    NSURL *url = [NSURL URLWithString:@"foo/bar?key=value1&key=value2"];
    expect(url.queryItems).to.equal(@[
      [NSURLQueryItem queryItemWithName:@"key" value:@"value1"],
      [NSURLQueryItem queryItemWithName:@"key" value:@"value2"]
    ]);
  });

  it(@"should return nil value for missing value in query", ^{
    NSURL *url = [NSURL URLWithString:@"foo/bar?key"];
    expect(url.queryItems[0]).to.equal([NSURLQueryItem queryItemWithName:@"key" value:nil]);
  });

  it(@"should return empty value for empty value in query", ^{
    NSURL *url = [NSURL URLWithString:@"foo/bar?key="];
    expect(url.queryItems[0]).to.equal([NSURLQueryItem queryItemWithName:@"key" value:@""]);
  });

  it(@"should return empty key and nil value for empty item", ^{
    NSURL *url = [NSURL URLWithString:@"foo/bar?&"];
    expect(url.queryItems[0]).to.equal([NSURLQueryItem queryItemWithName:@"" value:nil]);
  });
});

context(@"lt_URLByAppendingQueryItems", ^{
  it(@"should not modify URL when appending empty query item", ^{
    NSURL *url = [NSURL URLWithString:@"foo/bar?key=value"];
    expect([url lt_URLByAppendingQueryItems:@[]]).to.equal(url);
  });

  it(@"should correctly append query to URL without a query", ^{
    NSURL *url = [NSURL URLWithString:@"foo/bar"];
    NSURLQueryItem *item = [NSURLQueryItem queryItemWithName:@"key" value:@"value"];

    NSURL *urlWithQuery = [url lt_URLByAppendingQueryItems:@[item]];
    expect(urlWithQuery.queryItems).to.equal(@[item]);
  });

  it(@"should append query to url with existing query", ^{
    NSURL *url = [NSURL URLWithString:@"foo/bar?key=value1"];
    NSURLQueryItem *existing = [[NSURLQueryItem alloc] initWithName:@"key" value:@"value1"];
    NSURLQueryItem *appended = [[NSURLQueryItem alloc] initWithName:@"key" value:@"value2"];

    NSURL *urlWithQuery = [url lt_URLByAppendingQueryItems:@[appended]];
    expect(urlWithQuery.queryItems).to.equal(@[existing, appended]);
  });

  it(@"should preserve relative URL", ^{
    NSURL *baseURL = [NSURL URLWithString:@"scheme://domain/root"];
    NSURL *relativeURL = [NSURL URLWithString:@"/newroot/path?key1=value1" relativeToURL:baseURL];

    NSURLQueryItem *existing = [[NSURLQueryItem alloc] initWithName:@"key1" value:@"value1"];
    NSURLQueryItem *appended = [[NSURLQueryItem alloc] initWithName:@"key2" value:@"value2"];
    NSURL *urlWithQuery = [relativeURL lt_URLByAppendingQueryItems:@[appended]];

    expect(urlWithQuery.baseURL).to.equal(baseURL);
    expect(urlWithQuery.queryItems).to.equal(@[existing, appended]);
  });
});

context(@"lt_URLByAppendingQueryDictionary", ^{
  it(@"should raise when query dictionary is illegal", ^{
    NSURL *url = [NSURL URLWithString:@"foo"];

    expect(^{
      [url lt_URLByAppendingQueryDictionary:@{@"key": [NSNull null]}];
    }).to.raise(NSInvalidArgumentException);

    expect(^{
      [url lt_URLByAppendingQueryDictionary:@{@42: @"value"}];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should not modify URL when appending empty query dictionary", ^{
    NSURL *url = [NSURL URLWithString:@"foo/bar&key=value"];
    expect([url lt_URLByAppendingQueryDictionary:@{}]).to.equal(url);
  });

  it(@"should correctly append query dictionary to URL without a query", ^{
    NSURL *url = [NSURL URLWithString:@"foo/bar"];
    NSURL *urlWithQuery = [url lt_URLByAppendingQueryDictionary:@{@"key": @"value"}];
    expect(urlWithQuery.query).to.equal(@"key=value");
  });

  it(@"should append query to url with existing query", ^{
    NSURL *url = [NSURL URLWithString:@"foo/bar?key=value1"];
    NSURL *urlWithQuery = [url lt_URLByAppendingQueryDictionary:@{@"key": @"value2"}];
    expect(urlWithQuery.query).to.equal(@"key=value1&key=value2");
  });

  it(@"should append empty query value for empty dictionary value", ^{
    NSURL *url = [NSURL URLWithString:@"foo/bar"];
    NSURL *urlWithQuery = [url lt_URLByAppendingQueryDictionary:@{@"key": @""}];
    expect(urlWithQuery.query).to.equal(@"key=");
  });

  it(@"should append empty query key for empty dictionary key", ^{
    NSURL *url = [NSURL URLWithString:@"foo/bar"];
    NSURL *urlWithQuery = [url lt_URLByAppendingQueryDictionary:@{@"": @""}];
    expect(urlWithQuery.query).to.equal(@"=");
  });

  it(@"should preserve relative URL", ^{
    NSURL *baseURL = [NSURL URLWithString:@"scheme://domain/root"];
    NSURL *relativeURL = [NSURL URLWithString:@"/newroot/path?key1=value1" relativeToURL:baseURL];

    NSURL *urlWithQuery = [relativeURL lt_URLByAppendingQueryDictionary:@{@"key2": @"value2"}];

    expect(urlWithQuery.baseURL).to.equal(baseURL);
    expect(urlWithQuery.query).to.equal(@"key1=value1&key2=value2");
  });
});

SpecEnd
