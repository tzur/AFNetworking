// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Dekel Avrahami.

#import "HUIItem.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark -
#pragma mark HUIItem
#pragma mark -

@implementation HUIItem

- (instancetype)init {
  if (self = [super init]) {
    _associatedFeatureItemTitles = @[];
  }
  return self;
}

+ (NSDictionary<NSString *, Class> *)itemTypeToClass {
  return @{
    @"text": [HUITextItem class],
    @"image": [HUIImageItem class],
    @"video": [HUIVideoItem class],
    @"slideshow": [HUISlideshowItem class],
  };
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
  return @{
    @instanceKeypath(HUIItem, associatedFeatureItemTitles):
          @"associated_feature_item_titles",
  };
}

+ (Class)classForParsingJSONDictionary:(NSDictionary *)JSONDictionary {
  NSString *type = JSONDictionary[@"type"];
  LTParameterAssert(type, @"No type is given.");

  Class itemClass = [[self class] itemTypeToClass][type];
  LTParameterAssert(itemClass, @"Given type %@ is not one of the valid.", type);

  return itemClass;
}

@end

#pragma mark -
#pragma mark HUITextItem
#pragma mark -

@implementation HUITextItem

- (void)setText:(NSString *)text {
  _text = [HUIModelSettings localize:text];
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
  return [@{@instanceKeypath(HUITextItem, text): @"text"}
          mtl_dictionaryByAddingEntriesFromDictionary:[super JSONKeyPathsByPropertyKey]];
}

@end

#pragma mark -
#pragma mark HUIImageItem
#pragma mark -

@implementation HUIImageItem

+ (NSValueTransformer *)iconURLJSONTransformer {
  return [NSValueTransformer valueTransformerForName:MTLURLValueTransformerName];
}

- (void)setTitle:(NSString * _Nullable)title {
  _title = [HUIModelSettings localize:title];
}

- (void)setBody:(NSString * _Nullable)body {
  _body = [HUIModelSettings localize:body];
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
  return [@{
    @instanceKeypath(HUIImageItem, image): @"image",
    @instanceKeypath(HUIImageItem, title): @"title",
    @instanceKeypath(HUIImageItem, body): @"body",
    @instanceKeypath(HUIImageItem, iconURL): @"icon_url",
  } mtl_dictionaryByAddingEntriesFromDictionary:[super JSONKeyPathsByPropertyKey]];
}

@end

#pragma mark -
#pragma mark HUIVideoItem
#pragma mark -

@implementation HUIVideoItem

- (void)setTitle:(NSString * _Nullable)title {
  _title = [HUIModelSettings localize:title];
}

- (void)setBody:(NSString * _Nullable)body {
  _body = [HUIModelSettings localize:body];
}

+ (NSValueTransformer *)iconURLJSONTransformer {
  return [NSValueTransformer valueTransformerForName:MTLURLValueTransformerName];
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
  return [@{
    @instanceKeypath(HUIVideoItem, video): @"video",
    @instanceKeypath(HUIVideoItem, title): @"title",
    @instanceKeypath(HUIVideoItem, body): @"body",
    @instanceKeypath(HUIVideoItem, iconURL): @"icon_url",
  } mtl_dictionaryByAddingEntriesFromDictionary:[super JSONKeyPathsByPropertyKey]];
}

@end

#pragma mark -
#pragma mark HUISlideshowItem
#pragma mark -

@implementation HUISlideshowItem

static NSDictionary * const kSlideshowItemDefaultsForCurtain = @{
  @instanceKeypath(HUISlideshowItem, stillDuration): @1.25,
  @instanceKeypath(HUISlideshowItem, transitionDuration): @1.25,
};

static NSDictionary * const kSlideshowItemDefaultsForFade = @{
  @instanceKeypath(HUISlideshowItem, stillDuration): @1.5,
  @instanceKeypath(HUISlideshowItem, transitionDuration): @0.65,
};

- (instancetype)init {
  if (self = [super init]) {
    _transition = HUISlideshowTransitionCurtain;
    _stillDuration = [kSlideshowItemDefaultsForCurtain[@keypath(self, stillDuration)] doubleValue];
    _transitionDuration = [kSlideshowItemDefaultsForCurtain[@keypath(self, transitionDuration)]
                           doubleValue];
  }
  return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionaryValue
                             error:(NSError *__autoreleasing *)error {
  NSDictionary *defaults = @{};
  NSNumber *transitionValue = dictionaryValue[@keypath(self, transition)];
  if (transitionValue) {
    auto transition = (HUISlideshowTransition)[transitionValue unsignedIntegerValue];
    switch (transition) {
      case HUISlideshowTransitionCurtain:
        defaults = kSlideshowItemDefaultsForCurtain;
        break;
      case HUISlideshowTransitionFade:
        defaults = kSlideshowItemDefaultsForFade;
        break;
    }
  }

  dictionaryValue = [defaults mtl_dictionaryByAddingEntriesFromDictionary:dictionaryValue];
  return [super initWithDictionary:dictionaryValue error:error];
}

+ (NSValueTransformer *)transitionJSONTransformer {
  return [NSValueTransformer mtl_valueMappingTransformerWithDictionary:@{
    @"curtain": @(HUISlideshowTransitionCurtain),
    @"fade": @(HUISlideshowTransitionFade),
  }];
}

+ (NSValueTransformer *)iconURLJSONTransformer {
  return [NSValueTransformer valueTransformerForName:MTLURLValueTransformerName];
}

- (void)setTitle:(NSString * _Nullable)title {
  _title = [HUIModelSettings localize:title];
}

- (void)setBody:(NSString * _Nullable)body {
  _body = [HUIModelSettings localize:body];
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
  return [@{
    @instanceKeypath(HUISlideshowItem, title): @"title",
    @instanceKeypath(HUISlideshowItem, body): @"body",
    @instanceKeypath(HUISlideshowItem, iconURL): @"icon_url",
    @instanceKeypath(HUISlideshowItem, images): @"images",
    @instanceKeypath(HUISlideshowItem, transition): @"transition",
    @instanceKeypath(HUISlideshowItem, stillDuration): @"still_duration",
    @instanceKeypath(HUISlideshowItem, transitionDuration): @"transition_duration",
  } mtl_dictionaryByAddingEntriesFromDictionary:[super JSONKeyPathsByPropertyKey]];
}

@end

NS_ASSUME_NONNULL_END
