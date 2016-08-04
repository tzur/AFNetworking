// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTUDataSource.h"

NS_ASSUME_NONNULL_BEGIN

/// Fake data source object used for testing.
@interface PTUFakeDataSource : NSObject <PTUDataSource, UICollectionViewDataSource>

/// Current data represented by the receiever.
@property (strong, nonatomic) NSArray<NSArray<id<PTNDescriptor>> *> *data;

/// Subject used as the \c didUpdateCollectionView signal.
@property (readonly, nonatomic) RACSubject *didUpdateCollectionView;

/// Title associated with this data.
@property (strong, nonatomic, nullable) NSString *title;

/// \c YES if the reciever has any data.
@property (readonly, nonatomic) BOOL hasData;

/// \c Error received by the receiver.
@property (strong, nonatomic, nullable) NSError *error;

/// The receiver's collection view on which he operates. Setting this property will set the receiver
/// as the \c dataSource \c collectionView and register cell classes for reuse on it.
@property (weak, nonatomic, nullable) UICollectionView *collectionView;

@end

NS_ASSUME_NONNULL_END
