// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTUFakeDataSource.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTUFakeDataSource ()

/// \c YES if the reciever has any data.
@property (readwrite, nonatomic) BOOL hasData;

@end

@implementation PTUFakeDataSource

@synthesize title = _title;
@synthesize didUpdateCollectionView = _didUpdateCollectionView;

- (nullable id<PTNDescriptor>)descriptorAtIndexPath:(NSIndexPath *)index {
  if (self.data.count <= (NSUInteger)index.section) {
    return nil;
  }
  if (self.data[index.section].count <= (NSUInteger)index.item) {
    return nil;
  }
  return self.data[index.section][index.item];
}

- (nullable NSIndexPath *)indexPathOfDescriptor:(id<PTNDescriptor>)descriptor {
  NSUInteger item;
  for (unsigned int section = 0; section < self.data.count; ++section) {
    item = [self.data[section] indexOfObject:descriptor];
    if (item != NSNotFound) {
      return [NSIndexPath indexPathForItem:item inSection:section];
    }
  }

  return nil;
}

- (nullable NSString *)titleForSection:(NSInteger)section {
  return self.sectionTitles[@(section)];
}

- (void)setCollectionView:(nullable UICollectionView *)collectionView {
  _collectionView = collectionView;
  self.collectionView.dataSource = self;
  NSString *reuseIdentifier = NSStringFromClass([UICollectionViewCell class]);
  [self.collectionView registerClass:[UICollectionViewCell class]
          forCellWithReuseIdentifier:reuseIdentifier];
}

- (void)setData:(NSArray<NSArray<id<PTNDescriptor>> *> *)data {
  _data = data;
  self.hasData = [self dataModelHasData];
}

- (BOOL)dataModelHasData {
  for (NSArray *collection in self.data) {
    if (collection.count) {
      return YES;
    }
  }

  return NO;
}

- (RACSignal *)didUpdateCollectionView {
  if (!_didUpdateCollectionView) {
    _didUpdateCollectionView = [RACSubject subject];
  }
  
  return _didUpdateCollectionView;
}

#pragma mark -
#pragma mark UICollectionViewDataSource
#pragma mark -

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView * __unused)collectionView {
  return self.data.count;
}

- (NSInteger)collectionView:(UICollectionView __unused *)view
     numberOfItemsInSection:(NSInteger)section {
  return self.data[section].count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
  NSString *reuseIdentifier = NSStringFromClass([UICollectionViewCell class]);
  return [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier
                                                   forIndexPath:indexPath];
}

@end

NS_ASSUME_NONNULL_END
