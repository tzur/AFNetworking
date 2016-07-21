// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Shachar Langbeheim.

#import "UIFont+Utilities.h"

SpecBegin(UIFont_Utilities)

context(@"wf_fontWithItalicTrait", ^{
  it(@"should add italic trait to font", ^{
    UIFont *font = [UIFont systemFontOfSize:10];

    UIFont *resultFont = font.wf_fontWithItalicTrait;

    expect(resultFont.fontDescriptor.symbolicTraits & UIFontDescriptorTraitItalic).to.beTruthy();
  });

  it(@"should maintain existing traits", ^{
    UIFont *font = [UIFont systemFontOfSize:10 weight:UIFontWeightSemibold];

    UIFont *resultFont = font.wf_fontWithItalicTrait;

    expect(resultFont.fontDescriptor.symbolicTraits & font.fontDescriptor.symbolicTraits)
        .to.equal(font.fontDescriptor.symbolicTraits);
  });

  it(@"should maintain font size", ^{
    CGFloat expectedFontSize = 11;
    UIFont *font = [UIFont systemFontOfSize:expectedFontSize];

    UIFont *resultFont = font.wf_fontWithItalicTrait;

    expect(resultFont.pointSize).to.equal(expectedFontSize);
  });
});

SpecEnd
