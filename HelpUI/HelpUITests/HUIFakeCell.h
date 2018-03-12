// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Dekel Avrahami.

#import "HUIAnimatableCell.h"

NS_ASSUME_NONNULL_BEGIN

/// Fake cell provided and shown inside the help view.
@interface HUIFakeCell : UICollectionViewCell <HUIAnimatableCell>

/// Cell value.
@property (strong, nonatomic) NSString *value;

/// \c YES if \c startAnimation was invoked and \c stopAnimation was not invoked after it. \c NO
/// otherwise.
@property (nonatomic) BOOL animating;

@end

NS_ASSUME_NONNULL_END
