// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Dekel Avrahami.

#import "HUIBoxTopLayout.h"

#import <LTKit/UIColor+Utilities.h>

SpecBegin(HUIBoxTopLayout)

// The minimal allowed height for \c HUIBoxTopView.
static const CGFloat kMinimalHeight = 75.;

// Arbitrary width that the tests set for the \c HUIBoxTopView.
static const CGFloat kBoxTopViewWidth = 335.34;

// Arbitrary content that fits in one line of \c HUIBoxTopView title.
static NSString * const kOneLineTitle = @"title";

// Arbitrary content that requires more than one line of \c HUIBoxTopView title.
static NSString * const kMultipleLinesTitle = @"title title title title title title title title \
title title title title title title title title title title";

// Arbitrary content that fits in three lines of \c HUIBoxTopView body.
static NSString * const kShortBody = @"Body body body body body.";

// Arbitrary content that requires more than three lines of \c HUIBoxTopView title.
static NSString * const kLongBody = @"Body body body body body body body body body body body body \
body body body body body body body body body body body body body body body body body body body \
body body body body body body body body body body body body body body body body body body.";

// The required ratio between vertical margin and body height of \c HUIBoxTopView.
static const CGFloat kBodyHeightMultiplierForVerticalMargin = 1.57;

// The minimal allowed vertical distance between top of \c HUIBoxTopView to the top of its content.
// Equal to the minimal allowed vertical distance between bottom of the content of \c HUIBoxTopView
// to the bottom of \c HUIBoxTopView.
static const CGFloat kMinimalVerticalMargin = 15.;

// The vertical distance from title to body.
static const CGFloat kTitleBodyDistance = 10.;

// The required ratio between icon height and \c lineHeight of the \c UIFont of the required font
// for the title of \c HUIBoxTopView.
static const CGFloat kTitleFontHeightMultiplierForIconHeight = 1.1;

// The required ratio between maximal allowed content width and \c bounds width of
// \c HUIBoxTopView.
static const CGFloat kBoundsWidthMultiplierForMaxContentWidth = 0.84;

// The required line spacing for the textual content (title and body) of \c HUIBoxTopView.
static const CGFloat kLineSpacing = 3.;

// The \c lineHeight of the \c UIFont of the required font for a single line title of
// \c HUIBoxTopView.
static const CGFloat kTitleFontHeight = 21.480469;

// The \c lineHeight of the \c UIFont of the required font for a multiple lines title of
// \c HUIBoxTopView.
static const CGFloat kDecreasedTitleFontHeight = 17.900391;

// The required ratio between horizontal distance from icon to title and \c lineHeight of the
// \c UIFont of the required font for the title of \c HUIBoxTopView.
static const CGFloat kTitleFontHeightMultiplierForIconTitleDistance = 0.22;

__block HUIBoxTopLayout *layout;

it(@"should have correct intrinsic height when has empty content", ^{
  CGRect bounds = CGRectMake(0, 0, kBoxTopViewWidth, 0);
  layout = [[HUIBoxTopLayout alloc] initWithBounds:bounds title:nil body:nil hasIcon:NO];

  expect(layout.intrinsicHeight).to.beCloseTo(kMinimalHeight);
});

