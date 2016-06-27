// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

NS_ASSUME_NONNULL_BEGIN

/// Value class representing metadata related to a \c PTUChangeset.
@interface PTUChangesetMetadata : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c title and \c sectionTitles.
- (instancetype)initWithTitle:(nullable NSString *)title
                sectionTitles:(NSDictionary<NSNumber *, NSString *> *)sectionTitles
    NS_DESIGNATED_INITIALIZER;

/// Title of the data in the \c PTUChangeset associated with this metadata or \c nil if no such
/// title is available.
@property (readonly, nonatomic, nullable) NSString *title;

/// Titles of the sections of the data in the \c PTUChangeset associated with this metadata. If no
/// title is available for a section, \c sectionTitles will contain no value for that index.
@property (readonly, nonatomic) NSDictionary<NSNumber *, NSString *> *sectionTitles;

@end

NS_ASSUME_NONNULL_END
