// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTMMInputFile.h"

#import <sys/fcntl.h>
#import <sys/mman.h>

#import "NSError+LTKit.h"

NS_ASSUME_NONNULL_BEGIN

@interface LTMMInputFile ()

/// Path to the memory mapped file.
@property (readwrite, nonatomic) NSString *path;

/// File descriptor of the memory mapped file.
@property (nonatomic) int fd;

/// Pointer to the mapped data.
@property (readwrite, nonatomic) const uint8_t *data;

/// Size of the buffer pointed by \c data.
@property (readwrite, nonatomic) size_t size;

@end

@implementation LTMMInputFile

- (instancetype)init {
  return nil;
}

- (nullable instancetype)initWithPath:(NSString *)path error:(NSError *__autoreleasing *)error {
  if (self = [super init]) {
    self.path = path;

    self.fd = open([path UTF8String], O_RDONLY);
    if (self.fd < 0) {
      if (error) {
        *error = [NSError lt_errorWithCode:LTErrorCodeFileReadFailed path:path
                           underlyingError:[NSError lt_errorWithSystemError]];
      }
      return nil;
    }

    off_t offset = lseek(self.fd, 0, SEEK_END);
    if (offset == -1) {
      if (error) {
        *error = [NSError lt_errorWithCode:LTErrorCodeFileReadFailed path:path
                           underlyingError:[NSError lt_errorWithSystemError]];
      }
      return nil;
    }
    self.size = (size_t)offset;
    if (lseek(self.fd, 0, SEEK_SET) == -1) {
      if (error) {
        *error = [NSError lt_errorWithCode:LTErrorCodeFileReadFailed path:path
                           underlyingError:[NSError lt_errorWithSystemError]];
      }
      return nil;
    }

    self.data = (uint8_t *)mmap(0, _size, PROT_READ, MAP_FILE | MAP_PRIVATE, self.fd, 0);
    if (self.data == MAP_FAILED) {
      if (error) {
        *error = [NSError lt_errorWithCode:LTErrorCodeFileReadFailed path:path
                           underlyingError:[NSError lt_errorWithSystemError]];
      }
      return nil;
    }
  }
  return self;
}

- (void)dealloc {
  if (self.data && self.data != MAP_FAILED) {
    if (munmap((void *)self.data, self.size) == -1) {
      LogError(@"Failed unmapping file from memory: %@", LTSystemErrorMessageForError(errno));
    }
  }

  if (self.fd >= 0) {
    if (close(self.fd) == -1) {
      LogError(@"Failed closing file: %d: %@", _fd, LTSystemErrorMessageForError(errno));
    }
  }
}

@end

NS_ASSUME_NONNULL_END
