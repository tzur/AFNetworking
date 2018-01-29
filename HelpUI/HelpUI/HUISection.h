// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Daniel Hadar.

NS_ASSUME_NONNULL_BEGIN

@class HUIItem;

/// Immutable object that represents a section of a help document. Section groups a number of help
/// items. Section may optionally have a title.
@interface HUISection : MTLModel <MTLJSONSerializing>

/// Initializes with \c key, non localized \c title and \c items.
- (instancetype)initWithKey:(NSString *)key title:(NSString * _Nullable)title
                      items:(NSArray<HUIItem *> *)items;

/// \c YES if this section has a title.
- (BOOL)hasTitle;

/// Unique section key.
@property (copy, readonly, nonatomic) NSString *key;

/// Localized title of this help section. \c nil if the section has no title. Localization is done
/// by the localization method of \c HUIModelSettings.
@property (copy, readonly, nonatomic, nullable) NSString *title;

/// Array of \c HUIItem objects, that belong to this section.
@property (copy, readonly, nonatomic) NSArray<HUIItem *> *items;

/// Set of titles of all feature items that are associated with at least one item in this sections.
@property (readonly, nonatomic) NSSet<NSString *> *featureItemTitles;

@end

NS_ASSUME_NONNULL_END
