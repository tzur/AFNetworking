// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

@class LTVGGlyph, LTVGLines;

/// Class providing typsetting functionality.
@interface LTVGTypesetter : NSObject

/// Creates an \c LTVGLines object representing the path information of the provided
/// \c attributedString.
+ (LTVGLines *)linesFromAttributedString:(NSAttributedString *)attributedString;

/// Creates an \c LTVGGlyph with the default path representing the glyph at the given \c index in
/// the glyph table of the given \c font, translated by the given \c baselineOrigin. The given
/// \c font must not be \c nil.
+ (LTVGGlyph *)glyphWithIndex:(CGGlyph)index font:(UIFont *)font
               baselineOrigin:(CGPoint)baselineOrigin;

@end
