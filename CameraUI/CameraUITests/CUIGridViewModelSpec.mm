// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Nir Bruner.

#import "CUIGridViewModel.h"

@interface CUIFakeGridContainer : NSObject <CUIGridContainer>
@end

@implementation CUIFakeGridContainer
@synthesize gridHidden = _gridHidden;
@end

SpecBegin(CUIGridViewModel)

__block CUIGridViewModel *gridViewModel;
__block id<CUIGridContainer> gridContainer;
__block NSString *title;
__block NSURL *iconURL;

beforeEach(^{
  gridContainer = [[CUIFakeGridContainer alloc] init];
  title = @"foo";
  iconURL = [NSURL URLWithString:@"http://some.url"];
  gridViewModel = [[CUIGridViewModel alloc] initWithGridContainer:gridContainer title:title
                                                          iconURL:iconURL];
});

context(@"initialization", ^{
  it(@"should set correct defaults", ^{
    expect(gridViewModel.enabled).will.beTruthy();
    expect(gridViewModel.hidden).to.beFalsy();
    expect(gridViewModel.subitems).to.beNil();
  });

  it(@"should set values from initializer", ^{
    expect(gridViewModel.title).to.equal(title);
    expect(gridViewModel.iconURL).to.equal(iconURL);
  });
});

context(@"enabledSignal", ^{
  it(@"should update the enabled property", ^{
    RACSubject *enabledSignal = [[RACSubject alloc] init];
    gridViewModel.enabledSignal = enabledSignal;
    expect(gridViewModel.enabled).to.beTruthy();

    [enabledSignal sendNext:@NO];
    expect(gridViewModel.enabled).will.beFalsy();

    [enabledSignal sendNext:@YES];
    expect(gridViewModel.enabled).will.beTruthy();
  });
});

context(@"didTap", ^{
  beforeEach(^{
    gridContainer.gridHidden = YES;
  });

  it(@"should toggle grid visibility", ^{
    expect(gridContainer.gridHidden).to.beTruthy();
    [gridViewModel didTap];
    expect(gridContainer.gridHidden).to.beFalsy();
  });

  it(@"should set selectedness according to visibility", ^{
    expect(gridViewModel.selected).to.beFalsy();
    gridContainer.gridHidden = NO;
    expect(gridViewModel.selected).to.beTruthy();
  });
});

SpecEnd
