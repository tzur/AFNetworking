// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Shachar Langbeheim.

#import "UIFont+Utilities.h"

NS_ASSUME_NONNULL_BEGIN

@implementation UIFont (Utilities)

- (UIFont *)wf_fontWithItalicTrait {
  UIFontDescriptor *descriptor = [self.fontDescriptor fontDescriptorWithSymbolicTraits:
                                  UIFontDescriptorTraitItalic | self.fontDescriptor.symbolicTraits];
  return [UIFont fontWithDescriptor:descriptor size:0];
}

@end

NS_ASSUME_NONNULL_END
