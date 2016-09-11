// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Reuven Siman Tov.

#import "CUIDropDownEntryViewModel.h"

#import "CUIMenuItemView.h"

NS_ASSUME_NONNULL_BEGIN

@implementation CUIDropDownEntryViewModel

- (CUIDropDownEntryViewModel *)initWithMainBarItem:(id<CUIMenuItemViewModel>)mainBarItem
                              mainBarItemViewClass:(Class)mainBarItemViewClass
                             submenuItemsViewClass:(Class)submenuItemsViewClass {
  LTParameterAssert([self validateItemViewClass:mainBarItemViewClass],
                    @"invalid itemViewClass: %@", mainBarItemViewClass);
  LTParameterAssert([self validateItemViewClass:submenuItemsViewClass],
                    @"invalid submenuItemViewClass %@", submenuItemsViewClass);
  if (self = [super init]) {
    _mainBarItem = mainBarItem;
    _mainBarItemViewClass = mainBarItemViewClass;
    _submenuItemsViewClass = submenuItemsViewClass;
  }
  return self;
}

- (BOOL)validateItemViewClass:(Class)itemViewClass {
  return [itemViewClass conformsToProtocol:@protocol(CUIMenuItemView)] &&
      [itemViewClass isSubclassOfClass:[UIView class]];
}

@end

NS_ASSUME_NONNULL_END
