// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Reuven Siman Tov.

#import "CUIDropDownHorizontalView.h"

#import "CUIDropDownEntryViewModel.h"
#import "CUIMenuItemView.h"
#import "CUISimpleMenuItemViewModel.h"
#import "UIView+Retrieval.h"

static const CGRect kViewFrame = CGRectMake(0, 0, 300, 44);
static UIColor * const kSubmenuBackgroundColor = [UIColor grayColor];

@interface  CUIFakeMenuItemView : UIView <CUIMenuItemView>
@end

@implementation CUIFakeMenuItemView
@synthesize model = _model;
- (instancetype)initWithModel:(id<CUIMenuItemViewModel>)model {
  if (self = [super initWithFrame:CGRectZero]) {
    _model = model;
  }
  return self;
}
@end

@interface  CUIFakeMenuItemButton : UIControl <CUIMenuItemView>
@end

@implementation CUIFakeMenuItemButton
@synthesize model = _model;
- (instancetype)initWithModel:(id<CUIMenuItemViewModel>)model {
  if (self = [super initWithFrame:CGRectZero]) {
    _model = model;
  }
  return self;
}
@end

SpecBegin(CUIDropDownHorizontalView)

__block CUIDropDownHorizontalView *dropDownView;
__block NSArray<CUIDropDownEntryViewModel *> *entries;
__block CUISimpleMenuItemViewModel *mainBarItem1;
__block CUISimpleMenuItemViewModel *mainBarItem2;
__block CUISimpleMenuItemViewModel *mainBarItem3;

beforeEach(^{
  mainBarItem1 = [[CUISimpleMenuItemViewModel alloc] init];
  mainBarItem1.subitems = @[
    [[CUISimpleMenuItemViewModel alloc] init],
    [[CUISimpleMenuItemViewModel alloc] init]
  ];
  mainBarItem2 = [[CUISimpleMenuItemViewModel alloc] init];
  mainBarItem3 = [[CUISimpleMenuItemViewModel alloc] init];
  mainBarItem3.subitems = @[
    [[CUISimpleMenuItemViewModel alloc] init]
  ];

  Class buttonClass = [CUIFakeMenuItemButton class];
  Class viewClass = [CUIFakeMenuItemView class];

  entries = @[
    [[CUIDropDownEntryViewModel alloc] initWithMainBarItem:mainBarItem1
                                      mainBarItemViewClass:buttonClass
                                     submenuItemsViewClass:buttonClass],
    [[CUIDropDownEntryViewModel alloc] initWithMainBarItem:mainBarItem2
                                      mainBarItemViewClass:viewClass
                                     submenuItemsViewClass:buttonClass],
    [[CUIDropDownEntryViewModel alloc] initWithMainBarItem:mainBarItem3
                                      mainBarItemViewClass:buttonClass
                                     submenuItemsViewClass:buttonClass]
  ];
  dropDownView = [[CUIDropDownHorizontalView alloc] initWithFrame:kViewFrame];
});

context(@"initialization", ^{
  it(@"should set properties", ^{
    expect(dropDownView.frame).to.equal(kViewFrame);
    expect(dropDownView.entries).to.equal(@[]);
    expect(dropDownView.maxMainBarWidth).to.equal(450);
    expect(dropDownView.lateralMargins).to.equal(0);
    expect(dropDownView.submenuLateralMargins).to.equal(0);
    expect(dropDownView.submenuBackgroundColor).to.equal([UIColor clearColor]);
  });
});

