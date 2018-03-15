// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Daniel Hadar.

#import "HUIView.h"

#import "HUICellsAnimator.h"
#import "HUIDocumentDataSource.h"

NS_ASSUME_NONNULL_BEGIN

@interface HUIView () <UICollectionViewDelegateFlowLayout>

/// Collection view presenting the items provided by the \c dataSource
@property (readonly, nonatomic) UICollectionView *collectionView;

/// Layout for the collection view.
@property (readonly, nonatomic) UICollectionViewFlowLayout *collectionViewLayout;

/// Animator to control the animation of the cells of the collection view.
@property (readonly, nonatomic) HUICellsAnimator *cellsAnimator;

@end

@implementation HUIView

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithFrame:(CGRect)frame {
  if (self = [super initWithFrame:frame]) {
    [self setup];
  }
  return self;
}

- (void)setup {
  self.backgroundColor = [HUISettings instance].helpViewBackgroundColor;
  [self setupCollectionViewLayout];
  [self setupCollectionView];
  _cellsAnimator = [[HUICellsAnimator alloc] init];
}

- (void)setupCollectionViewLayout {
  _collectionViewLayout = [[UICollectionViewFlowLayout alloc] init];
  self.collectionViewLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
}

- (void)setupCollectionView {
  _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero
                                       collectionViewLayout:self.collectionViewLayout];
  self.collectionView.accessibilityIdentifier = @"CollectionView";
  self.collectionView.delegate = self;
  self.collectionView.showsHorizontalScrollIndicator = NO;
  self.collectionView.showsVerticalScrollIndicator = NO;
  self.collectionView.backgroundColor = [UIColor clearColor];

  [self addSubview:self.collectionView];

  [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.edges.equalTo(self);
  }];
}

#pragma mark -
#pragma mark UICollectionViewDelegateFlowLayout
#pragma mark -

- (UIEdgeInsets)collectionView:(UICollectionView __unused *)collectionView
                        layout:(UICollectionViewLayout __unused *)collectionViewLayout
        insetForSectionAtIndex:(NSInteger)section {
  auto isLastSection = section == self.collectionView.numberOfSections - 1;
  auto lastSectionBottomInset = std::min(92., self.collectionView.bounds.size.width * 0.2);
  auto bottomInset = isLastSection ? lastSectionBottomInset : [self lineSpacing];
  auto topInset = section ? 0 : std::min(60., self.collectionView.bounds.size.width * 0.1);
  auto sideInset = 0.5 * (self.collectionView.bounds.size.width - [self cellWidth]);

  return UIEdgeInsetsMake(topInset, sideInset, bottomInset, sideInset);
}

- (CGFloat)lineSpacing {
  return std::min(self.frame.size.width * 0.053, 35.);
}

- (CGFloat)cellWidth {
  auto minimalSideInset = 0.095 * self.collectionView.bounds.size.width;
  return std::min(350., self.collectionView.bounds.size.width - 2 * minimalSideInset);
}

- (CGFloat)collectionView:(UICollectionView __unused *)collectionView
    layout:(UICollectionViewLayout __unused *)collectionViewLayout
    minimumLineSpacingForSectionAtIndex:(__unused NSInteger)section {
  return [self lineSpacing];
}

- (CGSize)collectionView:(UICollectionView __unused *)collectionView
                  layout:(UICollectionViewLayout __unused *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
  auto cellWidth = [self cellWidth];
  auto cellHeight = [self.dataSource cellHeightForIndexPath:indexPath width:cellWidth];
  return CGSizeMake(cellWidth, cellHeight);
}

#pragma mark -
#pragma mark UICollectionViewDelegate
#pragma mark -

- (void)collectionView:(UICollectionView __unused *)collectionView
       willDisplayCell:(UICollectionViewCell *)cell
    forItemAtIndexPath:(NSIndexPath __unused *)indexPath {
  if ([cell conformsToProtocol:@protocol(HUIAnimatableCell)]) {
    [self.cellsAnimator addCell:(UICollectionViewCell<HUIAnimatableCell> *)cell];
  }
}

- (void)collectionView:(UICollectionView __unused *)collectionView
  didEndDisplayingCell:(UICollectionViewCell *)cell
    forItemAtIndexPath:(NSIndexPath __unused *)indexPath {
  if ([cell conformsToProtocol:@protocol(HUIAnimatableCell)]) {
    [self.cellsAnimator removeCell:(UICollectionViewCell<HUIAnimatableCell> *)cell];
  }
}

- (void)scrollViewDidScroll:(UIScrollView __unused *)scrollView {
  [self adjustAnimationArea];
}

- (void)adjustAnimationArea {
  auto animationArea = CGRectCenteredAt(CGRectCenter(self.bounds),
                                        self.bounds.size * CGSizeMake(0.5, 0.5));
  auto animationAreaInCollectionView = [self convertRect:animationArea toView:self.collectionView];
  self.cellsAnimator.animationArea = animationAreaInCollectionView;
}

#pragma mark -
#pragma mark UIView
#pragma mark -

- (void)traitCollectionDidChange:(UITraitCollection  * _Nullable)previousTraitCollection {
  [super traitCollectionDidChange:previousTraitCollection];
  [self.collectionViewLayout invalidateLayout];
}

- (void)layoutSubviews {
  [super layoutSubviews];
  [self adjustAnimationArea];
}

#pragma mark -
#pragma mark Public
#pragma mark -

- (void)setDataSource:(id<HUIItemsDataSource> _Nullable)dataSource {
  _dataSource = dataSource;
  [self.dataSource registerCellClassesWithCollectionView:self.collectionView];
  self.collectionView.dataSource = dataSource;
  [self.collectionView reloadData];
}

- (void)invalidateLayout {
  [self.collectionViewLayout invalidateLayout];
  [self.collectionView setNeedsLayout];
  [self setNeedsLayout];
}

- (void)reloadData {
  [self.collectionView reloadData];
}

- (void)showSection:(NSInteger)sectionIndex
   atScrollPosition:(UICollectionViewScrollPosition)scrollPosition
           animated:(BOOL)animated {
  auto numberOfSections = self.collectionView.numberOfSections;
  LTParameterAssert(sectionIndex < numberOfSections, @"sectionIndex is out of bounds");

  auto indexPath = [NSIndexPath indexPathForItem:0 inSection:sectionIndex];

  [self.collectionView layoutIfNeeded];
  [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:scrollPosition
                                      animated:animated];
}

@end

NS_ASSUME_NONNULL_END
