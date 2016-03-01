// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNDropboxTestUtils.h"

#import <DropboxSDK/DropboxSDK.h>

NS_ASSUME_NONNULL_BEGIN

DBMetadata *PTNDropboxCreateFileMetadata(NSString *path, NSString * _Nullable revision) {
  DBMetadata *metadata = PTNDropboxCreateMetadata(path, revision);
  OCMStub([metadata isDirectory]).andReturn(NO);
  return metadata;
}

DBMetadata *PTNDropboxCreateFileMetadataWithModificationDate(NSString *path,
                                                             NSString * _Nullable revision,
                                                             NSDate * _Nullable lastModified) {
  DBMetadata *metadata = PTNDropboxCreateFileMetadata(path, revision);
  OCMStub([metadata lastModifiedDate]).andReturn(lastModified);
  return metadata;
}

DBMetadata *PTNDropboxCreateDirectoryMetadataWithContents(NSString *path,
                                                          NSArray<DBMetadata *> *contents) {
  DBMetadata *metadata = PTNDropboxCreateDirectoryMetadata(path);
  OCMStub([metadata contents]).andReturn(contents);
  return metadata;
}

DBMetadata *PTNDropboxCreateDirectoryMetadata(NSString *path) {
  DBMetadata *metadata = PTNDropboxCreateMetadata(path, nil);
  OCMStub([metadata isDirectory]).andReturn(YES);
  return metadata;
}

DBMetadata *PTNDropboxCreateMetadata(NSString *path, NSString * _Nullable revision) {
  DBMetadata *metadata = OCMClassMock([DBMetadata class]);
  OCMStub([metadata path]).andReturn(path);
  OCMStub([metadata rev]).andReturn(revision);
  return metadata;
}

NSError *PTNDropboxErrorWithPathInfo(NSString *path) {
  return [NSError errorWithDomain:@"Dropbox" code:0 userInfo:@{@"path": path}];
}

NS_ASSUME_NONNULL_END