context(@"content with title only (no icon and no body)", ^{
  __block CGRect bounds;

  beforeEach(^{
    bounds = CGRectMake(0, 0, kBoxTopViewWidth, kMinimalHeight);
    layout = [[HUIBoxTopLayout alloc] initWithBounds:bounds title:kOneLineTitle body:nil
                                             hasIcon:NO];
  });

  it(@"should have correct intrinsic height", ^{
    expect(layout.intrinsicHeight).to.beCloseTo(kMinimalHeight);
  });

  it(@"should have title with width smaller than or equal to maximal title width", ^{
    auto maximalWidth = bounds.size.width * kBoundsWidthMultiplierForMaxContentWidth;

    expect(layout.titleFrame.size.width).to.beGreaterThanOrEqualTo(0);
    expect(layout.titleFrame.size.width).to.beLessThanOrEqualTo(maximalWidth);
  });

  it(@"should have centered title", ^{
    auto expectedXCoordinate = 0.5 * (bounds.size.width - layout.titleFrame.size.width);
    auto expectedYCoordinate = 0.5 * (bounds.size.height - layout.titleFrame.size.height);

    expect(layout.titleFrame.origin.x).to.beCloseTo(expectedXCoordinate);
    expect(layout.titleFrame.origin.y).to.beCloseTo(expectedYCoordinate);
  });

  it(@"should have uppercase title", ^{
    expect(layout.titleAttributedString.string).to.equal([kOneLineTitle uppercaseString]);
  });

  it(@"should have same string attributes for the whole title", ^{
    NSRange wholeTitleRange = NSMakeRange(0, kOneLineTitle.length);
    NSRange sameAttributesRange;
    [layout.titleAttributedString attributesAtIndex:0 longestEffectiveRange:&sameAttributesRange
                                            inRange:wholeTitleRange];
    expect(sameAttributesRange.length).to.equal(wholeTitleRange.length);
  });

  it(@"should have correct title attributes", ^{
    auto attributes = [layout.titleAttributedString attributesAtIndex:0 effectiveRange:nil];
    auto font = (UIFont *)attributes[NSFontAttributeName];
    auto expectedFont = [UIFont systemFontOfSize:18. weight:UIFontWeightBold];
    auto expectedColor = [[UIColor lt_colorWithHex:@"#FFFFFF"] colorWithAlphaComponent:0.9];
    CGFloat expectedRed, expectedGreen, expectedBlue, expectedAlpha;
    [expectedColor getRed:&expectedRed green:&expectedGreen blue:&expectedBlue
                    alpha:&expectedAlpha];
    CGFloat actualRed, actualGreen, actualBlue, actualAlpha;
    auto actualColor = (UIColor *)attributes[NSForegroundColorAttributeName];
    [actualColor getRed:&actualRed green:&actualGreen blue:&actualBlue alpha:&actualAlpha];
    auto paragraphStyle = (NSParagraphStyle *)attributes[NSParagraphStyleAttributeName];

    expect(font.familyName).to.equal(expectedFont.familyName);
    expect(font.pointSize).to.beCloseTo(expectedFont.pointSize);
    expect(actualRed).to.beCloseTo(expectedRed);
    expect(actualGreen).to.beCloseTo(expectedGreen);
    expect(actualBlue).to.beCloseTo(expectedBlue);
    expect(actualAlpha).to.beCloseTo(expectedAlpha);
    expect(paragraphStyle.lineSpacing).to.beCloseTo(kLineSpacing);
    expect(paragraphStyle.alignment).to.equal(NSTextAlignmentCenter);
    expect(paragraphStyle.lineBreakMode).to.equal(NSLineBreakByWordWrapping);
  });

  it(@"should have decreased title font size when title has two lines", ^{
    layout = [[HUIBoxTopLayout alloc] initWithBounds:bounds title:kMultipleLinesTitle body:nil
                                             hasIcon:NO];
    auto attributes = [layout.titleAttributedString attributesAtIndex:0 effectiveRange:nil];
    auto font = (UIFont *)attributes[NSFontAttributeName];
    auto expectedFont = [UIFont systemFontOfSize:15. weight:UIFontWeightBold];

    expect(font.familyName).to.equal(expectedFont.familyName);
    expect(font.pointSize).to.beCloseTo(expectedFont.pointSize);
  });
});

