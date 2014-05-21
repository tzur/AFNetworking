// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTTextureContentsBundleArchiver.h"

#import "LTImage.h"
#import "LTTexture.h"
#import "UIImage+Loading.h"

@interface LTTextureContentsBundleArchiver ()
@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSBundle *bundle;
@end

@implementation LTTextureContentsBundleArchiver

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithName:(NSString *)name {
  return [self initWithName:name bundle:[NSBundle mainBundle]];
}

- (instancetype)initWithName:(NSString *)name bundle:(NSBundle *)bundle {
  if (self = [super init]) {
    self.name = name;
    self.bundle = bundle;
  }
  return self;
}

#pragma mark -
#pragma mark NSCoding
#pragma mark -

- (id)initWithCoder:(NSCoder *)aDecoder {
  if (self = [super init]) {
    self.name = [aDecoder decodeObjectOfClass:[NSString class] forKey:@keypath(self, name)];
    self.bundle = [NSBundle bundleWithURL:[aDecoder decodeObjectForKey:@keypath(self, bundle)]];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
  [aCoder encodeObject:self.name forKey:@keypath(self, name)];
  [aCoder encodeObject:self.bundle.bundleURL forKey:@keypath(self, bundle)];
}

+ (BOOL)supportsSecureCoding {
  return YES;
}

#pragma mark -
#pragma mark Archiving
#pragma mark -

- (NSData *)archiveTexture:(LTTexture __unused *)texture
                     error:(NSError *__autoreleasing __unused *)error {
  // Nothing to do here - texture can be loaded from bundle.
  return [NSData data];
}

- (BOOL)unarchiveData:(NSData *)data toTexture:(LTTexture *)texture
                error:(NSError *__autoreleasing *)error {
  LTParameterAssert(data && !data.length, @"Given data must be an empty NSData object");

  UIImage *image = [UIImage imageNamed:self.name fromBundle:self.bundle];
  if (!image) {
    if (error) {
      *error = [NSError errorWithDomain:kLTKitErrorDomain code:NSFileNoSuchFileError
                               userInfo:@{NSFilePathErrorKey: self.name,
                                          NSURLErrorKey: self.bundle.resourceURL}];
    }
    return NO;
  }

  LTImage *ltImage = [[LTImage alloc] initWithImage:image];
  [texture load:ltImage.mat];

  return YES;
}

@end
