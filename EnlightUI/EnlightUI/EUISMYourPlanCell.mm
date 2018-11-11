// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Dekel Avrahami.

#import "EUISMYourPlanCell.h"

#import "EUISMYourPlanViewModel.h"
#import "UIColor+EnlightUI.h"
#import "UIFont+EnlightUI.h"

NS_ASSUME_NONNULL_BEGIN

@interface EUISMYourPlanCell ()

/// Label for the title.
@property (readonly, nonatomic) UILabel *titleLabel;

/// Font size of the title.
@property (nonatomic) CGFloat titleFontSize;

/// Vertical spacer view to seperate the title from the content below it.
@property (readonly, nonatomic) UIView *titleSpacer;

/// Label for the subtitle.
@property (readonly, nonatomic) UILabel *subtitleLabel;

/// Font size of the subtitle.
@property (nonatomic) CGFloat subtitleFontSize;

/// Vertical spacer view to seperate the subtitle from the content below it.
@property (readonly, nonatomic) UIView *subtitleSpacer;

/// Label for the body.
@property (readonly, nonatomic) UILabel *bodyLabel;

/// Font size of the body.
@property (nonatomic) CGFloat bodyFontSize;

/// Image view for the current application thumbnail.
@property (readonly, nonatomic) UIImageView *currentAppThumbnailView;

/// Image view for icon reflecting the current subscription plan status.
@property (readonly, nonatomic) UIImageView *statusIconView;

@end

@implementation EUISMYourPlanCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style
              reuseIdentifier:(nullable NSString *)reuseIdentifier {
  if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
    [self setupThumbnail];
    [self setupText];
    [self setupInfoIcons];
    self.backgroundColor = [UIColor eui_secondaryDarkColor];
  }
  return self;
}

- (void)setupThumbnail {
  _currentAppThumbnailView = [[UIImageView alloc] initWithFrame:CGRectZero];
  @weakify(self);
  RAC(self.currentAppThumbnailView, wf_viewModel) =
      [RACObserve(self, viewModel.currentAppThumbnailURL)
          map:^id<WFImageViewModel>(NSURL *url) {
            @strongify(self);
            return WFImageViewModel(url).sizeToBounds(self.currentAppThumbnailView).build();
          }];
  [self.contentView addSubview:self.currentAppThumbnailView];

  [self.currentAppThumbnailView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.left.equalTo(self).with.offset(20);
    make.width.height.equalTo(@60);
  }];
}

- (void)setupText {
  [self setupTitle];
  [self setupTitleSpacer];
  [self setupSubtitle];
  [self setupSubtitleSpacer];
  [self setupBody];

  auto stackView = [[UIStackView alloc] initWithArrangedSubviews:@[
    self.titleLabel,
    self.titleSpacer,
    self.subtitleLabel,
    self.subtitleSpacer,
    self.bodyLabel
  ]];
  stackView.axis = UILayoutConstraintAxisVertical;
  [self.contentView addSubview:stackView];

  [self.titleSpacer mas_makeConstraints:^(MASConstraintMaker *make) {
    make.height.equalTo(@2);
  }];
  [self.subtitleSpacer mas_makeConstraints:^(MASConstraintMaker *make) {
    make.height.equalTo(@8);
  }];
  [stackView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.centerY.equalTo(self);
    make.left.equalTo(self.currentAppThumbnailView.mas_right).offset(10);
  }];
}

- (void)setupTitle {
  _titleLabel = [[UILabel alloc] init];
  self.titleLabel.textColor = [[UIColor eui_whiteColor] colorWithAlphaComponent:0.9];
  RAC(self.titleLabel, text) = RACObserve(self, viewModel.title);
  RAC(self.titleLabel, font) = [RACObserve(self, titleFontSize)
      map:^UIFont *(NSNumber *fontSize) {
        return [UIFont eui_secondaryLabelFontWithSize:fontSize.CGFloatValue];
  }];
}

- (void)setupTitleSpacer {
  _titleSpacer = [[UIView alloc] initWithFrame:CGRectZero];
  RAC(self.titleSpacer, hidden) = [RACSignal combineLatest:@[
    RACObserve(self, viewModel.title.length),
    RACObserve(self, viewModel.subtitle.length),
    RACObserve(self, viewModel.body.length)
  ] reduce:(id)^NSNumber *(NSNumber * _Nullable titleLength, NSNumber * _Nullable subtitleLength,
                           NSNumber * _Nullable bodyLength) {
    return @([EUISMYourPlanCell isTextEmpty:titleLength] ||
        ([EUISMYourPlanCell isTextEmpty:subtitleLength] &&
         [EUISMYourPlanCell isTextEmpty:bodyLength]));
  }];
  self.titleSpacer.accessibilityIdentifier = @"YourPlanTitleSpacer";
}

