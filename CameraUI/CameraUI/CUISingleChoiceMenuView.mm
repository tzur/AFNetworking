// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Lior Bar.

#import "CUISingleChoiceMenuView.h"

#import "CUIMenuItemsDataSource.h"
#import "CUIMutableMenuItemView.h"

NS_ASSUME_NONNULL_BEGIN

@interface CUISingleChoiceMenuView () <UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

/// View model.
@property (readonly, nonatomic) CUISingleChoiceMenuViewModel *menuViewModel;

/// Underlying collection view.
@property (readonly, nonatomic) UICollectionView *collectionView;

/// Menu cells class.
@property (readonly, nonatomic) Class cellClass;

/// Provides cells to the \c collectionView according \c menuViewModel's current \c itemViewModels.
/// Values set to this property become the \c collectionView data source delegates.
@property (strong, nonatomic) CUIMenuItemsDataSource *menuItemsDataSource;

@end

@implementation CUISingleChoiceMenuView

static const CGFloat kDefaultItemsPerRow = 5.5;
static NSString * const kCellClassIdentifier = @"cellClass";

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithFrame:(CGRect)frame
                menuViewModel:(CUISingleChoiceMenuViewModel *)menuViewModel
                    cellClass:(Class)cellClass {
  if (self = [super initWithFrame:frame]) {
    LTParameterAssert([cellClass isSubclassOfClass:[UICollectionViewCell class]],
        @"%@ is not a subclass of UICollectionViewCell", cellClass);
    LTParameterAssert([cellClass conformsToProtocol:@protocol(CUIMutableMenuItemView)],
        @"%@ does not conform to the CUIMutableMenuItemView protocol", cellClass);
    _itemsPerRow = kDefaultItemsPerRow;
    _menuViewModel = menuViewModel;
    _cellClass = cellClass;
    [self setupCollectionView];
  }
  return self;
}

- (void)setupCollectionView {
  _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero
                                       collectionViewLayout:[self collectionLayout]];
  self.collectionView.showsHorizontalScrollIndicator = NO;
  self.collectionView.showsVerticalScrollIndicator = NO;
  self.collectionView.delegate = self;
  [self.collectionView registerClass:self.cellClass
          forCellWithReuseIdentifier:kCellClassIdentifier];
  [self setupViewModel];

  [self addSubview:self.collectionView];
}

- (void)setItemsPerRow:(CGFloat)itemsPerRow {
  LTParameterAssert(itemsPerRow > 0, @"itemsPerRow must be a strictly positive number");
  _itemsPerRow = itemsPerRow;
  [self.collectionView.collectionViewLayout invalidateLayout];
}

- (void)layoutSubviews {
  [super layoutSubviews];

  self.collectionView.frame = self.bounds;
}

- (UICollectionViewFlowLayout *)collectionLayout {
  UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
  layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
  return layout;
}

- (void)setupViewModel {
  [self setupUpdateSignal];
  [self setupUserSelectionSignal];
}

- (void)setupUpdateSignal {
  RAC(self, menuItemsDataSource) = [[RACObserve(self, menuViewModel.itemViewModels)
      deliverOnMainThread]
      map:^CUIMenuItemsDataSource *(NSArray<id<CUIMenuItemViewModel>> *itemViewModels) {
        return [[CUIMenuItemsDataSource alloc] initWithItemViewModels:itemViewModels
                                               reusableCellIdentifier:kCellClassIdentifier];
      }];
}

- (void)setupUserSelectionSignal {
  RACSignal *willSelectItemSignal =
      [[self rac_signalForSelector:@selector(collectionView:shouldSelectItemAtIndexPath:)
                      fromProtocol:@protocol(UICollectionViewDelegate)]
          reduceEach:(id)^NSNumber *(id, NSIndexPath *idx) {
            return @(idx.item);
          }];
  [self.menuViewModel rac_liftSelector:@selector(didTapItemAtIndex:)
                           withSignals:willSelectItemSignal, nil];
}

- (void)setMenuItemsDataSource:(CUIMenuItemsDataSource *)menuItemsDataSource {
  self.collectionView.dataSource = menuItemsDataSource;
  _menuItemsDataSource = menuItemsDataSource;
}

#pragma mark -
#pragma mark UICollectionViewDelegate
#pragma mark -

- (BOOL)collectionView:(UICollectionView __unused *)collectionView
    shouldSelectItemAtIndexPath:(NSIndexPath __unused *)indexPath {
  // Items are selected through the view model. Returning \c NO prevents \c UICollectionView from
  // selecting them.
  return NO;
}

#pragma mark -
#pragma mark UICollectionViewDelegateFlowLayout
#pragma mark -

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout __unused *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath __unused *)indexPath {
  CGFloat cellWidth = std::floor(collectionView.bounds.size.width / self.itemsPerRow);
  return CGSizeMake(cellWidth, collectionView.bounds.size.height);
}

- (UIEdgeInsets)collectionView:(UICollectionView __unused *)collectionView
                        layout:(UICollectionViewLayout __unused *)collectionViewLayout
        insetForSectionAtIndex:(NSInteger __unused)section {
  return UIEdgeInsetsZero;
}

- (CGFloat)collectionView:(UICollectionView __unused *)collectionView
                   layout:(UICollectionViewLayout __unused *)collectionViewLayout
    minimumLineSpacingForSectionAtIndex:(NSInteger __unused)section {
  return 0;
}

- (CGFloat)collectionView:(UICollectionView __unused *)collectionView
                   layout:(UICollectionViewLayout __unused *)collectionViewLayout
    minimumInteritemSpacingForSectionAtIndex:(NSInteger __unused)section {
  return 0;
}

@end

NS_ASSUME_NONNULL_END
