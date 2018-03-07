// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Dekel Avrahami.

#import "HUIBoxTopLayout.h"

NS_ASSUME_NONNULL_BEGIN

@interface HUIBoxTopLayout ()

/// Calculated size for the title of the \c HUIBoxTopView.
@property (readwrite, nonatomic) CGSize titleSize;

/// Calculated size for the icon of the \c HUIBoxTopView.
@property (readwrite, nonatomic) CGSize iconSize;

/// Calculated size for the body of the \c HUIBoxTopView.
@property (readwrite, nonatomic) CGSize bodySize;

/// Attributed string for the title of the \c HUIBoxTopView.
@property (readwrite, nonatomic) NSAttributedString *titleAttributedString;

/// Attributed string for the body of the \c HUIBoxTopView.
@property (readwrite, nonatomic) NSAttributedString *bodyAttributedString;

/// Bounds of the \c HUIBoxTopView.
@property (readonly, nonatomic) CGRect bounds;

/// Text of the title of the \c HUIBoxTopView.
@property (readonly, nonatomic, nullable) NSString *titleText;

/// Text of the body of the \c HUIBoxTopView.
@property (readonly, nonatomic, nullable) NSString *bodyText;

/// \c YES if the \c HUIBoxTopView has an icon
@property (readonly, nonatomic) BOOL hasIcon;

@end

@implementation HUIBoxTopLayout

/// The preferred font size for the title. Will be used unless title longer than one line and in
/// this case font will be reduced to try and fit one line.
static const CGFloat kTitlePreferredFontSize = 18.;

/// The preferred font size for the body. Will be used unless title longer than three lines and in
/// this case font will be reduced to try and fit three lines.
static const CGFloat kBodyPreferredFontSize = 14.;

- (instancetype)initWithBounds:(CGRect)bounds title:(nullable NSString *)title
                          body:(nullable NSString *)body hasIcon:(BOOL)hasIcon{
  if (self = [super init]) {
    _bounds = bounds;
    _titleText = [title uppercaseString];
    _bodyText = body;
    _hasIcon = hasIcon;
    self.titleSize = CGSizeNull;
    self.iconSize = CGSizeNull;
    self.bodySize = CGSizeNull;
    [self setupLayout];
  }
  return self;
}

- (void)setupLayout {
  [self setupBodyAttributedStringAndSize];
  [self setupTitleAttributedStringAndSize];
  [self setupIconSize];
  [self setupIntrinsicHeight];
  [self setupIconFrame];
  [self setupTitleFrame];
  [self setupBodyFrame];
}

- (void)setupBodyAttributedStringAndSize {
  auto bodyAttributes = @{
    NSForegroundColorAttributeName: [HUISettings instance].topBoxBodyColor,
    NSParagraphStyleAttributeName: [HUIBoxTopLayout paragraphStyle],
    NSFontAttributeName: [HUIBoxTopLayout preferredBodyFont]
  };

  if (!self.bodyText) {
    self.bodyAttributedString = [[NSAttributedString alloc] initWithString:@""
                                                                attributes:bodyAttributes];
    self.bodySize = CGSizeZero;
    return;
  }

  auto minFontSize = 10;
  auto maxFontSize = (NSUInteger)kBodyPreferredFontSize;
  auto fontSizeRange = NSMakeRange(minFontSize, maxFontSize - minFontSize + 1);
  [self enumerateAttributedStringsForText:nn(self.bodyText) attributes:bodyAttributes
                            fontSizeRange:fontSizeRange
                               usingBlock:^(NSAttributedString *attributedString,
                                            CGSize boundingRectSize, BOOL *stop) {
    self.bodyAttributedString = attributedString;
    self.bodySize = CGSizeMake(boundingRectSize.width, boundingRectSize.height);
    *stop = boundingRectSize.height <= [HUIBoxTopLayout maxBodyHeight];
  }];
}

+ (UIFont *)preferredBodyFont {
  return [UIFont systemFontOfSize:kBodyPreferredFontSize
                           weight:[HUISettings instance].topBoxBodyFontWeight];
}

+ (NSParagraphStyle *)paragraphStyle {
  auto paragraphStyle = [[NSMutableParagraphStyle alloc] init];
  paragraphStyle.alignment = NSTextAlignmentCenter;
  paragraphStyle.lineSpacing = 3;
  paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
  return [paragraphStyle copy];
}

