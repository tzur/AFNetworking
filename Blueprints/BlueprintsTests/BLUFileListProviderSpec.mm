// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "BLUFileListProvider.h"

#import <LTKit/NSFileManager+LTKit.h>

#import "BLUNode+Builder.h"

SpecBegin(BLUFileListProvider)

__block id fileManager;
__block BLUFileListProviderMappingBlock mappingBlock;

__block BLUFileListProvider *provider;

__block NSPredicate *predicate;
__block RACSignal *nodes;

beforeEach(^{
  fileManager = OCMClassMock([NSFileManager class]);
  mappingBlock = [^BLUNode *(NSString *filePath) {
    return BLUNode.builder().name(filePath).value(filePath).build();
  } copy];
  provider = [[BLUFileListProvider alloc] initWithFileManager:fileManager
                                                 mappingBlock:mappingBlock];

  predicate = [NSPredicate predicateWithValue:YES];

  nodes = [provider nodesForFilesInBaseDirectory:@"/foo" recursively:YES predicate:predicate];
});

it(@"should pass arguments to file manager", ^{
  [nodes testRecorder];

  OCMVerify([fileManager lt_globPath:@"/foo" recursively:YES withPredicate:predicate
                               error:[OCMArg anyObjectRef]]);
});

it(@"should return empty array of nodes if no files were found", ^{
  OCMExpect([fileManager lt_globPath:@"/foo" recursively:YES withPredicate:predicate
                               error:[OCMArg anyObjectRef]]).andReturn(@[]);

  expect(nodes).will.sendValues(@[@[]]);
});

it(@"should return array of nodes of files found", ^{
  NSArray<NSString *> *files = @[@"bar", @"baz"];
  OCMExpect([fileManager lt_globPath:@"/foo" recursively:YES withPredicate:predicate
                               error:[OCMArg anyObjectRef]]).andReturn(files);

  NSArray<BLUNode *> *mappedFiles = [[files.rac_sequence
    map:^NSString *(NSString *filename) {
      return [@"/foo" stringByAppendingPathComponent:filename];
    }]
    map:mappingBlock].array;
  expect(nodes).will.sendValues(@[mappedFiles]);
});

it(@"should complete after fetching file list", ^{
  NSArray<NSString *> *files = @[@"bar", @"baz"];
  OCMExpect([fileManager lt_globPath:@"/foo" recursively:YES withPredicate:predicate
                               error:[OCMArg anyObjectRef]]).andReturn(files);

  expect(nodes).will.complete();
});

it(@"should err if file listing failed", ^{
  NSError *error = [NSError lt_errorWithCode:LTErrorCodeFileUnknownError];
  OCMExpect([fileManager lt_globPath:@"/foo" recursively:YES withPredicate:predicate
                               error:[OCMArg setTo:error]]);

  expect(nodes).will.error();
});

SpecEnd
