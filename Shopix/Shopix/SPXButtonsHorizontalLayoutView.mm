// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "SPXButtonsHorizontalLayoutView.h"

NS_ASSUME_NONNULL_BEGIN

@interface SPXButtonsHorizontalLayoutView ()

/// Stack view holding all the \c buttons as arranged subviews.
@property (nonatomic, readonly) UIStackView *buttonsStackView;

/// Signal that sends the pressed button index, this signal will change whenever \c buttons are
/// changed. \c buttonPressed values are sent by the latest signal assigned to this property.
@property (strong, nonatomic) RACSignal<NSNumber *> *innerButtonPressedSignal;

@end

@implementation SPXButtonsHorizontalLayoutView

/// Enlarged button height ratio over the stack view height.
static const CGFloat kEnlargedButtonHeightRatio = 1.0;

/// Button height ratio over the stack view height.
static const CGFloat kButtonHeightRatio = 0.861;

/// Default spacing ratio between the buttons.
static const CGFloat kDefaultSpacingRatio = 0.058;

/// Default button width ratio over its height.
static const CGFloat kDefaultButtonAspectRatio = 1.0;

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithFrame:(CGRect)frame {
  if (self = [super initWithFrame:frame]) {
    _buttons = @[];
    _innerButtonPressedSignal = [RACSignal never];
    _buttonPressed = [RACObserve(self, innerButtonPressedSignal) switchToLatest];
    _spacingRatio = kDefaultSpacingRatio;
    _buttonAspectRatio = kDefaultButtonAspectRatio;
    [self setup];
  }
  return self;
}

- (void)setup {
  [self setupButtonsStackView];
  [self updateStackViewLayout];
  [self updateButtonsLayout];
}

- (void)setupButtonsStackView {
  _buttonsStackView = [[UIStackView alloc] initWithFrame:CGRectZero];
  [self addSubview:self.buttonsStackView];

  self.buttonsStackView.axis = UILayoutConstraintAxisHorizontal;
  self.buttonsStackView.alignment = UIStackViewAlignmentCenter;
  self.buttonsStackView.distribution = UIStackViewDistributionEqualSpacing;

  for (UIButton *button in self.buttons) {
    [self.buttonsStackView addArrangedSubview:button];
  }
}

- (void)updateStackViewLayout {
  [self.buttonsStackView mas_remakeConstraints:^(MASConstraintMaker *make) {
    make.center.height.equalTo(self);
    make.width.equalTo(self.mas_height).multipliedBy([self stackViewAspectRatio]);
  }];
}

- (CGFloat)stackViewAspectRatio {
  if (!self.buttons.count) {
    return 0;
  }

  CGFloat largestButtonHeightRatio =
      self.enlargedButtonIndex ? kEnlargedButtonHeightRatio : kButtonHeightRatio;
  CGFloat totalSpacingWidthRatio =
      (self.buttons.count - 1) * self.spacingRatio * largestButtonHeightRatio;
  CGFloat totalButtonsWidthRatio =
      ((self.buttons.count - 1) * kButtonHeightRatio + largestButtonHeightRatio) *
      self.buttonAspectRatio;

  return totalSpacingWidthRatio + totalButtonsWidthRatio;
}

- (void)updateButtonsLayout {
  [self.buttons enumerateObjectsUsingBlock:^(UIButton *button, NSUInteger index, BOOL *) {
    CGFloat buttonHeightFactor =
        [self isEnlargedButtonIndex:index] ? kEnlargedButtonHeightRatio : kButtonHeightRatio;

    [button mas_remakeConstraints:^(MASConstraintMaker *make) {
      make.height.equalTo(self.buttonsStackView).multipliedBy(buttonHeightFactor);
      make.width.equalTo(button.mas_height).multipliedBy(self.buttonAspectRatio);
    }];
  }];
}

- (BOOL)isEnlargedButtonIndex:(NSUInteger)index {
  return self.enlargedButtonIndex && index == self.enlargedButtonIndex.unsignedIntegerValue;
}

#pragma mark -
#pragma mark Properties
#pragma mark -

- (void)setButtons:(NSArray<UIButton *> *)buttons {
  [self replaceButtonsWith:buttons];
  self.enlargedButtonIndex = nil;
}

- (void)replaceButtonsWith:(NSArray<UIButton *> *)newButtons {
  [self.buttons makeObjectsPerformSelector:@selector(removeFromSuperview)];
  for (UIButton *button in newButtons) {
    [self.buttonsStackView addArrangedSubview:button];
  }
  _buttons = [newButtons copy];
  self.innerButtonPressedSignal = [self buttonPressedSignalForButtons:newButtons];
}

// Note: The returned signal should be disposed when the buttons are changed, otherwise the signal
// may deliver values if buttons were pressed even after they were removed from this view.
- (RACSignal *)buttonPressedSignalForButtons:(NSArray<UIButton *> *)buttons {
  auto signalFromButtons = [RACSignal empty];
  for (NSUInteger i = 0; i < buttons.count; ++i) {
    RACSignal *signalFromButton =
        [[buttons[i] rac_signalForControlEvents:UIControlEventTouchUpInside] mapReplace:@(i)];
    signalFromButtons = [signalFromButtons merge:signalFromButton];
  }
  return signalFromButtons;
}

- (void)setEnlargedButtonIndex:(nullable NSNumber *)enlargedButtonIndex {
  auto enlargedUnsignedIndex = enlargedButtonIndex.unsignedIntegerValue;
  LTParameterAssert(!enlargedButtonIndex || enlargedUnsignedIndex < self.buttons.count, @"enlarged "
                    "button index (%lu) must be smaller than the number of buttons (%lu)",
                    (unsigned long)enlargedUnsignedIndex, (unsigned long)self.buttons.count);
  _enlargedButtonIndex = enlargedButtonIndex;

  [self updateStackViewLayout];
  [self updateButtonsLayout];
}

- (void)setButtonAspectRatio:(CGFloat)buttonAspectRatio {
  _buttonAspectRatio = buttonAspectRatio;
  [self updateStackViewLayout];
  [self updateButtonsLayout];
}

- (void)setSpacingRatio:(CGFloat)spacingRatio {
  _spacingRatio = spacingRatio;
  [self updateStackViewLayout];
  [self updateButtonsLayout];
}

@end

NS_ASSUME_NONNULL_END
