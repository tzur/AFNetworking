// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTMMOutputFile.h"

#import <sys/fcntl.h>
#import <sys/mman.h>

@interface LTMMOutputFile ()

/// Path to the memory mapped file.
@property (readwrite, nonatomic) NSString *path;

/// File descriptor of the memory mapped file.
@property (nonatomic) int fd;

/// Pointer to the mapped data.
@property (readwrite, nonatomic) uint8_t *data;

/// Size of the buffer pointed by \c data.
@property (readwrite, nonatomic) size_t size;

@end

@implementation LTMMOutputFile

- (instancetype)init {
  return nil;
}

- (instancetype)initWithPath:(NSString *)path size:(size_t)size mode:(mode_t)mode
                       error:(NSError *__autoreleasing *)error {
  if (self = [super init]) {
    self.path = path;
    
    self.fd = open([path UTF8String], O_RDWR | O_CREAT, mode);
    if (self.fd < 0) {
      if (error) {
        *error = [NSError lt_errorWithCode:LTErrorCodeFileWriteFailed path:path
                           underlyingError:[NSError lt_errorWithSystemError]];
      }
      return nil;
    }

    if (ftruncate(self.fd, size) == -1) {
      if (error) {
        *error = [NSError lt_errorWithCode:LTErrorCodeFileWriteFailed path:path
                           underlyingError:[NSError lt_errorWithSystemError]];
      }
      return nil;
    }

    self.data = (uint8_t *)mmap(0, size, PROT_READ | PROT_WRITE, MAP_FILE | MAP_SHARED, self.fd, 0);
    if (self.data == MAP_FAILED) {
      if (error) {
        *error = [NSError lt_errorWithCode:LTErrorCodeFileWriteFailed path:path
                           underlyingError:[NSError lt_errorWithSystemError]];
      }
      return nil;
    }

    self.size = size;
    self.finalSize = size;
  }
  return self;
}

- (void)dealloc {
  if (self.data && self.data != MAP_FAILED) {
    if (munmap(self.data, self.size) == -1) {
      LogError(@"Failed unmapping file from memory: %@", LTSystemErrorMessageForError(errno));
    }
  }

  if (self.fd >= 0) {
    if (self.size != self.finalSize) {
      if (ftruncate(self.fd, self.finalSize) == -1) {
        LogError(@"Failed to truncate file to size %lu: %@", (unsigned long)self.finalSize,
                 LTSystemErrorMessageForError(errno));
      }
    }

    if (close(self.fd) == -1) {
      LogError(@"Failed closing file: %d: %@", _fd, LTSystemErrorMessageForError(errno));
    }
  }
}

@end