- (void)setupSubtitle {
  _subtitleLabel = [[UILabel alloc] init];
  self.subtitleLabel.textColor = [[UIColor eui_mainTextColor] colorWithAlphaComponent:0.9];
  RAC(self.subtitleLabel, text) = RACObserve(self, viewModel.subtitle);
  RAC(self.subtitleLabel, font) = [RACObserve(self, subtitleFontSize)
      map:^UIFont *(NSNumber *fontSize) {
        return [UIFont eui_mainTextFontWithSize:fontSize.CGFloatValue];
  }];
}

- (void)setupSubtitleSpacer {
  _subtitleSpacer = [[UIView alloc] initWithFrame:CGRectZero];
  RAC(self.subtitleSpacer, hidden) = [RACSignal combineLatest:@[
    RACObserve(self, viewModel.subtitle.length),
    RACObserve(self, viewModel.body.length)
  ] reduce:(id)^NSNumber *(NSNumber * _Nullable subtitleLength, NSNumber * _Nullable bodyLength) {
    return @([EUISMYourPlanCell isTextEmpty:subtitleLength] ||
        [EUISMYourPlanCell isTextEmpty:bodyLength]);
  }];
  self.subtitleSpacer.accessibilityIdentifier = @"YourPlanSubtitleSpacer";
}

+ (BOOL)isTextEmpty:(nullable NSNumber *)textLength {
  return !textLength || !textLength.unsignedIntegerValue;
}

- (void)setupBody {
  _bodyLabel = [[UILabel alloc] init];
  self.bodyLabel.textColor = [UIColor eui_secondaryTextColor];
  RAC(self.bodyLabel, text) = RACObserve(self, viewModel.body);
  RAC(self.bodyLabel, font) = [RACObserve(self, bodyFontSize)
      map:^UIFont *(NSNumber *fontSize) {
        return [UIFont eui_mainTextFontWithSize:fontSize.CGFloatValue];
  }];
}

- (void)setupInfoIcons {
  auto chevronImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
  chevronImageView.wf_viewModel = WFImageViewModel([NSURL URLWithString:@"chevron"])
      .sizeToBounds(chevronImageView)
      .build();
  [self setupStatusIconView];

  auto horizontalStackView = [[UIStackView alloc] initWithArrangedSubviews:@[
    self.statusIconView,
    chevronImageView
  ]];
  horizontalStackView.axis = UILayoutConstraintAxisHorizontal;

  auto verticalSpacer = [[UIView alloc] initWithFrame:CGRectZero];
  auto verticalStackView = [[UIStackView alloc] initWithArrangedSubviews:@[
    verticalSpacer,
    horizontalStackView
  ]];
  verticalStackView.axis = UILayoutConstraintAxisVertical;
  [self.contentView addSubview:verticalStackView];

  [chevronImageView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.width.height.equalTo(@30);
  }];
  [self.statusIconView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.width.height.equalTo(@30);
  }];
  [verticalSpacer mas_makeConstraints:^(MASConstraintMaker *make) {
    make.height.greaterThanOrEqualTo(@7).priorityHigh();
    make.height.lessThanOrEqualTo(@16).priorityHigh();
    make.height.equalTo(self.mas_width).multipliedBy(0.032).priorityMedium();
  }];
  [verticalStackView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(self);
    make.right.equalTo(self).offset(-10);
  }];
}

- (void)setupStatusIconView {
  _statusIconView = [[UIImageView alloc] initWithFrame:CGRectZero];
  @weakify(self);
  RAC(self.statusIconView, wf_viewModel) = [RACObserve(self, viewModel.statusIconURL)
      map:^id<WFImageViewModel> _Nullable (NSURL * _Nullable url) {
        @strongify(self);
        return WFImageViewModel(url).sizeToBounds(self.statusIconView).build();
      }];
}

- (void)layoutSubviews {
  self.titleFontSize = std::clamp(CGRectGetWidth(self.bounds) * 0.045, 16., 17.);
  self.subtitleFontSize = std::clamp(CGRectGetWidth(self.bounds) * 0.035, 11., 13.);
  self.bodyFontSize = std::clamp(CGRectGetWidth(self.bounds) * 0.035, 11., 13.);
}

@end

NS_ASSUME_NONNULL_END