context(@"entries", ^{
  __block UIStackView *mainBarStackView;
  __block UIView *submenuView0;
  __block UIView *submenuView1;
  __block UIView *submenuView2;
  __block UIStackView *submenuStackView0;
  __block UIStackView *submenuStackView2;

  beforeEach(^{
    dropDownView.entries = entries;
    mainBarStackView =
        (UIStackView *)[dropDownView wf_viewForAccessibilityIdentifier:@"MainBarStackView"];
    submenuView0 = [dropDownView wf_viewForAccessibilityIdentifier:@"SubmenuView#0"];
    submenuView1 = [dropDownView wf_viewForAccessibilityIdentifier:@"SubmenuView#1"];
    submenuView2 = [dropDownView wf_viewForAccessibilityIdentifier:@"SubmenuView#2"];
    submenuStackView0 =
        (UIStackView *)[submenuView0 wf_viewForAccessibilityIdentifier:@"SubmenuStackView"];
    submenuStackView2 =
        (UIStackView *)[submenuView2 wf_viewForAccessibilityIdentifier:@"SubmenuStackView"];
  });

  it(@"should create appropriate subview classes", ^{
    expect(mainBarStackView).to.beKindOf([UIStackView class]);
    expect(submenuStackView0).to.beKindOf([UIStackView class]);
    expect(submenuStackView0).to.beKindOf([UIStackView class]);
  });

  it(@"should create main bar item views", ^{
    expect(mainBarStackView.arrangedSubviews.count).to.equal(entries.count);
    [mainBarStackView.arrangedSubviews enumerateObjectsUsingBlock:^(UIView *view, NSUInteger idx,
                                                                    BOOL *) {
      expect([view class]).to.equal(entries[idx].mainBarItemViewClass);
      expect(((id<CUIMenuItemView>)view).model).to.equal(entries[idx].mainBarItem);
    }];
  });

  it(@"should create hidden submenu views", ^{
    expect(submenuView0).toNot.beNil();
    expect(submenuView1).to.beNil();
    expect(submenuView2).toNot.beNil();

    expect(submenuView0.hidden).to.beTruthy();
    expect(submenuView2.hidden).to.beTruthy();
  });

  it(@"should create submenu item views", ^{
    expect(submenuStackView0.arrangedSubviews.count)
        .to.equal(entries[0].mainBarItem.subitems.count);
    [submenuStackView0.arrangedSubviews enumerateObjectsUsingBlock:^(UIView *view, NSUInteger idx,
                                                                     BOOL *) {
      expect([view class]).to.equal(entries[idx].submenuItemsViewClass);
      expect(((id<CUIMenuItemView>)view).model)
          .to.equal(entries[0].mainBarItem.subitems[idx]);
    }];

    expect(submenuStackView2.arrangedSubviews.count)
        .to.equal(entries[2].mainBarItem.subitems.count);
    [submenuStackView2.arrangedSubviews enumerateObjectsUsingBlock:^(UIView *view, NSUInteger idx,
                                                                     BOOL *) {
      expect([view class]).to.equal(entries[idx].submenuItemsViewClass);
      expect(((id<CUIMenuItemView>)view).model)
          .to.equal(entries[2].mainBarItem.subitems[idx]);
    }];
  });

  it(@"should clear previous entries and set new ones", ^{
    CUIDropDownEntryViewModel *viewModel = [[CUIDropDownEntryViewModel alloc]
        initWithMainBarItem:[[CUISimpleMenuItemViewModel alloc] init]
       mainBarItemViewClass:[CUIFakeMenuItemView class]
      submenuItemsViewClass:[CUIFakeMenuItemView class]];
    dropDownView.entries =  @[viewModel];

    UIStackView *mainBarStackView2 =
        (UIStackView *)[dropDownView wf_viewForAccessibilityIdentifier:@"MainBarStackView"];
    expect(submenuStackView0).to.beKindOf([UIStackView class]);

    expect(mainBarStackView2.arrangedSubviews.count).to.equal(1);
    CUIFakeMenuItemView *menuItemView = mainBarStackView2.arrangedSubviews[0];
    expect(menuItemView).to.beKindOf([CUIFakeMenuItemView class]);
    expect(menuItemView.model).to.equal(viewModel.mainBarItem);

    UIView *submenuView = [dropDownView wf_viewForAccessibilityIdentifier:@"SubmenuView#0"];
    expect(submenuView).to.beNil();
  });

  it(@"should raise when given an entry with subitems and a view that is not kind of UIControl", ^{
    CUISimpleMenuItemViewModel *mainBarItem = [[CUISimpleMenuItemViewModel alloc] init];
    mainBarItem.subitems = @[[[CUISimpleMenuItemViewModel alloc] init]];
    CUIDropDownEntryViewModel *viewModel =
        [[CUIDropDownEntryViewModel alloc] initWithMainBarItem:mainBarItem
                                          mainBarItemViewClass:[CUIFakeMenuItemView class]
                                         submenuItemsViewClass:[CUIFakeMenuItemView class]];

    expect(^{
      dropDownView.entries =  @[viewModel];
    }).to.raise(NSInternalInconsistencyException);
  });
});

