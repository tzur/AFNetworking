// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTFboPool.h"

#import <LTKit/LTHashExtensions.h>

#import "LTFbo.h"
#import "LTFboAttachable.h"
#import "LTFboAttachmentInfo.h"
#import "LTGLContext.h"
#import "LTRenderbuffer.h"
#import "LTTexture.h"

NS_ASSUME_NONNULL_BEGIN

/// Holds primitives of \c LTFboAttachable which serve as a key to the cache.
typedef struct {
  /// Attachment's type.
  LTFboAttachableType type;
  /// OpenGL unique identifier.
  GLuint name;
  /// Attachment level.
  GLint level;
  /// Fbo attachment point.
  LTFboAttachmentPoint attachmentPoint;
} LTFboAttachmentDescriptor;

constexpr bool operator==(LTFboAttachmentDescriptor lhs, LTFboAttachmentDescriptor rhs) {
  return lhs.type == rhs.type && lhs.name == rhs.name && lhs.level == rhs.level &&
      lhs.attachmentPoint == rhs.attachmentPoint;
}

/// Object representing framebuffer's attachments.
@interface LTFboAttachmentsDescriptor : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given \c infos, which maps \c LTFboAttachmentPoint to
/// \c LTFboAttachmentInfo.
+ (instancetype)withAttachableInfos:(NSDictionary<NSNumber *, LTFboAttachmentInfo *> *)infos;

/// Initializes with the given \c attachables, which maps \c LTFboAttachmentPoint to
/// \c LTFboAttachable.
+ (instancetype)withAttachables:(NSDictionary<NSNumber *, id<LTFboAttachable>> *)attachables;

/// Attachments held by this instance.
@property (readonly, nonatomic) std::vector<LTFboAttachmentDescriptor> attachments;

@end

@implementation LTFboAttachmentsDescriptor

#pragma mark -
#pragma mark Initialization
#pragma mark -

+ (instancetype)withAttachables:(NSDictionary<NSNumber *, id<LTFboAttachable>> *)attachables {
  auto infos = [NSMutableDictionary<NSNumber *, LTFboAttachmentInfo *> dictionary];
  for (NSNumber *attachmentPoint in attachables) {
    infos[attachmentPoint] = [LTFboAttachmentInfo withAttachable:attachables[attachmentPoint]];
  }
  return [[self alloc] initWithAttachmentInfos:[infos copy]];
}

+ (instancetype)withAttachableInfos:(NSDictionary<NSNumber *, LTFboAttachmentInfo *> *)infos {
  return [[self alloc] initWithAttachmentInfos:infos];
}

- (instancetype)initWithAttachmentInfos:(NSDictionary<NSNumber *, LTFboAttachmentInfo *> *)infos {
  if (self = [super init]) {
    for (NSNumber *attachPoint in infos) {
      LTFboAttachmentInfo *info = infos[attachPoint];
      _attachments.push_back({
        .type = info.attachable.attachableType,
        .name = info.attachable.name,
        .level = info.level,
        .attachmentPoint = (LTFboAttachmentPoint)attachPoint.integerValue
      });
    }
  }
  return self;
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (NSUInteger)hash {
  std::size_t hash = 0;
  for (const auto &attachment : self.attachments) {
    lt::hash_combine<LTFboAttachableType>(hash, attachment.type);
    lt::hash_combine<GLuint>(hash, attachment.name);
    lt::hash_combine<GLint>(hash, attachment.level);
    lt::hash_combine<LTFboAttachmentPoint>(hash, attachment.attachmentPoint);
  }
  return hash;
}

- (BOOL)isEqual:(LTFboAttachmentsDescriptor *)object {
  if (self == object) {
    return YES;
  }

  if (![object isKindOfClass:[LTFboAttachmentsDescriptor class]]) {
    return NO;
  }

  return self->_attachments == object->_attachments;
}

- (NSString *)description {
  auto descriptions = [NSMutableArray<NSString *> array];
  [descriptions addObject:[NSString stringWithFormat:@"%@: %p", self.class, self]];
  for (auto const &attachment : self.attachments) {
    [descriptions addObject:[NSString stringWithFormat:@"type: %lu, name: %d, level: %lu, "
                             "point: %d", (unsigned long)attachment.type, attachment.name,
                             (unsigned long)attachment.level, attachment.attachmentPoint]];
  }
  return [NSString stringWithFormat:@"<%@>", [descriptions componentsJoinedByString:@", "]];
}

@end

@interface LTFboPool ()

/// Maps between an \c LTFboAttachableDescriptor and its associated \c LTFbo, which is held weakly.
@property (strong, nonatomic) NSMapTable *attachmentDescriptorToFbo;

@end

@implementation LTFboPool

- (instancetype)init {
  if (self = [super init]) {
    self.attachmentDescriptorToFbo = [NSMapTable strongToWeakObjectsMapTable];
  }
  return self;
}

+ (nullable instancetype)currentPool {
  return [LTGLContext currentContext].fboPool;
}

- (LTFbo *)fboWithTexture:(LTTexture *)texture {
  return [self fboWithTexture:texture level:0];
}

- (LTFbo *)fboWithTexture:(LTTexture *)texture level:(GLint)level {
  return [self fboWithAttachmentInfos:@{
    @(LTFboAttachmentPointColor0): [LTFboAttachmentInfo withAttachable:texture level:level]
  }];
}

- (LTFbo *)fboWithRenderbuffer:(LTRenderbuffer *)renderbuffer {
  return [self fboWithAttachmentInfos:@{
    @(LTFboAttachmentPointColor0): [LTFboAttachmentInfo withAttachable:renderbuffer]
  }];
}

- (LTFbo *)fboWithAttachables:(NSDictionary<NSNumber *, id<LTFboAttachable>> *)attachables {
  auto descriptor = [LTFboAttachmentsDescriptor withAttachables:attachables];

  LTFbo *existingFbo = [self.attachmentDescriptorToFbo objectForKey:descriptor];
  if (existingFbo) {
    return existingFbo;
  }

  auto newFbo = [[LTFbo alloc] initWithAttachables:attachables];
  [self.attachmentDescriptorToFbo setObject:newFbo forKey:descriptor];

  return newFbo;
}

- (LTFbo *)fboWithAttachmentInfos:(NSDictionary<NSNumber *, LTFboAttachmentInfo *> *)infos {
  auto descriptor = [LTFboAttachmentsDescriptor withAttachableInfos:infos];

  LTFbo *existingFbo = [self.attachmentDescriptorToFbo objectForKey:descriptor];
  if (existingFbo) {
    return existingFbo;
  }

  auto newFbo = [[LTFbo alloc] initWithAttachmentInfos:infos];
  [self.attachmentDescriptorToFbo setObject:newFbo forKey:descriptor];

  return newFbo;
}

@end

NS_ASSUME_NONNULL_END