context(@"content with body only (no icon and no title)", ^{
  __block CGRect bounds;

  beforeEach(^{
    bounds = CGRectMake(0, 0, kBoxTopViewWidth, kMinimalHeight);
    layout = [[HUIBoxTopLayout alloc] initWithBounds:bounds title:nil body:kShortBody hasIcon:NO];
  });

  it(@"should have correct intrinsic height", ^{
    expect(layout.intrinsicHeight).to.beCloseTo(kMinimalHeight);
  });

  it(@"should have centered body", ^{
    auto expectedXCoordinate = 0.5 * (bounds.size.width - layout.bodyFrame.size.width);
    auto expectedYCoordinate = 0.5 * (bounds.size.height - layout.bodyFrame.size.height);

    expect(layout.bodyFrame.origin.x).to.beCloseTo(expectedXCoordinate);
    expect(layout.bodyFrame.origin.y).to.beCloseTo(expectedYCoordinate);
  });

  it(@"should have body with width smaller than or equal to maximal width", ^{
    auto maximalWidth = bounds.size.width * kBoundsWidthMultiplierForMaxContentWidth;

    expect(layout.bodyFrame.size.width).to.beGreaterThanOrEqualTo(0);
    expect(layout.bodyFrame.size.width).to.beLessThanOrEqualTo(maximalWidth);
  });

  it(@"should have same string attributes for the whole body", ^{
    NSRange wholeBodyRange = NSMakeRange(0, kShortBody.length);
    NSRange sameAttributesRange;
    [layout.bodyAttributedString attributesAtIndex:0 longestEffectiveRange:&sameAttributesRange
                                            inRange:wholeBodyRange];
    expect(sameAttributesRange.length).to.equal(wholeBodyRange.length);
  });

  it(@"should have correct body attributes", ^{
    auto attributes = [layout.bodyAttributedString attributesAtIndex:0 effectiveRange:nil];
    auto font = (UIFont *)attributes[NSFontAttributeName];
    auto expectedFont = [UIFont systemFontOfSize:14. weight:UIFontWeightLight];
    auto expectedColor = [[UIColor lt_colorWithHex:@"#FFFFFF"] colorWithAlphaComponent:0.8];
    CGFloat expectedRed, expectedGreen, expectedBlue, expectedAlpha;
    [expectedColor getRed:&expectedRed green:&expectedGreen blue:&expectedBlue
                    alpha:&expectedAlpha];
    CGFloat actualRed, actualGreen, actualBlue, actualAlpha;
    auto actualColor = (UIColor *)attributes[NSForegroundColorAttributeName];
    [actualColor getRed:&actualRed green:&actualGreen blue:&actualBlue alpha:&actualAlpha];
    auto paragraphStyle = (NSParagraphStyle *)attributes[NSParagraphStyleAttributeName];

    expect(font.familyName).to.equal(expectedFont.familyName);
    expect(font.pointSize).to.beCloseTo(expectedFont.pointSize);
    expect(actualRed).to.beCloseTo(expectedRed);
    expect(actualGreen).to.beCloseTo(expectedGreen);
    expect(actualBlue).to.beCloseTo(expectedBlue);
    expect(actualAlpha).to.beCloseTo(expectedAlpha);
    expect(paragraphStyle.lineSpacing).to.beCloseTo(kLineSpacing);
    expect(paragraphStyle.alignment).to.equal(NSTextAlignmentCenter);
    expect(paragraphStyle.lineBreakMode).to.equal(NSLineBreakByWordWrapping);
  });
});