// Invoks the given \c block for each font size in \c fontSizeRange or until the block assigns
// \c YES to the \c stop output parameter. The \c attributedString that is passed to the block as
// input parameter is created with the given \c text and \c initialAttributes, and the
// \c NSFontAttributeName of it is changed each iteration to font with the current size. In addition
// the \c boundingRectSize that is the needed size to present this attributed string in this view is
// also given to the block.
- (void)enumerateAttributedStringsForText:(NSString *)text
    attributes:(NSDictionary<NSString *, id> *)initialAttributes
    fontSizeRange:(NSRange)fontSizeRange
    usingBlock:(void(^)(NSAttributedString *attributedString, CGSize boundingRectSize,
                        BOOL *stop))block {
  auto fontSizes = [NSIndexSet indexSetWithIndexesInRange:fontSizeRange];
  [fontSizes enumerateIndexesWithOptions:NSEnumerationReverse usingBlock:^(NSUInteger fontSize,
                                                                           BOOL *stop) {
    auto attributes = [initialAttributes mutableCopy];
    auto font = (UIFont *)attributes[NSFontAttributeName];
    LTAssert(font, @"attributes does not contain font");
    attributes[NSFontAttributeName] = [font fontWithSize:fontSize];
    CGSize widthConstraint = CGSizeMake([self contentMaxWidth], NSUIntegerMax);
    auto boundingRect = [text boundingRectWithSize:widthConstraint
                                           options:NSStringDrawingUsesLineFragmentOrigin
                                        attributes:attributes context:nil];
    auto attributedString = [[NSAttributedString alloc] initWithString:text attributes:attributes];
    block(attributedString, boundingRect.size, stop);
  }];
}

- (CGFloat)contentMaxWidth {
  return  self.bounds.size.width * 0.84;
}

+ (CGFloat)maxBodyHeight {
  auto maxBodyFontHeight = ((UIFont *)[HUIBoxTopLayout preferredBodyFont]).lineHeight;
  auto lineSpacing = [HUIBoxTopLayout paragraphStyle].lineSpacing;
  return 3 * (maxBodyFontHeight + lineSpacing) + 1;
}

- (void)setupTitleAttributedStringAndSize {
  auto titleAttributes = @{
    NSForegroundColorAttributeName: [HUISettings instance].topBoxTitleColor,
    NSParagraphStyleAttributeName: [HUIBoxTopLayout paragraphStyle],
    NSFontAttributeName: [HUIBoxTopLayout preferredTitleFont]
  };

  if (!self.titleText) {
    self.titleAttributedString = [[NSAttributedString alloc] initWithString:@""
                                                                 attributes:titleAttributes];
    self.titleSize = CGSizeZero;
    return;
  }

  auto minFontSize = 15;
  auto maxFontSize = (NSUInteger)kTitlePreferredFontSize;
  auto fontSizeRange = NSMakeRange(minFontSize, maxFontSize - minFontSize + 1);
  [self enumerateAttributedStringsForText:nn(self.titleText) attributes:titleAttributes
                            fontSizeRange:fontSizeRange
                               usingBlock:^(NSAttributedString *attributedString,
                                            CGSize boundingRectSize, BOOL *stop) {
    self.titleAttributedString = attributedString;
    self.titleSize = CGSizeMake(boundingRectSize.width, boundingRectSize.height);
    *stop = self.titleSize.height <= [HUIBoxTopLayout maxTitleHeight] &&
            [self titleLineWidth] <= [self contentMaxWidth];
  }];

  while ([self titleLineWidth] > [self contentMaxWidth]) {
    self.titleSize = CGSizeMake(self.titleSize.width - 1., self.titleSize.height);
  }
}

+ (UIFont *)preferredTitleFont {
  return [UIFont systemFontOfSize:kTitlePreferredFontSize
                           weight:[HUISettings instance].topBoxTitleFontWeight];
}

+ (CGFloat)maxTitleHeight {
  auto maxTitleFontHeight = ((UIFont *)[HUIBoxTopLayout preferredTitleFont]).lineHeight;
  auto lineSpacing = [HUIBoxTopLayout paragraphStyle].lineSpacing;
  return maxTitleFontHeight + lineSpacing + 1;
}

- (CGFloat)titleLineWidth {
  [self assertTitleSizeInitialized];
  return [self iconWidth] + [self iconToTitleDistance] + self.titleSize.width;
}

