// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTUErrorViewProvider.h"

SpecBegin(PTUErrorViewProvider)

__block NSError *error;
__block NSError *otherError;
__block NSURL *url;
__block NSURL *otherUrl;

beforeEach(^{
  error = [NSError lt_errorWithCode:1337];
  otherError = [NSError lt_errorWithCode:1338];
  url = [NSURL URLWithString:@"http://www.foo.bar"];
  otherUrl = [NSURL URLWithString:@"http://www.foo.bar/baz"];
});

context(@"block initializer", ^{
  __block NSError *providedError;
  __block NSURL *providedURL;
  __block UIView *returnView;

  it(@"should invoke block for every view request", ^{
    PTUErrorViewProvider *errorViewProvider = [[PTUErrorViewProvider alloc]
                                               initWithBlock:^UIView *(NSError *error,
                                                                       NSURL *url) {
      providedError = error;
      providedURL = url;
      return returnView;
    }];
    returnView = [[UIView alloc] init];

    expect([errorViewProvider errorViewForError:error associatedURL:url]).to.equal(returnView);
    expect(providedError).to.equal(error);
    expect(providedURL).to.equal(url);

    returnView = [[UIView alloc] init];
    expect([errorViewProvider errorViewForError:otherError associatedURL:otherUrl])
        .to.equal(returnView);
    expect(providedError).to.equal(otherError);
    expect(providedURL).to.equal(otherUrl);

    returnView = [[UIView alloc] init];
    expect([errorViewProvider errorViewForError:error associatedURL:nil])
        .to.equal(returnView);
    expect(providedError).to.equal(error);
    expect(providedURL).to.beNil();
  });
});

context(@"view initializer", ^{
  it(@"should return the same view for every request", ^{
    UIView *returnView = [[UIView alloc] init];
    PTUErrorViewProvider *errorViewProvider = [[PTUErrorViewProvider alloc]
                                               initWithView:returnView];

    expect([errorViewProvider errorViewForError:error associatedURL:url]).to.equal(returnView);
    expect([errorViewProvider errorViewForError:error associatedURL:otherUrl]).to.equal(returnView);
    expect([errorViewProvider errorViewForError:error associatedURL:nil]).to.equal(returnView);
    expect([errorViewProvider errorViewForError:otherError associatedURL:url]).to.equal(returnView);
    expect([errorViewProvider errorViewForError:otherError associatedURL:otherUrl])
        .to.equal(returnView);
    expect([errorViewProvider errorViewForError:otherError associatedURL:nil]).to.equal(returnView);
  });
});

SpecEnd