context(@"submenuBackgroundColor", ^{
  it(@"should set the submenues background color", ^{
    UIColor *color = [UIColor grayColor];
    dropDownView.submenuBackgroundColor = color;
    dropDownView.entries = entries;
    UIView *submenuView0 = [dropDownView wf_viewForAccessibilityIdentifier:@"SubmenuView#0"];
    UIView *submenuView2 = [dropDownView wf_viewForAccessibilityIdentifier:@"SubmenuView#2"];

    expect(submenuView0.backgroundColor).to.equal(color);
    expect(submenuView2.backgroundColor).to.equal(color);

    dropDownView.submenuBackgroundColor = color = [UIColor whiteColor];
    expect(submenuView0.backgroundColor).to.equal(color);
    expect(submenuView2.backgroundColor).to.equal(color);

    dropDownView.submenuBackgroundColor = color = [UIColor redColor];
    expect(submenuView0.backgroundColor).to.equal(color);
    expect(submenuView2.backgroundColor).to.equal(color);
  });
});

context(@"submenus", ^{
  __block UIStackView *mainBarStackView;
  __block UIStackView *submenuStackView0;
  __block UIStackView *submenuStackView2;
  __block CUIFakeMenuItemButton *MainBarItemButton0;
  __block CUIFakeMenuItemButton *MainBarItemButton2;
  __block UIView *submenuView0;
  __block UIView *submenuView2;
  __block CUIFakeMenuItemButton *submenuButton00;
  __block CUIFakeMenuItemButton *submenuButton01;
  __block CUIFakeMenuItemButton *submenuButton20;

  beforeEach(^{
    dropDownView.entries = entries;
    mainBarStackView =
        (UIStackView *)[dropDownView wf_viewForAccessibilityIdentifier:@"MainBarStackView"];
    MainBarItemButton0 = mainBarStackView.arrangedSubviews[0];
    MainBarItemButton2 = mainBarStackView.arrangedSubviews[2];
    submenuView0 = [dropDownView wf_viewForAccessibilityIdentifier:@"SubmenuView#0"];
    submenuView2 = [dropDownView wf_viewForAccessibilityIdentifier:@"SubmenuView#2"];
    submenuStackView0 =
        (UIStackView *)[submenuView0 wf_viewForAccessibilityIdentifier:@"SubmenuStackView"];
    submenuButton00 = submenuStackView0.arrangedSubviews[0];
    submenuButton01 = submenuStackView0.arrangedSubviews[1];
    submenuStackView2 =
        (UIStackView *)[submenuView2 wf_viewForAccessibilityIdentifier:@"SubmenuStackView"];
    submenuButton20 = submenuStackView2.arrangedSubviews[0];
  });

  it(@"should create appropriate subview classes", ^{
    expect(mainBarStackView).to.beKindOf([UIStackView class]);
    expect(MainBarItemButton0).to.beKindOf([CUIFakeMenuItemButton class]);
    expect(MainBarItemButton2).to.beKindOf([CUIFakeMenuItemButton class]);
    expect(submenuStackView0).to.beKindOf([UIStackView class]);
    expect(submenuButton00).to.beKindOf([CUIFakeMenuItemButton class]);
    expect(submenuButton01).to.beKindOf([CUIFakeMenuItemButton class]);
    expect(submenuStackView2).to.beKindOf([UIStackView class]);
    expect(submenuButton20).to.beKindOf([CUIFakeMenuItemButton class]);
  });

  it(@"should toggle their hidden state when their main bar buttons are pressed", ^{
    expect(submenuView0.hidden).to.beTruthy();
    expect(submenuView2.hidden).to.beTruthy();

    [UIView performWithoutAnimation:^{
      [MainBarItemButton0 sendActionsForControlEvents:UIControlEventTouchUpInside];
    }];
    expect(submenuView0.hidden).will.beFalsy();
    expect(submenuView2.hidden).will.beTruthy();

    [UIView performWithoutAnimation:^{
      [MainBarItemButton0 sendActionsForControlEvents:UIControlEventTouchUpInside];
    }];
    expect(submenuView0.hidden).will.beTruthy();
    expect(submenuView2.hidden).will.beTruthy();

    [UIView performWithoutAnimation:^{
      [MainBarItemButton2 sendActionsForControlEvents:UIControlEventTouchUpInside];
    }];
    expect(submenuView0.hidden).will.beTruthy();
    expect(submenuView2.hidden).will.beFalsy();

    [UIView performWithoutAnimation:^{
      [MainBarItemButton2 sendActionsForControlEvents:UIControlEventTouchUpInside];
    }];
    expect(submenuView0.hidden).will.beTruthy();
    expect(submenuView2.hidden).will.beTruthy();
  });

  it(@"should be presented when their main bar buttons are pressed", ^{
    expect(submenuView0.hidden).to.beTruthy();
    expect(submenuView2.hidden).to.beTruthy();

    [UIView performWithoutAnimation:^{
      [MainBarItemButton0 sendActionsForControlEvents:UIControlEventTouchUpInside];
    }];
    expect(submenuView0.hidden).will.beFalsy();
    expect(submenuView2.hidden).will.beTruthy();

    [UIView performWithoutAnimation:^{
      [MainBarItemButton2 sendActionsForControlEvents:UIControlEventTouchUpInside];
    }];
    expect(submenuView0.hidden).will.beTruthy();
    expect(submenuView2.hidden).will.beFalsy();

    [UIView performWithoutAnimation:^{
      [MainBarItemButton0 sendActionsForControlEvents:UIControlEventTouchUpInside];
    }];
    expect(submenuView0.hidden).will.beFalsy();
    expect(submenuView2.hidden).will.beTruthy();
  });

  it(@"should toggle their hidden state when their submenu buttons are pressed", ^{
    expect(submenuView0.hidden).to.beTruthy();

    [UIView performWithoutAnimation:^{
      [MainBarItemButton0 sendActionsForControlEvents:UIControlEventTouchUpInside];
    }];
    expect(submenuView0.hidden).will.beFalsy();
    [UIView performWithoutAnimation:^{
      [submenuButton00 sendActionsForControlEvents:UIControlEventTouchUpInside];
    }];
    expect(submenuView0.hidden).will.beTruthy();

    [UIView performWithoutAnimation:^{
      [MainBarItemButton0 sendActionsForControlEvents:UIControlEventTouchUpInside];
    }];
    expect(submenuView0.hidden).will.beFalsy();
    [UIView performWithoutAnimation:^{
      [submenuButton01 sendActionsForControlEvents:UIControlEventTouchUpInside];
    }];
    expect(submenuView0.hidden).will.beTruthy();
    expect(submenuView2.hidden).will.beTruthy();

    [UIView performWithoutAnimation:^{
      [MainBarItemButton2 sendActionsForControlEvents:UIControlEventTouchUpInside];
    }];
    expect(submenuView2.hidden).will.beFalsy();
    [UIView performWithoutAnimation:^{
      [submenuButton20 sendActionsForControlEvents:UIControlEventTouchUpInside];
    }];
    expect(submenuView2.hidden).will.beTruthy();
  });

  it(@"should be hidden after a call to hideDropDownViews", ^{
    [UIView performWithoutAnimation:^{
      [dropDownView hideDropDownViews];
    }];
    expect(submenuView0.hidden).will.beTruthy();
    expect(submenuView2.hidden).will.beTruthy();

    submenuView0.hidden = NO;
    submenuView2.hidden = NO;
    expect(submenuView0.hidden).to.beFalsy();
    expect(submenuView2.hidden).to.beFalsy();

    [UIView performWithoutAnimation:^{
      [dropDownView hideDropDownViews];
    }];
    expect(submenuView0.hidden).will.beTruthy();
    expect(submenuView2.hidden).will.beTruthy();
  });
});

SpecEnd
