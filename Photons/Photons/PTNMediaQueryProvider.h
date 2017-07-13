// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Michael Kimyagarov.

#import <MediaPlayer/MPMediaQuery.h>

NS_ASSUME_NONNULL_BEGIN

@class MPMediaItem, MPMediaItemCollection, MPMediaPredicate;

/// Protocol defining functionality of a media query.
@protocol PTNMediaQuery <NSObject>

/// Array of media items that match the media query’s predicates or \c nil on error.
@property (readonly, nonatomic, nullable) NSArray<MPMediaItem *> *items;

/// Array of media item collections whose contained items match the query’s predicates or \c nil on
/// error. Items within each collection are grouped by \c groupingType.
@property (readonly, nonatomic, nullable) NSArray<MPMediaItemCollection *> *collections;

/// Grouping for collections retrieved with the media query.
@property (nonatomic) MPMediaGrouping groupingType;

/// Predicates of the media query.
@property (nonatomic) NSSet<MPMediaPredicate *> *filterPredicates;

@end

/// Marks \c MPMediaQuery as an implementer of \c PTNMediaQuery.
@interface MPMediaQuery (PTNMediaQuery) <PTNMediaQuery>
@end

/// Protocol defining functionality for creating \c MPMediaQuery objects.
@protocol PTNMediaQueryProvider <NSObject>

/// Returns \c PTNMediaQuery initialized with the given \c predicates.
- (id<PTNMediaQuery>)queryWithFilterPredicates:(NSSet<MPMediaPredicate *> *)predicates;

@end

/// Default implementation of \PTNMediaQueryProvider protocol.
@interface PTNMediaQueryProvider : NSObject <PTNMediaQueryProvider>
@end

NS_ASSUME_NONNULL_END
