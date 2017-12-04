// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Alex Gershovich.

#import "NSURL+Query.h"

SpecBegin(NSURL_Query)

context(@"queryDictionary", ^{
  it(@"should return empty dictionary for missing query", ^{
    NSURL *url = [NSURL URLWithString:@"foo/bar"];
    expect(url.lt_queryDictionary).to.equal(@{});
  });

  it(@"should return empty dictionary for empty query", ^{
    NSURL *url = [NSURL URLWithString:@"foo/bar?"];
    expect(url.lt_queryDictionary).to.equal(@{});
  });

  it(@"should contain correct query items with keys and values", ^{
    NSURL *url = [NSURL URLWithString:@"foo/bar?key1=value1&key2=value2"];
    expect(url.lt_queryDictionary).to.equal(@{
      @"key1": @"value1",
      @"key2": @"value2"
    });
  });

  it(@"should return last value for duplicate keys", ^{
    NSURL *url = [NSURL URLWithString:@"foo/bar?key=value1&key=value2"];
    expect(url.lt_queryDictionary[@"key"]).to.equal(@"value2");
  });

  it(@"should return empty string for missing value", ^{
    NSURL *url = [NSURL URLWithString:@"foo/bar?key"];
    expect(url.lt_queryDictionary[@"key"]).to.equal(@"");
  });

  it(@"should return empty string for empty value", ^{
    NSURL *url = [NSURL URLWithString:@"foo/bar?key="];
    expect(url.lt_queryDictionary[@"key"]).to.equal(@"");
  });

  it(@"should return empty key and value for empty item", ^{
    NSURL *url = [NSURL URLWithString:@"foo/bar?&"];
    expect(url.lt_queryDictionary[@""]).to.equal(@"");
  });
});

context(@"queryArrayDictionary", ^{
  it(@"should return empty dictionary for missing query", ^{
    NSURL *url = [NSURL URLWithString:@"foo/bar"];
    expect(url.lt_queryArrayDictionary).to.equal(@{});
  });

  it(@"should return empty dictionary for empty query", ^{
    NSURL *url = [NSURL URLWithString:@"foo/bar?"];
    expect(url.lt_queryArrayDictionary).to.equal(@{});
  });

  it(@"should contain correct query items with keys and values", ^{
    NSURL *url = [NSURL URLWithString:@"foo/bar?key1=value1&key2=value2"];
    expect(url.lt_queryArrayDictionary).to.equal(@{
      @"key1": @[@"value1"],
      @"key2": @[@"value2"]
    });
  });

  it(@"should return all values for duplicate keys", ^{
    NSURL *url = [NSURL URLWithString:@"foo/bar?key=value1&key=value2"];
    expect(url.lt_queryArrayDictionary[@"key"]).to.equal(@[@"value1", @"value2"]);
  });

  it(@"should return empty string for missing value", ^{
    NSURL *url = [NSURL URLWithString:@"foo/bar?key"];
    expect(url.lt_queryArrayDictionary[@"key"]).to.equal(@[@""]);
  });

  it(@"should return empty string for empty value", ^{
    NSURL *url = [NSURL URLWithString:@"foo/bar?key="];
    expect(url.lt_queryArrayDictionary[@"key"]).to.equal(@[@""]);
  });

  it(@"should return empty key and values for empty items", ^{
    NSURL *url = [NSURL URLWithString:@"foo/bar?&"];
    expect(url.lt_queryArrayDictionary[@""]).to.equal(@[@"", @""]);
  });

  it(@"should join arrays even without consecutive keys", ^{
    NSURL *url = [NSURL URLWithString:@"foo/bar?key1=value1&key2=value1&key1=value2"];
    expect(url.lt_queryArrayDictionary).to.equal(@{
      @"key1": @[@"value1", @"value2"],
      @"key2": @[@"value1"]
    });
  });
});

context(@"queryItems", ^{
  it(@"should return nil for missing query", ^{
    NSURL *url = [NSURL URLWithString:@"foo/bar"];
    expect(url.lt_queryItems).to.beNil();
  });

  it(@"should return empty array for empty query", ^{
    NSURL *url = [NSURL URLWithString:@"foo/bar?"];
    expect(url.lt_queryItems).to.equal(@[]);
  });

  it(@"should contain correct query items with keys and values", ^{
    NSURL *url = [NSURL URLWithString:@"foo/bar?key1=value1&key2=value2"];
    expect(url.lt_queryItems).to.equal(@[
      [NSURLQueryItem queryItemWithName:@"key1" value:@"value1"],
      [NSURLQueryItem queryItemWithName:@"key2" value:@"value2"]
    ]);
  });

  it(@"should contain duplicate query items in correct order for duplicate keys", ^{
    NSURL *url = [NSURL URLWithString:@"foo/bar?key=value1&key=value2"];
    expect(url.lt_queryItems).to.equal(@[
      [NSURLQueryItem queryItemWithName:@"key" value:@"value1"],
      [NSURLQueryItem queryItemWithName:@"key" value:@"value2"]
    ]);
  });

  it(@"should return nil value for missing value in query", ^{
    NSURL *url = [NSURL URLWithString:@"foo/bar?key"];
    expect(url.lt_queryItems[0]).to.equal([NSURLQueryItem queryItemWithName:@"key" value:nil]);
  });

  it(@"should return empty value for empty value in query", ^{
    NSURL *url = [NSURL URLWithString:@"foo/bar?key="];
    expect(url.lt_queryItems[0]).to.equal([NSURLQueryItem queryItemWithName:@"key" value:@""]);
  });

  it(@"should return empty key and nil value for empty item", ^{
    NSURL *url = [NSURL URLWithString:@"foo/bar?&"];
    expect(url.lt_queryItems[0]).to.equal([NSURLQueryItem queryItemWithName:@"" value:nil]);
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
    expect(urlWithQuery.lt_queryItems).to.equal(@[item]);
  });

  it(@"should append query to url with existing query", ^{
    NSURL *url = [NSURL URLWithString:@"foo/bar?key=value1"];
    NSURLQueryItem *existing = [[NSURLQueryItem alloc] initWithName:@"key" value:@"value1"];
    NSURLQueryItem *appended = [[NSURLQueryItem alloc] initWithName:@"key" value:@"value2"];

    NSURL *urlWithQuery = [url lt_URLByAppendingQueryItems:@[appended]];
    expect(urlWithQuery.lt_queryItems).to.equal(@[existing, appended]);
  });

  it(@"should preserve relative URL", ^{
    NSURL *baseURL = [NSURL URLWithString:@"scheme://domain/root"];
    NSURL *relativeURL = [NSURL URLWithString:@"/newroot/path?key1=value1" relativeToURL:baseURL];

    NSURLQueryItem *existing = [[NSURLQueryItem alloc] initWithName:@"key1" value:@"value1"];
    NSURLQueryItem *appended = [[NSURLQueryItem alloc] initWithName:@"key2" value:@"value2"];
    NSURL *urlWithQuery = [relativeURL lt_URLByAppendingQueryItems:@[appended]];

    expect(urlWithQuery.baseURL).to.equal(baseURL);
    expect(urlWithQuery.lt_queryItems).to.equal(@[existing, appended]);
  });
});