context(@"content with long body only (no icon and no title)", ^{
  __block CGRect bounds;

  beforeEach(^{
    bounds = CGRectMake(0, 0, kBoxTopViewWidth, kMinimalHeight);
    layout = [[HUIBoxTopLayout alloc] initWithBounds:bounds title:nil body:kLongBody hasIcon:NO];
  });

  it(@"should have correct intrinsic height", ^{
    auto bodyHeight = layout.bodyFrame.size.height;
    auto verticaMargin = 30;
    auto expectedHeight = bodyHeight + 2 * verticaMargin;

    expect(layout.intrinsicHeight).to.beCloseTo(expectedHeight);
  });

  it(@"should have decreased body font size", ^{
    layout = [[HUIBoxTopLayout alloc] initWithBounds:bounds title:nil body:kLongBody hasIcon:NO];
    auto attributes = [layout.bodyAttributedString attributesAtIndex:0 effectiveRange:nil];
    auto font = (UIFont *)attributes[NSFontAttributeName];
    auto expectedFont = [UIFont systemFontOfSize:10. weight:UIFontWeightBold];

    expect(font.familyName).to.equal(expectedFont.familyName);
    expect(font.pointSize).to.beCloseTo(expectedFont.pointSize);
  });

  it(@"should have body with width smaller than or equal to maximal width", ^{
    layout = [[HUIBoxTopLayout alloc] initWithBounds:bounds title:nil body:kLongBody hasIcon:NO];
    auto maximalWidth = bounds.size.width * kBoundsWidthMultiplierForMaxContentWidth;

    expect(layout.bodyFrame.size.width).to.beGreaterThanOrEqualTo(0);
    expect(layout.bodyFrame.size.width).to.beLessThanOrEqualTo(maximalWidth);
  });
});

context(@"content with icon only (no body and no title)", ^{
  __block CGRect bounds;

  beforeEach(^{
    bounds = CGRectMake(0, 0, kBoxTopViewWidth, kMinimalHeight);
    layout = [[HUIBoxTopLayout alloc] initWithBounds:bounds title:nil body:nil hasIcon:YES];
  });

  it(@"should have correct intrinsic height", ^{
    expect(layout.intrinsicHeight).to.beCloseTo(kMinimalHeight);
  });

  it(@"should have centered icon", ^{
    auto expectedXCoordinate = 0.5 * (bounds.size.width - layout.iconFrame.size.width);
    auto expectedYCoordinate = 0.5 * (bounds.size.height - layout.iconFrame.size.height);

    expect(layout.iconFrame.origin.x).to.beCloseTo(expectedXCoordinate);
    expect(layout.iconFrame.origin.y).to.beCloseTo(expectedYCoordinate);
  });

  it(@"should have correct icon size", ^{
    auto expectedHeight = kTitleFontHeightMultiplierForIconHeight * kTitleFontHeight;

    expect(layout.iconFrame.size.width).to.beCloseTo(expectedHeight);
    expect(layout.iconFrame.size.width).to.beCloseTo(layout.iconFrame.size.height);
  });
});

context(@"content with icon and one line title (no body)", ^{
  __block CGRect bounds;

  beforeEach(^{
    bounds = CGRectMake(0, 0, kBoxTopViewWidth, kMinimalHeight);
    layout = [[HUIBoxTopLayout alloc] initWithBounds:bounds title:kOneLineTitle body:nil
                                             hasIcon:YES];
  });

  it(@"should have correct intrinsic height", ^{
    expect(layout.intrinsicHeight).to.beCloseTo(kMinimalHeight);
  });

  it(@"should have width smaller than or equal to maximal width", ^{
    auto iconToTitleDistance = kTitleFontHeightMultiplierForIconTitleDistance * kTitleFontHeight;
    auto width = layout.iconFrame.size.width + iconToTitleDistance + layout.titleFrame.size.width;
    auto maximalWidth = bounds.size.width * kBoundsWidthMultiplierForMaxContentWidth;

    expect(width).to.beGreaterThanOrEqualTo(0);
    expect(width).to.beLessThanOrEqualTo(maximalWidth);
  });

  it(@"should have vertically centered icon", ^{
    auto expectedYCoordinate = 0.5 * (bounds.size.height - layout.iconFrame.size.height);

    expect(layout.iconFrame.origin.y).to.beCloseTo(expectedYCoordinate);
  });

  it(@"should have correct icon size", ^{
    auto expectedHeight = kTitleFontHeightMultiplierForIconHeight * kTitleFontHeight;

    expect(layout.iconFrame.size.width).to.beCloseTo(expectedHeight);
    expect(layout.iconFrame.size.width).to.beCloseTo(layout.iconFrame.size.height);
  });

  it(@"should have title in correct vertical position", ^{
    auto iconHeight = layout.iconFrame.size.height;
    auto iconTopToTitleTopDistance = 0.5 * (iconHeight - kTitleFontHeight);
    auto expectedYCoordinate = layout.iconFrame.origin.y + iconTopToTitleTopDistance;

    expect(layout.titleFrame.origin.y).to.beCloseTo(expectedYCoordinate);
  });

  it(@"should have correct horizontal layout", ^{
    auto iconToTitleDistance = kTitleFontHeightMultiplierForIconTitleDistance * (kTitleFontHeight);
    auto width = layout.iconFrame.size.width + iconToTitleDistance + layout.titleFrame.size.width;
    auto expectedIconX = 0.5 * (bounds.size.width - width);
    auto expectedTitleX = expectedIconX + layout.iconFrame.size.width + iconToTitleDistance;

    expect(layout.iconFrame.origin.x).to.beCloseTo(expectedIconX);
    expect(layout.titleFrame.origin.x).to.beCloseTo(expectedTitleX);
  });
});

