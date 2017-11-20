// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "SPXPagingView.h"

SpecBegin(SPXPagingView)

context(@"setting page width ratio", ^{
  it(@"should set the page width correctly", ^{
    auto pagingView = [[SPXPagingView alloc] init];
    pagingView.pageViewWidthRatio = 0.3;
    expect(pagingView.pageViewWidthRatio).to.equal(0.3);
  });

  it(@"should clamp if the page width ratio is out of bounds ", ^{
    auto pagingView = [[SPXPagingView alloc] init];
    pagingView.pageViewWidthRatio = 1.1;
    expect(pagingView.pageViewWidthRatio).to.equal(1.0);
  });

  it(@"should clamp if the page width ratio is negative", ^{
    auto pagingView = [[SPXPagingView alloc] init];
    pagingView.pageViewWidthRatio = -0.3;
    expect(pagingView.pageViewWidthRatio).to.equal(0);
  });
});

context(@"setting spcaing ratio", ^{
  it(@"should set the spacing ratio corrrectly ", ^{
    auto pagingView = [[SPXPagingView alloc] init];
    pagingView.spacingRatio = 0.3;
    expect(pagingView.spacingRatio).to.equal(0.3);
  });

  it(@"should clamp if the spacing ratio is out of bounds ", ^{
    auto pagingView = [[SPXPagingView alloc] init];
    pagingView.spacingRatio = 1.1;
    expect(pagingView.spacingRatio).to.equal(1.0);
  });

  it(@"should clamp if the spacing ratio is negative ", ^{
    auto pagingView = [[SPXPagingView alloc] init];
    pagingView.spacingRatio = -0.3;
    expect(pagingView.spacingRatio).to.equal(0);
  });
});

SpecEnd
