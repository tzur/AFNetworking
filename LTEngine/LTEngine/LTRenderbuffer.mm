// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTRenderbuffer.h"

#import "LTFboWritableAttachment.h"
#import "LTGLContext.h"
#import "LTGLPixelFormat.h"
#import "LTRenderbuffer+Writing.h"

NS_ASSUME_NONNULL_BEGIN

@interface LTRenderbuffer ()

/// OpenGL name of the renderbuffer.
@property (readwrite, nonatomic) GLuint name;

/// \c YES if the renderbuffer is currently bound.
@property (nonatomic) BOOL bound;

/// Set to the previously bound renderbuffer, or \c 0 if renderbuffer is not bound.
@property (nonatomic) GLint previousRenderbuffer;

/// Pixel format of the attachment.
@property (readwrite, nonatomic) LTGLPixelFormat *pixelFormat;

/// Current generation ID of the attachment.
@property (readwrite, nonatomic) NSString *generationID;

/// Color the renderbuffed is filled with, or \c LTVector4::null() if the fill color is
/// undetermined.
@property (readwrite, nonatomic) LTVector4 fillColor;

@end

@implementation LTRenderbuffer

- (instancetype)initWithDrawable:(id<EAGLDrawable>)drawable {
  if (self = [super init]) {
    _fillColor = LTVector4::null();

    [self updateGenerationID];
    [self createRenderbuffer];
    [self allocateRenderbufferStorageForDrawable:drawable];
    [self derivePixelFormat];
  }
  return self;
}

- (instancetype)initWithSize:(CGSize)size pixelFormat:(LTGLPixelFormat *)format {
  if (self = [super init]) {
    _fillColor = LTVector4::null();
    _pixelFormat = format;

    [self updateGenerationID];
    [self createRenderbuffer];
    [self allocateRenderbufferStorageWithSize:size];
  }
  return self;
}

- (void)createRenderbuffer {
  glGenRenderbuffers(1, &_name);
  LTGLCheck(@"Renderbuffer creation failed");
}

- (void)allocateRenderbufferStorageForDrawable:(id<EAGLDrawable>)drawable {
  __block BOOL storageCreated;

  [self bindAndExecute:^{
    storageCreated = [[LTGLContext currentContext].context renderbufferStorage:GL_RENDERBUFFER
                                                                  fromDrawable:drawable];
  }];

  LTAssert(storageCreated, @"Renderbuffer storage creation failed for drawable %@", drawable);
}

- (void)allocateRenderbufferStorageWithSize:(CGSize)size {
  [self bindAndExecute:^{
    auto contextVersion = [LTGLContext currentContext].version;
    auto internalFormat = [self.pixelFormat renderbufferInternalFormatForVersion:contextVersion];
    glRenderbufferStorage(GL_RENDERBUFFER, internalFormat, size.width, size.height);
    LTGLCheckDbg(@"Error when allocating renderbuffer storage with size: %@, format: %@",
                 NSStringFromCGSize(size), self.pixelFormat);
  }];
}

- (void)derivePixelFormat {
  __block GLint internalFormat;
  [self bindAndExecute:^{
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_INTERNAL_FORMAT, &internalFormat);
  }];

  _pixelFormat = [[LTGLPixelFormat alloc]
                  initWithRenderbufferInternalFormat:internalFormat
                  version:[LTGLContext currentContext].version];
}

- (void)dealloc {
  if (self.name) {
    glDeleteRenderbuffers(1, &_name);
    LTGLCheckDbg(@"Error deleting renderbuffer");
  }
}

#pragma mark -
#pragma mark LTGPUResource
#pragma mark -

- (void)bind {
  if (self.bound) {
    return;
  }
  glGetIntegerv(GL_RENDERBUFFER_BINDING, &_previousRenderbuffer);
  glBindRenderbuffer(GL_RENDERBUFFER, self.name);
  self.bound = YES;
}

- (void)unbind {
  if (!self.bound) {
    return;
  }
  glBindRenderbuffer(GL_RENDERBUFFER, self.previousRenderbuffer);
  self.previousRenderbuffer = 0;
  self.bound = NO;
}

- (void)bindAndExecute:(LTVoidBlock)block {
  LTParameterAssert(block);
  if (self.bound) {
    block();
  } else {
    [self bind];
    block();
    [self unbind];
  }
}

#pragma mark -
#pragma mark LTFboWritableAttachment
#pragma mark -

- (LTFboAttachableType)attachableType {
  return LTFboAttachableTypeRenderbuffer;
}

- (void)writeToAttachmentWithBlock:(LTVoidBlock)block {
  LTParameterAssert(block);

  block();
  self.fillColor = LTVector4::null();
  [self updateGenerationID];
}

- (void)clearAttachmentWithColor:(LTVector4)color block:(LTVoidBlock)block {
  block();
  self.fillColor = color;
  [self updateGenerationID];
}

- (void)updateGenerationID {
  self.generationID = [NSUUID UUID].UUIDString;
}

- (CGSize)size {
  __block CGSize size;

  [self bindAndExecute:^{
    GLint width, height;
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &width);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &height);
    size = CGSizeMake(width, height);
  }];

  return size;
}

#pragma mark -
#pragma mark Presentation
#pragma mark -

- (void)present {
  [self bindAndExecute:^{
    [[LTGLContext currentContext].context presentRenderbuffer:GL_RENDERBUFFER];
  }];
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@: %p, name: %u, pixelFormat: %@, fillColor: %@>",
          self.class, self, self.name, self.pixelFormat, NSStringFromLTVector4(self.fillColor)];
}

@end

NS_ASSUME_NONNULL_END
