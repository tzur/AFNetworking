// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Lior Bar.

#import "CUIMenuItemModel.h"

SpecBegin(CUIMenuItemModel)

context(@"menu item model", ^{
  it(@"should init correctly", ^{
    NSURL *url = [[NSURL alloc] initWithString:@"http://hello.world"];
    CUIMenuItemModel *model = [[CUIMenuItemModel alloc] initWithLocalizedTitle:@"title" iconURL:url
                                                                           key:@"key"];
    expect(model.localizedTitle).to.equal(@"title");
    expect(model.iconURL).to.equal(url);
    expect(model.key).to.equal(@"key");
  });

  it(@"should deserialize correctly", ^{
    NSDictionary *dict = @{
      @"localizedTitle": @"title",
      @"iconURL": @"http://hello.world",
      @"key": @"key"
    };
    NSURL *expectedURL = [NSURL URLWithString:dict[@"iconURL"]];
    NSError *error;
    CUIMenuItemModel *model = [MTLJSONAdapter modelOfClass:CUIMenuItemModel.class
                                        fromJSONDictionary:dict error:&error];
    expect(error).to.beNil();
    expect(model).toNot.beNil();
    expect(model.localizedTitle).to.equal(@"title");
    expect(model.iconURL).to.equal(expectedURL);
    expect(model.key).to.equal(@"key");
  });
});

SpecEnd