context(@"content with icon and two lines title (no body)", ^{
  __block CGRect bounds;

  beforeEach(^{
    bounds = CGRectMake(0, 0, kBoxTopViewWidth, kMinimalHeight);
    layout = [[HUIBoxTopLayout alloc] initWithBounds:bounds title:kMultipleLinesTitle body:nil
                                             hasIcon:YES];
  });

  it(@"should have correct intrinsic height", ^{
    auto titleHeight = layout.titleFrame.size.height;
    auto expectedHeight = 2 * kMinimalVerticalMargin + titleHeight;

    expect(layout.intrinsicHeight).to.beCloseTo(expectedHeight);
  });

  it(@"should have width smaller than or equal to maximal width", ^{
    auto iconToTitleDistance =
        kTitleFontHeightMultiplierForIconTitleDistance * kDecreasedTitleFontHeight;
    auto width = layout.iconFrame.size.width + iconToTitleDistance + layout.titleFrame.size.width;
    auto maximalWidth = bounds.size.width * kBoundsWidthMultiplierForMaxContentWidth;

    expect(width).to.beGreaterThanOrEqualTo(0);
    expect(width).to.beLessThanOrEqualTo(maximalWidth);
  });

  it(@"should have correct icon size", ^{
    auto expectedHeight = kTitleFontHeightMultiplierForIconHeight * kDecreasedTitleFontHeight;

    expect(layout.iconFrame.size.width).to.beCloseTo(expectedHeight);
    expect(layout.iconFrame.size.width).to.beCloseTo(layout.iconFrame.size.height);
  });

  it(@"should have correct vertical layout", ^{
    auto iconHeight = layout.iconFrame.size.height;
    auto titleHeight = layout.titleFrame.size.height;
    auto expectedTitleY = kMinimalVerticalMargin;
    auto expectedIconY = kMinimalVerticalMargin + (titleHeight - iconHeight) / 2.;

    expect(layout.titleFrame.origin.y).to.beCloseTo(expectedTitleY);
    expect(layout.iconFrame.origin.y).to.beCloseTo(expectedIconY);
  });

  it(@"should have correct horizontal layout", ^{
    auto iconToTitleDistance = 4;
    auto width = layout.iconFrame.size.width + iconToTitleDistance + layout.titleFrame.size.width;
    auto expectedIconX = 0.5 * (bounds.size.width - width);
    auto expectedTitleX = expectedIconX + layout.iconFrame.size.width + iconToTitleDistance;

    expect(layout.iconFrame.origin.x).to.beCloseTo(expectedIconX);
    expect(layout.titleFrame.origin.x).to.beCloseTo(expectedTitleX);
  });
});

