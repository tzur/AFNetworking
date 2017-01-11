// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "UIColor+Utilities.h"

SpecBegin(UIColor_Utilities)

context(@"hex to color", ^{
  it(@"should create UIColor with #RGB hex", ^{
    UIColor *color = [UIColor lt_colorWithHex:@"#963"];

    CGFloat red, green, blue, alpha;
    [color getRed:&red green:&green blue:&blue alpha:&alpha];

    expect(red).to.beCloseTo(0x99 / 255.f);
    expect(green).to.beCloseTo(0x66 / 255.f);
    expect(blue).to.beCloseTo(0x33 / 255.f);
    expect(alpha).to.beCloseTo(1.f);
  });

  it(@"should create UIColor with #ARGB hex", ^{
    UIColor *color = [UIColor lt_colorWithHex:@"#9963"];

    CGFloat red, green, blue, alpha;
    [color getRed:&red green:&green blue:&blue alpha:&alpha];

    expect(red).to.beCloseTo(0x99 / 255.f);
    expect(green).to.beCloseTo(0x66 / 255.f);
    expect(blue).to.beCloseTo(0x33 / 255.f);
    expect(alpha).to.beCloseTo(0x99 / 255.f);
  });

  it(@"should create UIColor with #RRGGBB hex", ^{
    UIColor *color = [UIColor lt_colorWithHex:@"#906F3A"];

    CGFloat red, green, blue, alpha;
    [color getRed:&red green:&green blue:&blue alpha:&alpha];

    expect(red).to.beCloseTo(0x90 / 255.f);
    expect(green).to.beCloseTo(0x6F / 255.f);
    expect(blue).to.beCloseTo(0x3A / 255.f);
    expect(alpha).to.beCloseTo(1.f);
  });

  it(@"should create UIColor with #AARRGGBB hex", ^{
    UIColor *color = [UIColor lt_colorWithHex:@"#7F906F3A"];

    CGFloat red, green, blue, alpha;
    [color getRed:&red green:&green blue:&blue alpha:&alpha];

    expect(red).to.beCloseTo(0x90 / 255.f);
    expect(green).to.beCloseTo(0x6F / 255.f);
    expect(blue).to.beCloseTo(0x3A / 255.f);
    expect(alpha).to.beCloseTo(0X7F / 255.f);
  });

  it(@"should raise on invalid value", ^{
    expect(^{
      [UIColor lt_colorWithHex:@"#77F906F3A"];
    }).to.raiseAny();
    expect(^{
      [UIColor lt_colorWithHex:@"#77F90"];
    }).to.raiseAny();
    expect(^{
      [UIColor lt_colorWithHex:@"#77"];
    }).to.raiseAny();
    expect(^{
      [UIColor lt_colorWithHex:@"7"];
    }).to.raiseAny();
    expect(^{
      [UIColor lt_colorWithHex:@"abcz"];
    }).to.raiseAny();
    expect(^{
      [UIColor lt_colorWithHex:@"##7799AA"];
    }).to.raiseAny();
    expect(^{
      [UIColor lt_colorWithHex:@""];
    }).to.raiseAny();
    expect(^{
      [UIColor lt_colorWithHex:@"#"];
    }).to.raiseAny();
  });
});

context(@"color to hex", ^{
  it(@"should return hex description of valid colors", ^{
    expect([[UIColor clearColor] lt_hexString]).to.equal(@"#00000000");
    expect([[UIColor blackColor] lt_hexString]).to.equal(@"#FF000000");
    expect([[UIColor whiteColor] lt_hexString]).to.equal(@"#FFFFFFFF");
    expect([[UIColor redColor] lt_hexString]).to.equal(@"#FFFF0000");
    expect([[UIColor greenColor] lt_hexString]).to.equal(@"#FF00FF00");
    expect([[UIColor blueColor] lt_hexString]).to.equal(@"#FF0000FF");
    expect([[UIColor colorWithWhite:1 alpha:0.5] lt_hexString]).to.equal(@"#80FFFFFF");
    expect([[UIColor colorWithWhite:0.5 alpha:1] lt_hexString]).to.equal(@"#FF808080");
  });
});

context(@"color interpolation", ^{
  it(@"should interpolate rgb color", ^{
    UIColor *start = [UIColor colorWithRed:0.25 green:0.5 blue:0.75 alpha:0.5];
    UIColor *end = [UIColor colorWithRed:0.75 green:0 blue:0.25 alpha:1];

    UIColor *result = [UIColor lt_lerpColorFrom:start to:end parameter:0.5];

    CGFloat red, green, blue, alpha;
    [result getRed:&red green:&green blue:&blue alpha:&alpha];

    expect(red).to.beCloseTo(0.5);
    expect(green).to.beCloseTo(0.25);
    expect(blue).to.beCloseTo(0.5);
    expect(alpha).to.beCloseTo(0.75);
  });
});

SpecEnd
