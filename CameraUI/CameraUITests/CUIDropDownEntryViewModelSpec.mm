// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Reuven Siman Tov.

#import "CUIDropDownEntryViewModel.h"

#import "CUIMenuItemIconButton.h"
#import "CUIMenuItemTextButton.h"
#import "CUISimpleMenuItemViewModel.h"

SpecBegin(CUIDropDownEntryViewModel)

__block CUISimpleMenuItemViewModel *barItem;
__block Class mainBarItemViewClass;
__block Class submenuItemsViewClass;

beforeEach(^{
  barItem = [[CUISimpleMenuItemViewModel alloc] init];
  mainBarItemViewClass = [CUIMenuItemTextButton class];
  submenuItemsViewClass = [CUIMenuItemIconButton class];

});

context(@"initialization", ^{
  it(@"should raise an exception when initialized with invalid main bar item view class", ^{
    expect(^{
      CUIDropDownEntryViewModel * __unused badEntry =
          [[CUIDropDownEntryViewModel alloc] initWithMainBarItem:barItem
                                            mainBarItemViewClass:[UIView class]
                                           submenuItemsViewClass:submenuItemsViewClass];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise an exception when initialized with invalid submenu item view class", ^{
    expect(^{
      CUIDropDownEntryViewModel * __unused badEntry =
          [[CUIDropDownEntryViewModel alloc] initWithMainBarItem:barItem
                                            mainBarItemViewClass:mainBarItemViewClass
                                           submenuItemsViewClass:[UIView class]];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should set the properties", ^{
    CUIDropDownEntryViewModel *entry =
        [[CUIDropDownEntryViewModel alloc] initWithMainBarItem:barItem
                                          mainBarItemViewClass:mainBarItemViewClass
                                         submenuItemsViewClass:submenuItemsViewClass];

      expect(entry.mainBarItem).to.beIdenticalTo(barItem);
      expect(entry.mainBarItemViewClass).to.equal(mainBarItemViewClass);
      expect(entry.submenuItemsViewClass).to.equal(submenuItemsViewClass);
  });
});

SpecEnd
