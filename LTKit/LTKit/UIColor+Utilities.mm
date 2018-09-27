// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "UIColor+Utilities.h"

#import <LTKit/LTCGExtensions.h>
#import <inttypes.h>

NS_ASSUME_NONNULL_BEGIN

@implementation UIColor (Utilities)

+ (UIColor *)lt_colorWithHex:(NSString *)hex {
  NSString *colorString = [hex characterAtIndex:0] == '#' ? [hex substringFromIndex:1] : hex;

  CGFloat alpha, red, blue, green;
  switch (colorString.length) {
    case 3: // #RGB.
      alpha = 1.0f;
      red = [self lt_colorComponentFrom:colorString start:0 length:1];
      green = [self lt_colorComponentFrom:colorString start:1 length:1];
      blue = [self lt_colorComponentFrom:colorString start:2 length:1];
      break;
    case 4: // #ARGB.
      alpha = [self lt_colorComponentFrom:colorString start:0 length:1];
      red = [self lt_colorComponentFrom:colorString start:1 length:1];
      green = [self lt_colorComponentFrom:colorString start:2 length:1];
      blue = [self lt_colorComponentFrom:colorString start:3 length:1];
      break;
    case 6: // #RRGGBB.
      alpha = 1.0f;
      red = [self lt_colorComponentFrom:colorString start:0 length:2];
      green = [self lt_colorComponentFrom:colorString start:2 length:2];
      blue = [self lt_colorComponentFrom:colorString start:4 length:2];
      break;
    case 8: // #AARRGGBB.
      alpha = [self lt_colorComponentFrom:colorString start:0 length:2];
      red = [self lt_colorComponentFrom:colorString start:2 length:2];
      green = [self lt_colorComponentFrom:colorString start:4 length:2];
      blue = [self lt_colorComponentFrom:colorString start:6 length:2];
      break;
    default:
      LTParameterAssert(NO, @"Given color value '%@' is invalid. It should be a hex value in one "
                        "of the forms: #RBG, #ARGB, #RRGGBB, or #AARRGGBB", hex);
      break;
  }

  return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
}

+ (CGFloat)lt_colorComponentFrom:(NSString *)string start:(NSUInteger)start
                          length:(NSUInteger)length {
  NSString *substring = [string substringWithRange:NSMakeRange(start, length)];
  NSString *fullHex = length == 2 ? substring :
      [NSString stringWithFormat:@"%@%@", substring, substring];

  unsigned int hexComponent;
  if (![[NSScanner scannerWithString:fullHex] scanHexInt:&hexComponent]) {
    LTParameterAssert(NO, @"Invalid hex digit given: %@", substring);
  }
  return hexComponent / 255.0;
}

- (NSString *)lt_hexString {
  static const uint8_t kMax = std::numeric_limits<uint8_t>::max();

  CGFloat r, g, b, a;
  uint8_t r8, g8, b8, a8;

  if ([self getRed:&r green:&g blue:&b alpha:&a]) {
    r8 = std::round(r * kMax);
    g8 = std::round(g * kMax);
    b8 = std::round(b * kMax);
    a8 = std::round(a * kMax);
  } else if ([self getWhite:&r alpha:&a]) {
    r8 = g8 = b8 = std::round(r * kMax);
    a8 = std::round(a * kMax);
  } else {
    LTAssert(NO, @"Invalid color for conversion: %@", self);
  }

  return [NSString stringWithFormat:@"#%02" PRIX8 "%02" PRIX8 "%02" PRIX8 "%02" PRIX8,
          a8, r8, g8, b8];
}

+ (UIColor *)lt_lerpColorFrom:(UIColor *)start to:(UIColor *)end parameter:(CGFloat)t {
  const CGFloat *startComponent = CGColorGetComponents(start.CGColor);
  const CGFloat *endComponent = CGColorGetComponents(end.CGColor);

  CGFloat startAlpha = CGColorGetAlpha(start.CGColor);
  CGFloat endAlpha = CGColorGetAlpha(end.CGColor);

  t = std::clamp(t, 0., 1.);

  CGFloat r = startComponent[0] + (endComponent[0] - startComponent[0]) * t;
  CGFloat g = startComponent[1] + (endComponent[1] - startComponent[1]) * t;
  CGFloat b = startComponent[2] + (endComponent[2] - startComponent[2]) * t;
  CGFloat a = startAlpha + (endAlpha - startAlpha) * t;

  return [UIColor colorWithRed:r green:g blue:b alpha:a];
}

@end

NS_ASSUME_NONNULL_END