context(@"content with title and body (no icon)", ^{
  __block CGRect bounds;
  __block CGFloat titleLineHeight;
  __block CGFloat bodyHeight;
  __block CGFloat verticaMargin;

  beforeEach(^{
    bounds = CGRectMake(0, 0, kBoxTopViewWidth, kMinimalHeight);
    layout = [[HUIBoxTopLayout alloc] initWithBounds:bounds title:kOneLineTitle body:kShortBody
                                             hasIcon:NO];

    titleLineHeight = layout.titleFrame.size.height;
    bodyHeight = layout.bodyFrame.size.height;
    verticaMargin = kBodyHeightMultiplierForVerticalMargin * bodyHeight;
  });

  it(@"should have correct intrinsic height", ^{
    auto expectedHeight = titleLineHeight + kTitleBodyDistance + bodyHeight + 2 * verticaMargin;

    expect(layout.intrinsicHeight).to.beCloseTo(expectedHeight);
  });

  it(@"should have correct vertical layout", ^{
    auto expextedBodyY = verticaMargin + titleLineHeight + kTitleBodyDistance;

    expect(layout.titleFrame.origin.y).to.beCloseTo(verticaMargin);
    expect(layout.bodyFrame.origin.y).to.beCloseTo(expextedBodyY);
  });
});

context(@"content with icon, title and body", ^{
  __block CGRect bounds;
  __block CGFloat titleLineHeight;
  __block CGFloat bodyHeight;
  __block CGFloat verticaMargin;

  beforeEach(^{
    bounds = CGRectMake(0, 0, kBoxTopViewWidth, kMinimalHeight);
    layout = [[HUIBoxTopLayout alloc] initWithBounds:bounds title:kOneLineTitle body:kShortBody
                                             hasIcon:YES];
    titleLineHeight = layout.iconFrame.size.height;
    bodyHeight = layout.bodyFrame.size.height;
    verticaMargin = kBodyHeightMultiplierForVerticalMargin * bodyHeight;
  });

  it(@"should have correct intrinsic height", ^{
    auto expectedHeight = titleLineHeight + kTitleBodyDistance + bodyHeight + 2 * verticaMargin;

    expect(layout.intrinsicHeight).to.beCloseTo(expectedHeight);
  });

  it(@"should have correct vertical layout", ^{
    auto expextedBodyY = verticaMargin + titleLineHeight + kTitleBodyDistance;

    expect(layout.iconFrame.origin.y).to.beCloseTo(verticaMargin);
    expect(layout.bodyFrame.origin.y).to.beCloseTo(expextedBodyY);
  });
});

context(@"content with icon, two lines title and body", ^{
  __block CGRect bounds;
  __block CGFloat titleHeight;
  __block CGFloat bodyHeight;
  __block CGFloat verticaMargin;

  beforeEach(^{
    bounds = CGRectMake(0, 0, kBoxTopViewWidth, kMinimalHeight);
    layout = [[HUIBoxTopLayout alloc] initWithBounds:bounds title:kMultipleLinesTitle
                                                body:kShortBody hasIcon:YES];

    titleHeight = layout.titleFrame.size.height;
    bodyHeight = layout.bodyFrame.size.height;
    verticaMargin = kBodyHeightMultiplierForVerticalMargin * bodyHeight;
  });

  it(@"should have correct intrinsic height", ^{
    auto expectedHeight = titleHeight + kTitleBodyDistance + bodyHeight + 2 * verticaMargin;

    expect(layout.intrinsicHeight).to.beCloseTo(expectedHeight);
  });

  it(@"should have correct vertical layout", ^{
    auto expextedBodyY = verticaMargin + titleHeight + kTitleBodyDistance;

    expect(layout.titleFrame.origin.y).to.beCloseTo(verticaMargin);
    expect(layout.bodyFrame.origin.y).to.beCloseTo(expextedBodyY);
  });
});

SpecEnd
