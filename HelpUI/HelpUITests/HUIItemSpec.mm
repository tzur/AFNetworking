// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Dekel Avrahami.

#import "HUIItem.h"

SpecBegin(HUIItem)

context(@"base", ^{
  __block NSError *error;

  it(@"should not deserialize without type", ^{
    NSDictionary *dict = @{};

    expect(^{
      [MTLJSONAdapter modelOfClass:HUIItem.class fromJSONDictionary:dict error:&error];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should not deserialize with wrong type", ^{
    NSDictionary *dict = @{@"type": @"no such type, yo"};

    expect(^{
      [MTLJSONAdapter modelOfClass:HUIItem.class fromJSONDictionary:dict error:&error];
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"text", ^{
  __block HUITextItem *item;
  __block NSError *error;
  __block NSDictionary *dict;

  beforeEach(^{
    dict = @{
      @"type": @"text",
      @"text": @"text1",
      @"associated_feature_item_titles": @[@"featureTitle"]
    };

    item = [MTLJSONAdapter modelOfClass:HUIItem.class fromJSONDictionary:dict error:&error];
  });

  it(@"should deserialize without errors", ^{
    expect(error).to.beNil();
  });

  it(@"should deserialize correctly", ^{
    expect(item.text).to.equal(@"text1");
    expect(item.associatedFeatureItemTitles).to.equal(@[@"featureTitle"]);
  });

  context(@"localization", ^{
    beforeEach(^{
      HUIModelSettings.localizationBlock = ^NSString * _Nullable(NSString *) {
        return @"text after localization";
      };
      item = [MTLJSONAdapter modelOfClass:HUIItem.class fromJSONDictionary:dict error:&error];
    });

    afterEach(^{
        HUIModelSettings.localizationBlock = nil;
    });

    it(@"should localize text with localizationBlock", ^{
      expect(item.text).to.equal(@"text after localization");
    });
  });
});

context(@"image", ^{
  __block HUIImageItem *item;
  __block NSError *error;
  __block NSDictionary *dict;

  beforeEach(^{
    dict = @{
      @"type": @"image",
      @"image": @"image1",
      @"title": @"title1",
      @"body": @"body1",
      @"icon_url": @"icon1",
      @"associated_feature_item_titles": @[@"featureTitle"]
    };

    item = [MTLJSONAdapter modelOfClass:HUIItem.class fromJSONDictionary:dict error:&error];
  });

  it(@"should deserialize without errors", ^{
    expect(error).to.beNil();
  });

  it(@"should deserialize correctly", ^{
    expect(item.image).to.equal(@"image1");
    expect(item.title).to.equal(@"title1");
    expect(item.body).to.equal(@"body1");
    expect(item.iconURL).to.equal([NSURL URLWithString:@"icon1"]);
    expect(item.associatedFeatureItemTitles).to.equal(@[@"featureTitle"]);
  });

  context(@"localization", ^{
    beforeEach(^{
      HUIModelSettings.localizationBlock = ^NSString * _Nullable(NSString *) {
        return @"text after localization";
      };
      item = [MTLJSONAdapter modelOfClass:HUIItem.class fromJSONDictionary:dict error:&error];
    });

    afterEach(^{
      HUIModelSettings.localizationBlock = nil;
    });

    it(@"should localize title and body with localizationBlock", ^{
      expect(item.title).to.equal(@"text after localization");
      expect(item.body).to.equal(@"text after localization");
    });
  });
});

context(@"video", ^{
  __block HUIVideoItem *item;
  __block NSError *error;
  __block NSDictionary *dict;

  beforeEach(^{
    dict = @{
      @"type": @"video",
      @"video": @"video1",
      @"title": @"title1",
      @"body": @"body1",
      @"icon_url": @"icon1",
    };

    item = [MTLJSONAdapter modelOfClass:HUIItem.class fromJSONDictionary:dict error:&error];
  });

  it(@"should deserialize without errors", ^{
    expect(error).to.beNil();
  });

  it(@"should deserialize correctly", ^{
    expect(item.video).to.equal(@"video1");
    expect(item.title).to.equal(@"title1");
    expect(item.body).to.equal(@"body1");
    expect(item.iconURL).to.equal([NSURL URLWithString:@"icon1"]);
  });

  context(@"localization", ^{
    beforeEach(^{
      HUIModelSettings.localizationBlock = ^NSString * _Nullable(NSString *) {
        return @"text after localization";
      };
      item = [MTLJSONAdapter modelOfClass:HUIItem.class fromJSONDictionary:dict error:&error];
    });

    afterEach(^{
      HUIModelSettings.localizationBlock = nil;
    });

    it(@"should localize title and body with localizationBlock", ^{
      expect(item.title).to.equal(@"text after localization");
      expect(item.body).to.equal(@"text after localization");
    });
  });
});

context(@"slideshow", ^{
  __block HUISlideshowItem *itemFade;
  __block NSError *errorFade;
  __block HUISlideshowItem *itemCurtain;
  __block NSError *errorCurtain;
  __block HUISlideshowItem *itemDefaultTransition;
  __block NSError *errorDefaultTransition;
  __block HUISlideshowItem *itemFadeDefaultDurations;
  __block NSError *errorFadeDefaultDurations;
  __block NSDictionary *dictDefaultTransition;

  beforeEach(^{
    NSDictionary *dictCurtain = @{
      @"type": @"slideshow",
      @"transition": @"curtain",
      @"images": @[@"image1", @"image2"],
      @"title": @"title1",
      @"body": @"body1",
      @"icon_url": @"icon1",
      @"still_duration": @1.5,
      @"transition_duration": @2.5,
    };

    NSDictionary *dictFade = @{
      @"type": @"slideshow",
      @"transition": @"fade",
      @"images": @[@"image1", @"image2"],
      @"title": @"title1",
      @"body": @"body1",
      @"icon_url": @"icon1",
      @"still_duration": @1.5,
      @"transition_duration": @2.5,
    };

    dictDefaultTransition = @{
      @"type": @"slideshow",
      @"images": @[@"image1", @"image2"],
      @"title": @"title1",
      @"body": @"body1",
      @"icon_url": @"icon1",
    };

    NSDictionary *dictFadeWithDefaultDurations = @{
      @"type": @"slideshow",
      @"transition": @"fade",
      @"images": @[@"image1", @"image2"],
      @"title": @"title1",
      @"body": @"body1",
      @"icon_url": @"icon1",
    };

    itemFade = [MTLJSONAdapter modelOfClass:HUIItem.class fromJSONDictionary:dictFade
                                      error:&errorFade];
    itemCurtain = [MTLJSONAdapter modelOfClass:HUIItem.class fromJSONDictionary:dictCurtain
                                         error:&errorCurtain];
    itemDefaultTransition = [MTLJSONAdapter modelOfClass:HUIItem.class
                                      fromJSONDictionary:dictDefaultTransition
                                                   error:&errorDefaultTransition];
    itemFadeDefaultDurations = [MTLJSONAdapter modelOfClass:HUIItem.class
                                         fromJSONDictionary:dictFadeWithDefaultDurations
                                                      error:&errorFadeDefaultDurations];
  });

  it(@"should deserialize without errors", ^{
    expect(errorFade).to.beNil();
    expect(errorCurtain).to.beNil();
    expect(errorDefaultTransition).to.beNil();
    expect(errorFadeDefaultDurations).to.beNil();
  });

  it(@"should deserialize slideshow item with fade transition correctly", ^{
    expect(itemFade.transition).to.equal(@(HUISlideshowTransitionFade));
    expect(itemFade.images).to.haveCountOf(2);
    expect(itemFade.images[0]).to.equal(@"image1");
    expect(itemFade.images[1]).to.equal(@"image2");
    expect(itemFade.title).to.equal(@"title1");
    expect(itemFade.body).to.equal(@"body1");
    expect(itemFade.iconURL).to.equal([NSURL URLWithString:@"icon1"]);
    expect(itemFade.stillDuration).to.beCloseTo(1.5);
    expect(itemFade.transitionDuration).to.beCloseTo(2.5);
  });

  it(@"should deserialize slideshow item with curtain transition correctly", ^{
    expect(itemCurtain.transition).to.equal(@(HUISlideshowTransitionCurtain));
    expect(itemCurtain.images).to.haveCountOf(2);
    expect(itemCurtain.images[0]).to.equal(@"image1");
    expect(itemCurtain.images[1]).to.equal(@"image2");
    expect(itemCurtain.title).to.equal(@"title1");
    expect(itemCurtain.body).to.equal(@"body1");
    expect(itemCurtain.iconURL).to.equal([NSURL URLWithString:@"icon1"]);
    expect(itemCurtain.stillDuration).to.beCloseTo(1.5);
    expect(itemCurtain.transitionDuration).to.beCloseTo(2.5);
  });

  it(@"should deserialize slideshow item with default transition correctly", ^{
    expect(itemDefaultTransition.transition).to.equal(@(HUISlideshowTransitionCurtain));
    expect(itemDefaultTransition.images).to.haveCountOf(2);
    expect(itemDefaultTransition.images[0]).to.equal(@"image1");
    expect(itemDefaultTransition.images[1]).to.equal(@"image2");
    expect(itemDefaultTransition.title).to.equal(@"title1");
    expect(itemDefaultTransition.body).to.equal(@"body1");
    expect(itemDefaultTransition.iconURL).to.equal([NSURL URLWithString:@"icon1"]);
    expect(itemDefaultTransition.stillDuration).to.beCloseTo(1.25);
    expect(itemDefaultTransition.transitionDuration).to.beCloseTo(1.25);
  });

  it(@"should deserialize slideshow item with fade transition and default durations correctly", ^{
    expect(itemFadeDefaultDurations.transition).to.equal(@(HUISlideshowTransitionFade));
    expect(itemFadeDefaultDurations.images).to.haveCountOf(2);
    expect(itemFadeDefaultDurations.images[0]).to.equal(@"image1");
    expect(itemFadeDefaultDurations.images[1]).to.equal(@"image2");
    expect(itemFadeDefaultDurations.title).to.equal(@"title1");
    expect(itemFadeDefaultDurations.body).to.equal(@"body1");
    expect(itemFadeDefaultDurations.iconURL).to.equal([NSURL URLWithString:@"icon1"]);
    expect(itemFadeDefaultDurations.stillDuration).to.beCloseTo(1.5);
    expect(itemFadeDefaultDurations.transitionDuration).to.beCloseTo(0.65);
  });

  it(@"should not deserialize incorrect transition", ^{
    __block NSError *error;
    NSDictionary *dict = @{@"type": @"slideshow", @"transition": @"straight to heaven"};

    expect(^{
      [MTLJSONAdapter modelOfClass:HUIItem.class fromJSONDictionary:dict error:&error];
    }).to.raise(@"NSInvalidArgumentException");
  });

  context(@"localization", ^{
    beforeEach(^{
      HUIModelSettings.localizationBlock = ^NSString * _Nullable(NSString *) {
        return @"text after localization";
      };
      itemDefaultTransition = [MTLJSONAdapter modelOfClass:HUIItem.class
                                        fromJSONDictionary:dictDefaultTransition
                                                     error:&errorDefaultTransition];
    });

    afterEach(^{
      HUIModelSettings.localizationBlock = nil;
    });

    it(@"should localize title and body with localizationBlock", ^{
      expect(itemDefaultTransition.title).to.equal(@"text after localization");
      expect(itemDefaultTransition.body).to.equal(@"text after localization");
    });
  });
});

SpecEnd