- (void)assertTitleSizeInitialized {
  LTAssert(!CGSizeIsNull(self.titleSize), @"titleSize was not initialized");
}

- (CGFloat)iconWidth {
  auto iconWidth = 0.;
  if (self.hasIcon) {
    iconWidth = [self titleFontHeight] * 1.1;
  }
  return iconWidth;
}

- (CGFloat)titleFontHeight {
  [self assertTitleAttributedStringInitialized];
  auto titleFont = [HUIBoxTopLayout preferredTitleFont];
  if (self.titleAttributedString.string.length) {
    auto titleAttributes = [self.titleAttributedString attributesAtIndex:0 effectiveRange:nil];
    titleFont = (UIFont *)titleAttributes[NSFontAttributeName];
  }
  return titleFont.lineHeight;
}

- (void)assertTitleAttributedStringInitialized {
  LTAssert(self.titleAttributedString, @"titleAttributedString was not initialized");
}

- (CGFloat)iconToTitleDistance {
  auto margin = 0.;
  if (self.hasIcon && self.titleText.length) {
    margin = std::max(4., [self titleFontHeight] * 0.22);
  }
  return margin;
}

- (void)setupIconSize {
  auto width = [self iconWidth];
  auto height = width;
  self.iconSize = CGSizeMake(width, height);
}

- (void)setupIntrinsicHeight {
  _intrinsicHeight = [self contentHeight] + 2 * [self verticalMargin];
}

- (CGFloat)contentHeight {
  [self assertBodySizeInitialized];
  return [self titleLineHeight] + [self titleLineToBodyDistance] + self.bodySize.height;
}

- (void)assertBodySizeInitialized {
  LTAssert(!CGSizeIsNull(self.bodySize), @"bodySize was not initialized");
}

- (CGFloat)titleLineHeight {
  [self assertTitleSizeInitialized];
  [self assertIconSizeInitialized];
  return std::max(self.titleSize.height, self.iconSize.height);
}

- (void) assertIconSizeInitialized{
  LTAssert(!CGSizeIsNull(self.iconSize), @"iconSize was not initialized");
}

- (CGFloat)titleLineToBodyDistance {
  return ((!self.titleText.length && !self.hasIcon) || !self.bodyText.length) ? 0. : 10.;
}

- (CGFloat)verticalMargin {
  [self assertBodySizeInitialized];
  auto margin = std::clamp(1.57 * self.bodySize.height, 15., 30.);
  return std::max(margin, CGFloat((75 - [self contentHeight]) / 2.));
}

- (void)setupIconFrame {
  [self assertIconSizeInitialized];
  [self assertTitleSizeInitialized];
  auto titleLineOrigin = [self titleLineOrigin];
  auto y = titleLineOrigin.y + std::max((self.titleSize.height - self.iconSize.height) / 2., 0.);
  _iconFrame = CGRectMake(titleLineOrigin.x, y, self.iconSize.width, self.iconSize.height);
}

- (CGPoint)titleLineOrigin {
  CGFloat x = [self minimalXCoordinate] + ([self contentMaxWidth] - [self titleLineWidth]) / 2.;
  CGFloat y = self.bounds.origin.y + [self verticalMargin];
  return CGPointMake(x,y);
}

- (CGFloat)minimalXCoordinate {
  return self.bounds.origin.x + (self.bounds.size.width - [self contentMaxWidth]) / 2.;
}

- (void)setupTitleFrame {
  [self assertIconSizeInitialized];
  [self assertTitleSizeInitialized];
  auto titleLineOrigin = [self titleLineOrigin];
  auto x = titleLineOrigin.x + self.iconSize.width + [self iconToTitleDistance];
  auto y = titleLineOrigin.y + std::max((self.iconSize.height - self.titleSize.height) / 2., 0.);
  _titleFrame = CGRectMake(x, y, self.titleSize.width, self.titleSize.height);
}

- (void)setupBodyFrame {
  [self assertBodySizeInitialized];
  auto x = [self minimalXCoordinate] + ([self contentMaxWidth] - self.bodySize.width) / 2.;
  auto y = [self titleLineOrigin].y + [self titleLineHeight] + [self titleLineToBodyDistance];
  _bodyFrame = CGRectMake(x, y, self.bodySize.width, self.bodySize.height);
}

@end

NS_ASSUME_NONNULL_END
