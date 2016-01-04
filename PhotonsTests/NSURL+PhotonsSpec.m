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

it(@"should return correct dictionary from url query", ^{
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

SpecEnd
