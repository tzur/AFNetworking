// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

NS_ASSUME_NONNULL_BEGIN

/// View of the \c PTUCollectionViewController, the view contains views with the
/// <tt>{CollectionView, CollectionViewContainer, Empty, Error}</tt> accessibility identifiers.
@interface PTUCollectionView : UIView

/// View to display when the receiver's has no data, but did not err. The view will automatically
/// track the size of the receiver's view. The default view contains a single \c UILabel containing
/// the localized string "No photos".
@property (strong, nonatomic) UIView *emptyView;

/// View to display when the receiver's has erred. The view will automatically track the size of the
/// receiver's view. The default view contains a single \c UILabel containing the localized string
/// "Error fetching data".
@property (strong, nonatomic) UIView *errorView;

/// View displayed behind the \c collectionViewContainer, the view will automatically track the size
/// of the receiver's view. Setting this view will add it the the receiver's view hierarchy. Setting
/// this view to \c nil will result in no view to be displayed behind the collection view container,
/// which is the default behavior.
@property (strong, nonatomic, nullable) UIView *backgroundView;

/// Background color of the receiver's collection view container, initial value is clear.
@property (strong, nonatomic) UIColor *backgroundColor;

/// View located below the \c emptyView and \c errorView and above the \c backgroundView. This view
/// tracks the size of the receiver.
@property (readonly, nonatomic) UIView *collectionViewContainer;

@end

NS_ASSUME_NONNULL_END
