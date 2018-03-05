// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Daniel Hadar.

NS_ASSUME_NONNULL_BEGIN

@class HUISection;

/// Immutable object that represents a single help document: a container for all help content for a
/// certain broad topic.
///
/// Help document is divided into sections, that by themselves are divided into items. Section is
/// intended to group items by a certain common context, like a currently selected tool, while items
/// give the ability to provide different types of content, like paragraphs of text, images, videos,
/// etc.
///
/// Broadly speaking, help document is like a web page, sections are like top level \c <div> tags,
/// and items are like html tags and widgets.
///
/// @note that while the the general design idea is for the help document to contain only content,
/// and not styling (aka html, and not css), some elements do break this rule. Nevertheless, try not
/// to extend this breakage.
@interface HUIDocument : MTLModel <MTLJSONSerializing>

/// Creates and returns a help document for the given JSON \c path.
/// If an error occurred while reading the file or deserializing it, \c nil will be returned and
/// \c error will be populated with \c LTErrorCodeFileReadFailed. If \c path is \c nil, \c nil will
/// be returned and \c error will be set to \c LTErrorCodeFileNotFound.
///
/// @note the JSON file supports showing videos, slideshows and images. See the following examples:
///
/// @example Video:
/// "key": "Filters",
/// "items": [
///   {
///     "type": "video",
///     "title": "title",
///     "body": "body",
///     "icon_url": "paintcode://EVDTimelineIcons/IconName",
///     "video": "1.mp4",
///     "associatedFeatureItemTitles": [
///       "Filters"
///     ]
///   }
/// ]
///
/// @example Slideshow:
/// "key": "Filters",
/// "items": [
///   {
///     "type": "slideshow",
///     "transition": "fade",
///     "transitionDuration": 0,
///     "title": "title",
///     "body": "body",
///     "icon_url": "paintcode://EVDTimelineIcons/IconName",
///     "images": [
///       "1.jpg",
///       "2.jpg"
///     ],
///     "associatedFeatureItemTitles": [
///       "Filters"
///     ]
///   }
/// ]
///
/// @example Image:
/// "key": "Filters",
/// "items": [
///   {
///     "type": "image",
///     "title": "title",
///     "body": "body",
///     "icon_url": "paintcode://EVDTimelineIcons/IconName",
///     "image": "1.jpg",
///     "associatedFeatureItemTitles": [
///       "Filters"
///     ]
///   }
/// ]
+ (nullable instancetype)helpDocumentForJsonAtPath:(nullable NSString *)path
                                             error:(NSError **)error;

/// Returns a section with the given key, or \c nil if no such section exists.
- (nullable HUISection *)sectionForKey:(NSString *)key;

/// Returns the key of the first section that matches \c featureHierarchyPath. The
/// \c featureHierarchyPath is the feature-tree path to a node. For example for the input
/// "Filters/Clip/EnlightVideo", first searches for a section that contains a help item that is
/// associated with the feature "Filters", if not found, continues to "Clip" and so on. If no such
/// section found returns \c nil.
- (nullable NSString *)sectionKeyForPath:(NSString *)featureHierarchyPath;

/// Localized title of this help document. Localization is done by the localization method of
/// \c HUISettings.
@property (readonly, nonatomic) NSString *title;

/// Array of \c HUISection objects, each representing a help section.
@property (copy, readonly, nonatomic) NSArray<HUISection *> *sections;

/// Set of feature item titles that are associated with items in this document.
@property (readonly, nonatomic) NSSet<NSString *> *featureItemTitles;

@end

NS_ASSUME_NONNULL_END
