// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "NSURL+Photons.h"

#import "PTNNSURLTestUtils.h"

SpecBegin(NSURL_Photons)

__block NSArray *query;

beforeEach(^{
  query = @[
    [[NSURLQueryItem alloc] initWithName:@"foo" value:@"bar"],
    [[NSURLQueryItem alloc] initWithName:@"bar" value:@"baz"],
    [[NSURLQueryItem alloc] initWithName:@"baz" value:@"gaz"]
  ];
});

it(@"should return correct dictionary from query", ^{
  expect([NSURL ptn_dictionaryWithQuery:query]).to.equal(@{
    @"foo": @"bar",
    @"bar": @"baz",
    @"baz": @"gaz"
  });
});

it(@"should return correct dictionary from url with query", ^{
  expect(PTNCreateURL(@"foo", @"bar", query).ptn_queryDictionary).to.equal(@{
    @"foo": @"bar",
    @"bar": @"baz",
    @"baz": @"gaz"
  });
});

it(@"should use the last instance of multiple items with the same query name", ^{
  NSURLQueryItem *duplicateQueryItem = [[NSURLQueryItem alloc] initWithName:@"foo" value:@"qux"];
  NSArray *duplicateQuery = [query arrayByAddingObject:duplicateQueryItem];
  expect(PTNCreateURL(@"foo", @"bar", duplicateQuery).ptn_queryDictionary).to.equal(@{
    @"bar": @"baz",
    @"baz": @"gaz",
    @"foo": @"qux"
  });
});

it(@"should append query to url without a query", ^{
  NSURL *url = PTNCreateURL(@"foo", @"bar", nil);
  NSURL *urlWithQuery = [url ptn_URLByAppendingQuery:query];
  expect([NSURLComponents componentsWithURL:urlWithQuery
                    resolvingAgainstBaseURL:NO].queryItems).to.equal(query);
});

it(@"should append query to url with existing a query", ^{
  NSURLQueryItem *existingQuery = [[NSURLQueryItem alloc] initWithName:@"gaz" value:@"qux"];
  NSArray *completeQuery = [@[existingQuery] arrayByAddingObjectsFromArray:query];
  NSURL *url = PTNCreateURL(@"foo", @"bar", @[existingQuery]);
  NSURL *urlWithQuery = [url ptn_URLByAppendingQuery:query];
  expect([NSURLComponents componentsWithURL:urlWithQuery
                    resolvingAgainstBaseURL:NO].queryItems).to.equal(completeQuery);
});

it(@"should return correct array of NSURLQueryItem objects", ^{
  NSArray *queryArray = [NSURL ptn_queryWithDictionary:@{
    @"foo": @"bar",
    @"bar": @"baz",
    @"baz": @"gaz"
  }];

  expect([NSSet setWithArray:queryArray]).to.equal([NSSet setWithArray:query]);
});

SpecEnd
