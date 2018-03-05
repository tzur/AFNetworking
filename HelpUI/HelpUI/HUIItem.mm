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

- (void)setTitle:(NSString * _Nullable)title {
  _title = [[HUISettings instance] localize:title];
}

- (void)setBody:(NSString * _Nullable)body {
  _body = [[HUISettings instance] localize:body];
}

+ (NSDictionary<NSString *, Class> *)itemTypeToClass {
  return @{
    @"image": [HUIImageItem class],
    @"video": [HUIVideoItem class],
    @"slideshow": [HUISlideshowItem class],
  };
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
  return @{
    @instanceKeypath(HUIItem, title): @"title",
    @instanceKeypath(HUIItem, body): @"body",
    @instanceKeypath(HUIItem, iconURL): @"icon_url",
    @instanceKeypath(HUIItem, associatedFeatureItemTitles): @"associated_feature_item_titles",
  };
}

+ (NSValueTransformer *)iconURLJSONTransformer {
  return [NSValueTransformer valueTransformerForName:MTLURLValueTransformerName];
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
#pragma mark HUIImageItem
#pragma mark -

@implementation HUIImageItem

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
  return [@{
    @instanceKeypath(HUIImageItem, image): @"image",
  } mtl_dictionaryByAddingEntriesFromDictionary:[super JSONKeyPathsByPropertyKey]];
}

@end

#pragma mark -
#pragma mark HUIVideoItem
#pragma mark -

@implementation HUIVideoItem

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
  return [@{
    @instanceKeypath(HUIVideoItem, video): @"video",
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

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
  return [@{
    @instanceKeypath(HUISlideshowItem, images): @"images",
    @instanceKeypath(HUISlideshowItem, transition): @"transition",
    @instanceKeypath(HUISlideshowItem, stillDuration): @"still_duration",
    @instanceKeypath(HUISlideshowItem, transitionDuration): @"transition_duration",
  } mtl_dictionaryByAddingEntriesFromDictionary:[super JSONKeyPathsByPropertyKey]];
}

@end

NS_ASSUME_NONNULL_END
