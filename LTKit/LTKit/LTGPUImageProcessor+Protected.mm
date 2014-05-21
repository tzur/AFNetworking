// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTGPUImageProcessor+Protected.h"

@interface LTGPUImageProcessor ()

/// Drawer to use while processing.
@property (strong, nonatomic) id<LTProcessingDrawer> drawer;

@end

@implementation LTGPUImageProcessor (Protected)

- (void)setObject:(id)obj forKeyedSubscript:(NSString *)key {
  [self.drawer setUniform:key withValue:obj];
}

- (id)objectForKeyedSubscript:(NSString *)key {
  return [self.drawer uniformForName:key];
}

- (void)setAuxiliaryTexture:(LTTexture *)texture withName:(NSString *)name {
  NSMutableDictionary *auxiliaryTextures = [self.auxiliaryTextures mutableCopy];
  auxiliaryTextures[name] = texture;
  objc_setAssociatedObject(self, @selector(auxiliaryTextures), [auxiliaryTextures copy],
                           OBJC_ASSOCIATION_RETAIN_NONATOMIC);

  [self.drawer setAuxiliaryTexture:texture withName:name];
}

- (NSDictionary *)auxiliaryTextures {
  return objc_getAssociatedObject(self, @selector(auxiliaryTextures));
}

- (void)setAuxiliaryTextures:(NSDictionary *)auxiliaryTextures {
  objc_setAssociatedObject(self, @selector(auxiliaryTextures), auxiliaryTextures,
                           OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  [auxiliaryTextures enumerateKeysAndObjectsUsingBlock:^(NSString *key, LTTexture *obj, BOOL *) {
    [self.drawer setAuxiliaryTexture:obj withName:key];
  }];
}

@end