context(@"lt_URLByReplacingQueryItemsWithName", ^{
  it(@"should replace query items for valid arguments", ^{
    NSURL *url = [NSURL URLWithString:@"foo/bar?key=value&foo=bar&key=baz"];
    NSURL *expectedURL = [NSURL URLWithString:@"foo/bar?key=foo&foo=bar&key=foo"];

    expect([url lt_URLByReplacingQueryItemsWithName:@"key" withValue:@"foo"]).to.equal(expectedURL);
  });

  it(@"should preserve relative URL", ^{
    NSURL *baseURL = [NSURL URLWithString:@"scheme://domain/root"];
    NSURL *relativeURL = [NSURL URLWithString:@"/newroot/path?key1=value1" relativeToURL:baseURL];
    NSURL *url = [relativeURL lt_URLByReplacingQueryItemsWithName:@"key1" withValue:@"value2"];

    expect(url.baseURL).to.equal(baseURL);
    expect(url.query).to.equal(@"key1=value2");
  });

  it(@"should return the same URL if the given name has no respective query item", ^{
    NSURL *url = [NSURL URLWithString:@"foo/bar?key=value&foo=bar"];
    expect([url lt_URLByReplacingQueryItemsWithName:@"baz" withValue:@"bar"]).to.equal(url);
  });
});

context(@"lt_URLByAppendingQueryDictionary", ^{
  it(@"should not modify URL when appending empty query dictionary", ^{
    NSURL *url = [NSURL URLWithString:@"foo/bar?key=value"];
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

context(@"lt_URLByAppendingQueryArrayDictionary", ^{
  it(@"should not modify URL when appending empty query dictionary", ^{
    NSURL *url = [NSURL URLWithString:@"foo/bar?key=value"];
    expect([url lt_URLByAppendingQueryArrayDictionary:@{}]).to.equal(url);
  });

  it(@"should correctly append query dictionary to URL without a query", ^{
    NSURL *url = [NSURL URLWithString:@"foo/bar"];
    NSURL *urlWithQuery =
        [url lt_URLByAppendingQueryArrayDictionary:@{@"key": @[@"value1", @"value2"]}];
    expect(urlWithQuery.query).to.equal(@"key=value1&key=value2");
  });

  it(@"should append query to url with existing query", ^{
    NSURL *url = [NSURL URLWithString:@"foo/bar?key=value1"];
    NSURL *urlWithQuery =
        [url lt_URLByAppendingQueryArrayDictionary:@{@"key": @[@"value2", @"value3"]}];
    expect(urlWithQuery.query).to.equal(@"key=value1&key=value2&key=value3");
  });

  it(@"should append empty query value for empty dictionary value", ^{
    NSURL *url = [NSURL URLWithString:@"foo/bar"];
    NSURL *urlWithQuery = [url lt_URLByAppendingQueryArrayDictionary:@{@"key": @[@""]}];
    expect(urlWithQuery.query).to.equal(@"key=");
  });

  it(@"should append empty query key for empty dictionary key", ^{
    NSURL *url = [NSURL URLWithString:@"foo/bar"];
    NSURL *urlWithQuery = [url lt_URLByAppendingQueryArrayDictionary:@{@"": @[@""]}];
    expect(urlWithQuery.query).to.equal(@"=");
  });

  it(@"should preserve relative URL", ^{
    NSURL *baseURL = [NSURL URLWithString:@"scheme://domain/root"];
    NSURL *relativeURL = [NSURL URLWithString:@"/newroot/path?key1=value1" relativeToURL:baseURL];

    NSURL *urlWithQuery =
        [relativeURL lt_URLByAppendingQueryArrayDictionary:@{@"key2": @[@"value2"]}];

    expect(urlWithQuery.baseURL).to.equal(baseURL);
    expect(urlWithQuery.query).to.equal(@"key1=value1&key2=value2");
  });
});

SpecEnd
