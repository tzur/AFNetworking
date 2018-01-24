// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Dekel Avrahami.

NS_ASSUME_NONNULL_BEGIN

/// Class cluster for all help items. An item provides a single type of content, like text, image,
/// animation, etc. All help items are immutable.
///
/// @important The class is deserializable from JSON using Mantle. The \c type field must exist in
/// the JSON dictionary and it is used to decide which subclass to use: if the value of the \c type
/// field is foo, type the calss \c HUIFooItem will be used to deserializable the object.
///
/// @note The idea is to provide content and not its styling, but sometimes this rule has to be
/// broken. Try to minimise this breakage as much as reasonably possible.
@interface HUIItem : MTLModel <MTLJSONSerializing>

/// Non-localized titles of the associated feature items. The default value is an empty array
/// (no associated feature items). This maps a help item to feature items.
@property (readonly, nonatomic, nullable) NSArray<NSString *> *associatedFeatureItemTitles;

@end

/// Textual help item, a paragraph of text.
@interface HUITextItem : HUIItem

/// Localized text presented by this item.
@property (readonly, nonatomic) NSString *text;

@end

/// Help item based on an image with an optional textual label.
@interface HUIImageItem : HUIItem

/// Name of the image resource.
@property (readonly, nonatomic) NSString *image;

/// Title for the image. Can be \c nil.
@property (readonly, nonatomic, nullable) NSString *title;

/// Main content for the image. Can be \c nil.
@property (readonly, nonatomic, nullable) NSString *body;

/// URL of an icon shown alongside the image. Can be \c nil.
@property (readonly, nonatomic, nullable) NSURL *iconURL;

@end

/// Help item presenting a video.
@interface HUIVideoItem : HUIItem

/// Name of the video resource.
@property (readonly, nonatomic) NSString *video;

/// Title for the video. Can be \c nil.
@property (readonly, nonatomic, nullable) NSString *title;

/// Main content for this video. Can be \c nil.
@property (readonly, nonatomic, nullable) NSString *body;

/// URL of an icon shown alongside the video. Can be \c nil.
@property (readonly, nonatomic, nullable) NSURL *iconURL;

@end

/// Transition types supported by the slideshow item.
typedef NS_ENUM(NSUInteger, HUISlideshowTransition) {
  HUISlideshowTransitionCurtain,
  HUISlideshowTransitionFade,
};

/// Help item peresenting a slideshow of fixed number of slides.
@interface HUISlideshowItem : HUIItem

/// Title for the slideshow. Can be \c nil.
@property (readonly, nonatomic, nullable) NSString *title;

/// Main content for this slideshow. Can be \c nil.
@property (readonly, nonatomic, nullable) NSString *body;

/// URL of an icon shown alongside the slideshow. Can be \c nil.
@property (readonly, nonatomic, nullable) NSURL *iconURL;

/// Array of \c NSString with names of the images to use as slides.
@property (readonly, nonatomic) NSArray<NSString *> *images;

/// Transition type used to transition from slide to slide. Defaults to
/// \c HUISlideshowTransitionCurtain.
@property (readonly, nonatomic) HUISlideshowTransition transition;

/// Duration for holding a slide still. Optional. Defaults to 1.25. If this object is deserialized
/// from JSON that doesn't include this property, the default of this property is 1.25 if transition
/// is \c HUISlideshowTransitionCurtain and 1.5 if transition is \c HUISlideshowTransitionFade.
@property (readonly, nonatomic) NSTimeInterval stillDuration;

/// Duration for transition animation between slides. Optional. Defaults to 1.25. If this object is
/// deserialize from JSON that doesn't include this property, the default of this property is 1.25
/// if transition is \c HUISlideshowTransitionCurtain and 0.65 if transition is
/// \c HUISlideshowTransitionFade.
@property (readonly, nonatomic) NSTimeInterval transitionDuration;

@end

NS_ASSUME_NONNULL_END
