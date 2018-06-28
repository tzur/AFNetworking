// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Dekel Avrahami.

#import "WHSProjectStorage.h"

#import <LTKit/NSArray+NSSet.h>

#import "WHSProjectUpdateRequest.h"

SpecBegin(WHSProjectStorage)
__block NSURL *baseURL;
__block NSURL *invalidURL;
__block NSString *bundleID;
__block NSString *newBundleID;
__block WHSProjectStorage *storage;

beforeEach(^{
  baseURL = [NSURL fileURLWithPath:LTTemporaryPath(@"storage")];
  bundleID = @"dummyBundleID";
  newBundleID = @"newBundleID";
  invalidURL = nn([NSURL URLWithString:@"www.com"]);
  storage = [[WHSProjectStorage alloc] initWithBundleID:bundleID baseURL:baseURL];
});

context(@"create project", ^{
  __block NSUUID * _Nullable projectID;

  beforeEach(^{
    projectID = [storage createProjectWithError:nil];
  });

  afterEach(^{
    if (projectID) {
      [storage deleteProjectWithID:nn(projectID) error:nil];
    }
  });

  it(@"should return the ID of the new project", ^{
    expect(projectID).notTo.beNil();
  });

  it(@"should return nil and set WHSErrorCodeWriteFailed when fails to create project", ^{
    NSError *error;
    auto storageWithBadURL = [[WHSProjectStorage alloc] initWithBundleID:bundleID
                                                                 baseURL:invalidURL];

    auto _Nullable IDOfProjectInBadURL = [storageWithBadURL createProjectWithError:&error];

    expect(IDOfProjectInBadURL).to.beNil();
    expect(error.lt_isLTDomain).to.beTruthy();
    expect(error.code).to.equal(WHSErrorCodeWriteFailed);
  });

  it(@"should contain the created project in another storage with the same base URL", ^{
    auto storageWithSameBaseURL = [[WHSProjectStorage alloc] initWithBundleID:bundleID
                                                                      baseURL:baseURL];
    auto storageWithSameBaseURLProjects = [storageWithSameBaseURL
                                           projectsIDsSortedBy:$(WHSProjectCreationDate)
                                           descending:YES error:nil];

    expect(storageWithSameBaseURLProjects).to.contain(nn(projectID));
  });

  context(@"created project properties", ^{
    __block WHSProjectSnapshot *project;

    beforeEach(^{
      project = nn([storage fetchSnapshotOfProjectWithID:nn(projectID)
                                                 options:WHSProjectFetchOptionsFetchAll error:nil]);
    });

    it(@"should create project with no steps", ^{
      expect(project.stepsIDs).to.beEmpty();
    });

    it(@"should create project with step cursor at zero", ^{
      expect(project.stepCursor).to.equal(0);
    });

    it(@"should create project with an empty user data", ^{
      expect(project.userData).to.equal(@{});
    });

    it(@"should create project with the bundle ID of the storage", ^{
      auto newStorage = [[WHSProjectStorage alloc] initWithBundleID:newBundleID baseURL:baseURL];
      auto projectFromNewStorage = nn([newStorage
                                       fetchSnapshotOfProjectWithID:nn(projectID)
                                       options:WHSProjectFetchOptionsFetchAll error:nil]);

      expect(projectFromNewStorage.bundleID).to.equal(bundleID);
    });

    it(@"should create project with assets URL in base URL", ^{
      for (NSUInteger i = 0; i < baseURL.pathComponents.count; ++i) {
        expect(project.assetsURL.pathComponents[i]).equal(baseURL.pathComponents[i]);
      }
    });
  });
});

context(@"fetch project list", ^{
  __block WHSProjectStorage *storage;
  __block NSMutableArray<NSUUID *> *projectIDs;

  beforeEach(^{
    projectIDs = [[NSMutableArray alloc] init];
    storage = [[WHSProjectStorage alloc] initWithBundleID:bundleID baseURL:baseURL];
    for (NSUInteger i = 0; i < 5; ++i) {
      [projectIDs addObject:nn([storage createProjectWithError:nil])];
    }
  });

  afterEach(^{
    for (NSUUID *projectID in projectIDs) {
      [storage deleteProjectWithID:projectID error:nil];
    }
  });

  it(@"should fetch all created projects", ^{
    auto _Nullable fetchedProjectIDs = [[storage projectsIDsSortedBy:$(WHSProjectCreationDate)
                                                          descending:YES error:nil] lt_set];

    expect(fetchedProjectIDs).to.equal([projectIDs lt_set]);
  });

  it(@"should fetch empty array when there are no projects", ^{
    for (NSUUID *projectID in projectIDs) {
      [storage deleteProjectWithID:projectID error:nil];
    }

    auto _Nullable fetchedProjectIDs = [storage projectsIDsSortedBy:$(WHSProjectCreationDate)
                                                         descending:YES error:nil];

    expect(fetchedProjectIDs).to.beEmpty();
  });

  it(@"should return nil and set WHSErrorCodeFetchFailed when fails to fetch", ^{
    NSError *error;
    auto storageWithBadURL = [[WHSProjectStorage alloc] initWithBundleID:bundleID
                                                                 baseURL:invalidURL];

    auto _Nullable IDs = [storageWithBadURL projectsIDsSortedBy:$(WHSProjectCreationDate)
                                                     descending:YES error:&error];

    expect(IDs).to.beNil();
    expect(error.lt_isLTDomain).to.beTruthy();
    expect(error.code).to.equal(WHSErrorCodeFetchFailed);
  });

  context(@"sort by creation date", ^{
    beforeEach(^{
      for (NSUInteger i = 0; i < projectIDs.count; ++i) {
        auto creationDate = [NSDate dateWithTimeIntervalSince1970:i];
        [storage setCreationDate:creationDate toProjectWithID:projectIDs[i] error:nil];
      }
    });

    it(@"should fetch in creation date descending order", ^{
      auto fetchedIDs = nn([storage projectsIDsSortedBy:$(WHSProjectCreationDate) descending:YES
                                                  error:nil]);
      auto reversedProjectIDs = [[projectIDs reverseObjectEnumerator] allObjects];

      expect(fetchedIDs).to.equal(reversedProjectIDs);
    });

    it(@"should fetch in creation date ascending order", ^{
      auto fetchedIDs = nn([storage projectsIDsSortedBy:$(WHSProjectCreationDate) descending:NO
                                                  error:nil]);

      expect(fetchedIDs).to.equal(projectIDs);
    });
  });

  context(@"sort by modification date", ^{
    beforeEach(^{
      for (NSUInteger i = 0; i < projectIDs.count; ++i) {
        auto modificationDate = [NSDate dateWithTimeIntervalSince1970:i];
        [storage setModificationDate:modificationDate toProjectWithID:projectIDs[i] error:nil];
      }
    });

    it(@"should fetch in modification date descending order with WHSProjectModificationDate", ^{
      auto fetchedIDs = nn([storage projectsIDsSortedBy:$(WHSProjectModificationDate) descending:YES
                                                  error:nil]);
      auto reversedProjectIDs = [[projectIDs reverseObjectEnumerator] allObjects];

      expect(fetchedIDs).to.equal(reversedProjectIDs);
    });

    it(@"should fetch in modification date ascending order with WHSProjectModificationDate", ^{
      auto fetchedIDs = nn([storage projectsIDsSortedBy:$(WHSProjectModificationDate) descending:NO
                                                  error:nil]);

      expect(fetchedIDs).to.equal(projectIDs);
    });
  });
});

context(@"fetch project snapshot", ^{
  __block WHSProjectStorage *storage;
  __block NSUUID *projectID;

  beforeEach(^{
    storage = [[WHSProjectStorage alloc] initWithBundleID:bundleID baseURL:baseURL];
    projectID = nn([storage createProjectWithError:nil]);
  });

  afterEach(^{
    [storage deleteProjectWithID:projectID error:nil];
  });

  it(@"should fetch in default mode when options is empty", ^{
    auto _Nullable project = [storage fetchSnapshotOfProjectWithID:projectID options:0 error:nil];

    expect(project.ID).to.equal(projectID);
    expect(project.bundleID).to.equal(bundleID);
    expect(project.creationDate).notTo.beNil();
    expect(project.modificationDate).notTo.beNil();
    expect(project.size).to.beGreaterThan(0);
    expect(project.stepsIDs).to.beNil();
    expect(project.stepCursor).to.beGreaterThanOrEqualTo(0);
    expect(project.userData).to.beNil();
    expect(project.assetsURL).notTo.beNil();
  });

  it(@"should fetch all properties with WHSProjectFetchOptionsFetchAll", ^{
    auto _Nullable project = [storage fetchSnapshotOfProjectWithID:projectID
                                                           options:WHSProjectFetchOptionsFetchAll
                                                             error:nil];

    expect(project.ID).to.equal(projectID);
    expect(project.bundleID).to.equal(bundleID);
    expect(project.creationDate).notTo.beNil();
    expect(project.modificationDate).notTo.beNil();
    expect(project.size).to.beGreaterThan(0);
    expect(project.stepsIDs).notTo.beNil();
    expect(project.stepCursor).to.beGreaterThanOrEqualTo(0);
    expect(project.userData).notTo.beNil();
    expect(project.assetsURL).notTo.beNil();
  });

  it(@"should fetch in default mode plus user data with WHSProjectFetchOptionsFetchUserData", ^{
    auto _Nullable project = [storage
                              fetchSnapshotOfProjectWithID:projectID
                              options:WHSProjectFetchOptionsFetchUserData error:nil];

    expect(project.ID).to.equal(projectID);
    expect(project.bundleID).to.equal(bundleID);
    expect(project.creationDate).notTo.beNil();
    expect(project.modificationDate).notTo.beNil();
    expect(project.size).to.beGreaterThan(0);
    expect(project.stepsIDs).to.beNil();
    expect(project.stepCursor).to.beGreaterThanOrEqualTo(0);
    expect(project.userData).notTo.beNil();
    expect(project.assetsURL).notTo.beNil();
  });

  it(@"should fetch in default mode plus steps IDs with WHSProjectFetchOptionsFetchStepsIDs", ^{
    auto _Nullable project = [storage
                              fetchSnapshotOfProjectWithID:projectID
                              options:WHSProjectFetchOptionsFetchStepsIDs error:nil];

    expect(project.ID).to.equal(projectID);
    expect(project.bundleID).to.equal(bundleID);
    expect(project.creationDate).notTo.beNil();
    expect(project.modificationDate).notTo.beNil();
    expect(project.size).to.beGreaterThan(0);
    expect(project.stepsIDs).notTo.beNil();
    expect(project.stepCursor).to.beGreaterThanOrEqualTo(0);
    expect(project.userData).to.beNil();
    expect(project.assetsURL).notTo.beNil();
  });

  it(@"should return nil and set WHSErrorCodeFetchFailed when fails to fetch", ^{
    NSError *error;

    auto _Nullable project = [storage fetchSnapshotOfProjectWithID:[NSUUID UUID] options:0
                                                             error:&error];

    expect(project).to.beNil();
    expect(error.lt_isLTDomain).to.beTruthy();
    expect(error.code).to.equal(WHSErrorCodeFetchFailed);
  });
});

context(@"delete project", ^{
  __block WHSProjectStorage *storage;
  __block NSUUID *projectID;
  __block NSUUID *anotherProjectID;

  beforeEach(^{
    storage = [[WHSProjectStorage alloc] initWithBundleID:bundleID baseURL:baseURL];
    projectID = nn([storage createProjectWithError:nil]);
    anotherProjectID = nn([storage createProjectWithError:nil]);
  });

  afterEach(^{
    [storage deleteProjectWithID:projectID error:nil];
    [storage deleteProjectWithID:anotherProjectID error:nil];
  });

  it(@"should delete the project given as input", ^{
    auto result = [storage deleteProjectWithID:projectID error:nil];

    expect(result).to.beTruthy();
    auto _Nullable projectsAfterDelete =
        [storage projectsIDsSortedBy:$(WHSProjectCreationDate) descending:YES error:nil];
    expect(projectsAfterDelete).notTo.contain(projectID);
  });

  it(@"should not delete project that is not given as input", ^{
    auto result = [storage deleteProjectWithID:projectID error:nil];

    expect(result).to.beTruthy();
    auto _Nullable projectsAfterDelete =
        [storage projectsIDsSortedBy:$(WHSProjectCreationDate) descending:YES error:nil];
    expect(projectsAfterDelete).to.contain(anotherProjectID);
  });

  it(@"should return NO and set WHSErrorCodeDeleteFailed if the input project does not exist", ^{
    NSError *error;
    auto result = [storage deleteProjectWithID:[NSUUID UUID] error:&error];

    expect(result).to.beFalsy();
    expect(error.lt_isLTDomain).to.beTruthy();
    expect(error.code).to.equal(WHSErrorCodeDeleteFailed);
  });

  it(@"should return NO and set WHSErrorCodeDeleteFailed when fails to delete", ^{
    NSError *error;
    auto storageWithBadURL = [[WHSProjectStorage alloc] initWithBundleID:bundleID
                                                                 baseURL:invalidURL];

    auto result = [storageWithBadURL deleteProjectWithID:[NSUUID UUID] error:&error];

    expect(result).to.beFalsy();
    expect(error.lt_isLTDomain).to.beTruthy();
    expect(error.code).to.equal(WHSErrorCodeDeleteFailed);
  });
});

context(@"update project", ^{
  __block WHSProjectStorage *storage;
  __block NSUUID *projectID;
  __block WHSStepContent *stepContent;
  __block NSString *stepAssetName;
  __block NSString *stepAssetContent;

  beforeEach(^{
    storage = [[WHSProjectStorage alloc] initWithBundleID:bundleID baseURL:baseURL];
    projectID = nn([storage createProjectWithError:nil]);
    auto stepUserData = @{@"importantData": @"air", @"notSoImportantData": @(90210)};
    auto stepAssetsURL = [NSURL fileURLWithPath:LTTemporaryPath(@"stepAssets")];
    [[NSFileManager defaultManager] createDirectoryAtURL:stepAssetsURL
                             withIntermediateDirectories:YES attributes:nil error:nil];
    stepAssetName = @"asset";
    auto stepAssetPath = nn([stepAssetsURL URLByAppendingPathComponent:stepAssetName].path);
    [[NSFileManager defaultManager] createFileAtPath:stepAssetPath contents:nil attributes:nil];
    stepAssetContent = @"large amount of data";
    [stepAssetContent writeToFile:stepAssetPath atomically:YES encoding:NSUTF8StringEncoding
                            error:nil];
    stepContent = [[WHSStepContent alloc] init];
    stepContent.userData = stepUserData;
    stepContent.assetsSourceURL = stepAssetsURL;
  });

  afterEach(^{
    [storage deleteProjectWithID:projectID error:nil];
  });

  it(@"should add a step", ^{
    auto request = [[WHSProjectUpdateRequest alloc] initWithProjectID:projectID];
    request.stepsContentToAdd = @[stepContent];

    auto result = [storage updateProjectWithRequest:request error:nil];

    expect(result).to.beTruthy();
    auto _Nullable projectAfterAdding = [storage
                                         fetchSnapshotOfProjectWithID:projectID
                                         options:WHSProjectFetchOptionsFetchStepsIDs error:nil];
    expect(projectAfterAdding.stepsIDs).to.haveCountOf(1);
  });

  it(@"should add a step with the given user data", ^{
    auto request = [[WHSProjectUpdateRequest alloc] initWithProjectID:projectID];
    request.stepsContentToAdd = @[stepContent];

    [storage updateProjectWithRequest:request error:nil];

    auto projectAfterAdding = nn([storage
                                  fetchSnapshotOfProjectWithID:projectID
                                  options:WHSProjectFetchOptionsFetchStepsIDs error:nil]);
    auto _Nullable step = [storage fetchStepWithID:nn(projectAfterAdding.stepsIDs)[0]
                                 fromProjectWithID:projectID error:nil];
    expect(step.userData).to.equal(stepContent.userData);
  });

  it(@"should move given assets to step storage when adding a step", ^{
    auto request = [[WHSProjectUpdateRequest alloc] initWithProjectID:projectID];
    request.stepsContentToAdd = @[stepContent];

    [storage updateProjectWithRequest:request error:nil];

    auto projectAfterAdding = nn([storage
                                  fetchSnapshotOfProjectWithID:projectID
                                  options:WHSProjectFetchOptionsFetchStepsIDs error:nil]);
    auto step = nn([storage fetchStepWithID:nn(projectAfterAdding.stepsIDs)[0]
                          fromProjectWithID:projectID error:nil]);
    auto AddedAssetPath = nn([step.assetsURL URLByAppendingPathComponent:stepAssetName].path);
    expect([[NSFileManager defaultManager] fileExistsAtPath:AddedAssetPath]).to.beTruthy();
    auto _Nullable addedAssetContent = [NSString stringWithContentsOfFile:AddedAssetPath
                                                                 encoding:NSUTF8StringEncoding
                                                                    error:nil];
    expect(addedAssetContent).to.equal(stepAssetContent);
    auto assetSourcePath = nn(stepContent.assetsSourceURL.path);
    expect([[NSFileManager defaultManager] fileExistsAtPath:assetSourcePath]).to.beFalsy();
  });

  it(@"should add multiple steps", ^{
    auto request = [[WHSProjectUpdateRequest alloc] initWithProjectID:projectID];
    auto secondStepContent = [[WHSStepContent alloc] init];
    secondStepContent.userData = @{};
    request.stepsContentToAdd = @[stepContent, secondStepContent];

    auto result = [storage updateProjectWithRequest:request error:nil];

    expect(result).to.beTruthy();
    auto _Nullable projectAfterAdding = [storage
                                         fetchSnapshotOfProjectWithID:projectID
                                         options:WHSProjectFetchOptionsFetchStepsIDs error:nil];
    expect(projectAfterAdding.stepsIDs).to.haveCountOf(2);
  });

  it(@"should not add steps when added steps content array is empty", ^{
    auto addRequest = [[WHSProjectUpdateRequest alloc] initWithProjectID:projectID];
    addRequest.stepsContentToAdd = @[stepContent];
    addRequest.stepCursor = @(1);
    [storage updateProjectWithRequest:addRequest error:nil];
    auto expectedStepsIDs = nn([storage
                                fetchSnapshotOfProjectWithID:projectID
                                options:WHSProjectFetchOptionsFetchStepsIDs error:nil]).stepsIDs;
    auto request = [[WHSProjectUpdateRequest alloc] initWithProjectID:projectID];
    request.stepsContentToAdd = @[];

    auto result = [storage updateProjectWithRequest:request error:nil];

    expect(result).to.beTruthy();
    auto _Nullable projectAfterAdding = [storage
                                         fetchSnapshotOfProjectWithID:projectID
                                         options:WHSProjectFetchOptionsFetchStepsIDs error:nil];
    expect(projectAfterAdding.stepsIDs).to.equal(expectedStepsIDs);
  });

  it(@"should return NO and set WHSErrorCodeWriteFailed if added step has invalid assets URL", ^{
    NSError *error;
    auto request = [[WHSProjectUpdateRequest alloc] initWithProjectID:projectID];
    auto invalidStepContent = [[WHSStepContent alloc] init];
    invalidStepContent.userData = @{};
    invalidStepContent.assetsSourceURL = [[NSURL alloc] init];
    request.stepsContentToAdd = @[invalidStepContent];

    auto result = [storage updateProjectWithRequest:request error:&error];

    expect(result).to.beFalsy();
    expect(error.lt_isLTDomain).to.beTruthy();
    expect(error.code).to.equal(WHSErrorCodeWriteFailed);
  });

  it(@"should delete step", ^{
    auto addRequest = [[WHSProjectUpdateRequest alloc] initWithProjectID:projectID];
    auto secondStepContent = [[WHSStepContent alloc] init];
    secondStepContent.userData = @{};
    addRequest.stepsContentToAdd = @[stepContent, secondStepContent];
    [storage updateProjectWithRequest:addRequest error:nil];
    auto stepsBeforeDelete = nn([storage
                                 fetchSnapshotOfProjectWithID:projectID
                                 options:WHSProjectFetchOptionsFetchStepsIDs error:nil].stepsIDs);
    auto delRequest = [[WHSProjectUpdateRequest alloc] initWithProjectID:projectID];
    delRequest.stepIDsToDelete = @[stepsBeforeDelete[0]];

    auto result = [storage updateProjectWithRequest:delRequest error:nil];

    expect(result).to.beTruthy();
    auto _Nullable projectAfterDelete = [storage
                                         fetchSnapshotOfProjectWithID:projectID
                                         options:WHSProjectFetchOptionsFetchStepsIDs error:nil];
    expect(projectAfterDelete.stepsIDs).to.equal(@[stepsBeforeDelete[1]]);
  });

  it(@"should delete multiple steps", ^{
    auto addRequest = [[WHSProjectUpdateRequest alloc] initWithProjectID:projectID];
    auto secondStepContent = [[WHSStepContent alloc] init];
    secondStepContent.userData = @{};
    addRequest.stepsContentToAdd = @[stepContent, secondStepContent];
    [storage updateProjectWithRequest:addRequest error:nil];
    auto delRequest = [[WHSProjectUpdateRequest alloc] initWithProjectID:projectID];
    delRequest.stepIDsToDelete = nn([storage
                                     fetchSnapshotOfProjectWithID:projectID
                                     options:WHSProjectFetchOptionsFetchStepsIDs
                                     error:nil].stepsIDs);

    auto result = [storage updateProjectWithRequest:delRequest error:nil];

    expect(result).to.beTruthy();
    auto _Nullable projectAfterDelete = [storage
                                         fetchSnapshotOfProjectWithID:projectID
                                         options:WHSProjectFetchOptionsFetchStepsIDs error:nil];
    expect(projectAfterDelete.stepsIDs).to.beEmpty();
  });

  it(@"shoulds ignore step to delete that is not in project", ^{
    auto addRequest = [[WHSProjectUpdateRequest alloc] initWithProjectID:projectID];
    addRequest.stepsContentToAdd = @[stepContent];
    [storage updateProjectWithRequest:addRequest error:nil];
    auto stepsBeforeDelete = nn([storage
                                 fetchSnapshotOfProjectWithID:projectID
                                 options:WHSProjectFetchOptionsFetchStepsIDs error:nil].stepsIDs);
    auto delRequest = [[WHSProjectUpdateRequest alloc] initWithProjectID:projectID];
    delRequest.stepIDsToDelete = @[[NSUUID UUID]];

    auto result = [storage updateProjectWithRequest:delRequest error:nil];

    expect(result).to.beTruthy();
    auto _Nullable projectAfterDelete = [storage
                                         fetchSnapshotOfProjectWithID:projectID
                                         options:WHSProjectFetchOptionsFetchStepsIDs error:nil];
    expect(projectAfterDelete.stepsIDs).to.equal(stepsBeforeDelete);
  });

  it(@"should update step cursor", ^{
    auto request = [[WHSProjectUpdateRequest alloc] initWithProjectID:projectID];
    request.stepsContentToAdd = @[stepContent];
    request.stepCursor = @(1);

    auto result = [storage updateProjectWithRequest:request error:nil];

    expect(result).to.beTruthy();
    auto _Nullable projectAfterUpdate = [storage fetchSnapshotOfProjectWithID:projectID options:0
                                                                        error:nil];
    expect(projectAfterUpdate.stepCursor).to.equal(request.stepCursor);
  });

  it(@"should not update bundle ID", ^{
    auto request = [[WHSProjectUpdateRequest alloc] initWithProjectID:projectID];
    request.stepsContentToAdd = @[stepContent];
    request.stepCursor = @(1);
    auto newStorage = [[WHSProjectStorage alloc] initWithBundleID:newBundleID baseURL:baseURL];

    auto result = [newStorage updateProjectWithRequest:request error:nil];

    expect(result).to.beTruthy();
    auto _Nullable projectAfterUpdate = [newStorage fetchSnapshotOfProjectWithID:projectID options:0
                                                                           error:nil];
    expect(projectAfterUpdate.bundleID).to.equal(bundleID);
  });

  it(@"should not update step cursor when step cursor property of the update object is nil", ^{
    auto addRequest = [[WHSProjectUpdateRequest alloc] initWithProjectID:projectID];
    addRequest.stepsContentToAdd = @[stepContent];
    addRequest.stepCursor = @(1);
    [storage updateProjectWithRequest:addRequest error:nil];
    auto request = [[WHSProjectUpdateRequest alloc] initWithProjectID:projectID];
    request.stepCursor = nil;

    auto result = [storage updateProjectWithRequest:request error:nil];
    expect(result).to.beTruthy();
    auto _Nullable projectAfterUpdate = [storage fetchSnapshotOfProjectWithID:projectID options:0
                                                                        error:nil];
    expect(projectAfterUpdate.stepCursor).to.equal(addRequest.stepCursor);
  });

  it(@"should return NO and set invalid argument error when step cursor is out of bounds", ^{
    NSError *error;
    auto request = [[WHSProjectUpdateRequest alloc] initWithProjectID:projectID];
    request.stepCursor = @(1);

    auto result = [storage updateProjectWithRequest:request error:&error];

    expect(result).to.beFalsy();
    expect(error.lt_isLTDomain).to.beTruthy();
    expect(error.code).to.equal(LTErrorCodeInvalidArgument);
  });

  it(@"should update project user data", ^{
    auto request = [[WHSProjectUpdateRequest alloc] initWithProjectID:projectID];
    request.userData = @{@"myProjectData": @"isInteresting"};

    auto result = [storage updateProjectWithRequest:request error:nil];

    expect(result).to.beTruthy();
    auto _Nullable projectAfterUpdate = [storage
                                         fetchSnapshotOfProjectWithID:projectID
                                         options:WHSProjectFetchOptionsFetchUserData error:nil];
    expect(projectAfterUpdate.userData).to.equal(request.userData);
  });

  it(@"should not update project user data when user data property of the update object is nil", ^{
    auto request1 = [[WHSProjectUpdateRequest alloc] initWithProjectID:projectID];
    request1.userData = @{@"myProjectData": @"isInteresting"};
    [storage updateProjectWithRequest:request1 error:nil];
    auto request2 = [[WHSProjectUpdateRequest alloc] initWithProjectID:projectID];
    request2.userData = nil;

    auto result = [storage updateProjectWithRequest:request2 error:nil];

    expect(result).to.beTruthy();
    auto _Nullable projectAfterUpdate = [storage
                                         fetchSnapshotOfProjectWithID:projectID
                                         options:WHSProjectFetchOptionsFetchUserData error:nil];
    expect(projectAfterUpdate.userData).to.equal(request1.userData);
  });
});

context(@"duplicate project", ^{
  __block WHSProjectStorage *storage;
  __block WHSProjectSnapshot *originalProject;
  __block WHSProjectSnapshot * _Nullable duplicatedProject;
  __block NSUUID * _Nullable duplicatedProjectID;
  __block NSString *assetName;
  __block NSString *assetContent;
  __block WHSStepContent *stepContent;
  __block NSString *stepAssetName;
  __block NSString *stepAssetContent;

  beforeEach(^{
    storage = [[WHSProjectStorage alloc] initWithBundleID:bundleID baseURL:baseURL];
    auto projectID = nn([storage createProjectWithError:nil]);
    auto stepUserData = @{@"importantData": @"air", @"notSoImportantData": @(90210)};

    auto assetsURL = nn([storage fetchSnapshotOfProjectWithID:projectID options:0
                                                        error:nil]).assetsURL;
    assetName = @"projectAsset";
    auto assetPath = nn([assetsURL URLByAppendingPathComponent:assetName].path);
    [[NSFileManager defaultManager] createFileAtPath:assetPath contents:nil attributes:nil];
    assetContent = @"large amount of data for project";
    [assetContent writeToFile:assetPath atomically:YES encoding:NSUTF8StringEncoding error:nil];

    auto stepAssetsURL = [NSURL fileURLWithPath:LTTemporaryPath(@"stepAssets")];
    [[NSFileManager defaultManager] createDirectoryAtURL:stepAssetsURL
                             withIntermediateDirectories:YES attributes:nil error:nil];
    stepAssetName = @"stepAsset";
    auto stepAssetPath = nn([stepAssetsURL URLByAppendingPathComponent:stepAssetName].path);
    [[NSFileManager defaultManager] createFileAtPath:stepAssetPath contents:nil attributes:nil];
    stepAssetContent = @"large amount of data for step";
    [stepAssetContent writeToFile:stepAssetPath atomically:YES encoding:NSUTF8StringEncoding
                            error:nil];
    stepContent = [[WHSStepContent alloc] init];
    stepContent.userData = stepUserData;
    stepContent.assetsSourceURL = stepAssetsURL;
    auto request = [[WHSProjectUpdateRequest alloc] initWithProjectID:projectID];
    request.stepsContentToAdd = @[stepContent];

    [storage updateProjectWithRequest:request error:nil];
    duplicatedProjectID = [storage duplicateProjectWithID:projectID error:nil];
    originalProject = [storage fetchSnapshotOfProjectWithID:projectID
                                                    options:WHSProjectFetchOptionsFetchAll
                                                      error:nil];
    if (duplicatedProjectID) {
      duplicatedProject = [storage fetchSnapshotOfProjectWithID:nn(duplicatedProjectID)
                                                        options:WHSProjectFetchOptionsFetchAll
                                                          error:nil];
    }
  });

  afterEach(^{
    [storage deleteProjectWithID:originalProject.ID error:nil];
    if (duplicatedProject) {
      [storage deleteProjectWithID:nn(duplicatedProject).ID error:nil];
    }
  });

  it(@"should contain both old and new projects after duplication", ^{
    expect(duplicatedProjectID).notTo.beNil();
    auto _Nullable projectIDs = [storage projectsIDsSortedBy:$(WHSProjectCreationDate)
                                                  descending:YES error:nil];
    expect(projectIDs).to.contain(originalProject.ID);
    expect(projectIDs).to.contain(duplicatedProject.ID);
  });

  it(@"should duplicate bundleID", ^{
    expect(duplicatedProject.bundleID).to.equal(originalProject.bundleID);
  });

  it(@"should duplicate steps IDs", ^{
    expect(duplicatedProject.stepsIDs).to.equal(originalProject.stepsIDs);
  });

  it(@"should duplicate step cursor", ^{
    expect(duplicatedProject.stepCursor).to.equal(originalProject.stepCursor);
  });

  it(@"should duplicate user data", ^{
    expect(duplicatedProject.userData).to.equal(originalProject.userData);
  });

  it(@"should duplicate assets", ^{
    expect(duplicatedProject).notTo.beNil();
    expect(duplicatedProject.assetsURL).notTo.equal(originalProject.assetsURL);
    auto duplicatedAssetPath = nn([duplicatedProject.assetsURL
                                   URLByAppendingPathComponent:assetName].path);
    expect([[NSFileManager defaultManager] fileExistsAtPath:duplicatedAssetPath]).to.beTruthy();
    auto _Nullable duplicatedAssetContent = [NSString stringWithContentsOfFile:duplicatedAssetPath
                                                                      encoding:NSUTF8StringEncoding
                                                                         error:nil];
    expect(duplicatedAssetContent).to.equal(assetContent);
    auto originalAssetPath = nn([originalProject.assetsURL
                                URLByAppendingPathComponent:assetName].path);
    expect([[NSFileManager defaultManager] fileExistsAtPath:originalAssetPath]).to.beTruthy();
  });

  it(@"should duplicate step", ^{
    auto originalStep = nn([storage fetchStepWithID:nn(originalProject.stepsIDs)[0]
                                  fromProjectWithID:originalProject.ID error:nil]);
    auto _Nullable duplicatedStep = [storage fetchStepWithID:nn(duplicatedProject.stepsIDs)[0]
                                           fromProjectWithID:nn(duplicatedProject).ID error:nil];

    expect(duplicatedStep.ID).to.equal(originalStep.ID);
    expect(duplicatedStep.userData).to.equal(originalStep.userData);
    expect(duplicatedStep.projectID).notTo.equal(originalStep.projectID);
    expect(duplicatedStep.assetsURL).notTo.equal(originalStep.assetsURL);
    auto duplicatedAssetPath = nn([duplicatedStep.assetsURL
                                   URLByAppendingPathComponent:stepAssetName].path);
    expect([[NSFileManager defaultManager] fileExistsAtPath:duplicatedAssetPath]).to.beTruthy();
    auto _Nullable duplicatedAssetContent = [NSString stringWithContentsOfFile:duplicatedAssetPath
                                                                      encoding:NSUTF8StringEncoding
                                                                         error:nil];
    expect(duplicatedAssetContent).to.equal(stepAssetContent);
    auto originalAssetPath = nn([originalStep.assetsURL
                                 URLByAppendingPathComponent:stepAssetName].path);
    expect([[NSFileManager defaultManager] fileExistsAtPath:originalAssetPath]).to.beTruthy();
  });

  it(@"should return NO and set WHSErrorCodeWriteFailed if duplicating non existing project", ^{
    NSError *error;

    auto _Nullable duplicated = [storage duplicateProjectWithID:[NSUUID UUID] error:&error];

    expect(duplicated).to.beNil();
    expect(error.lt_isLTDomain).to.beTruthy();
    expect(error.code).to.equal(WHSErrorCodeWriteFailed);
  });
});

context(@"fetch step", ^{
  __block WHSProjectStorage *storage;
  __block NSUUID *projectID;
  __block NSUUID *stepID;
  __block WHSStepContent *stepContent;

  beforeEach(^{
    storage = [[WHSProjectStorage alloc] initWithBundleID:bundleID baseURL:baseURL];
    projectID = nn([storage createProjectWithError:nil]);
    stepContent = [[WHSStepContent alloc] init];
    stepContent.userData = @{@"my setp": @"is the best"};
    auto request = [[WHSProjectUpdateRequest alloc] initWithProjectID:projectID];
    request.stepsContentToAdd = @[stepContent];
    [storage updateProjectWithRequest:request error:nil];
    stepID = nn([storage fetchSnapshotOfProjectWithID:projectID
                                              options:WHSProjectFetchOptionsFetchStepsIDs
                                                error:nil].stepsIDs)[0];
  });

  afterEach(^{
    [storage deleteProjectWithID:projectID error:nil];
  });

  it(@"should fetch step", ^{
    NSError *error;

    auto _Nullable step = [storage fetchStepWithID:stepID fromProjectWithID:projectID error:&error];

    expect(step.userData).to.equal(stepContent.userData);
    expect(step.assetsURL).notTo.beNil();
    expect([[NSFileManager defaultManager] fileExistsAtPath:nn(step.assetsURL.path)]).to.beTruthy();
  });

  it(@"should return nil and set WHSErrorCodeFetchFailed if fetching step not in the project", ^{
    NSError *error;

    auto _Nullable step = [storage fetchStepWithID:[NSUUID UUID] fromProjectWithID:projectID
                                             error:&error];

    expect(step).to.beNil();
    expect(error.lt_isLTDomain).to.beTruthy();
    expect(error.code).to.equal(WHSErrorCodeFetchFailed);
  });

  it(@"should return nil and set WHSErrorCodeFetchFailed if fetching step from invalid project", ^{
    NSError *error;

    auto _Nullable step = [storage fetchStepWithID:[NSUUID UUID] fromProjectWithID:[NSUUID UUID]
                                             error:&error];

    expect(step).to.beNil();
    expect(error.lt_isLTDomain).to.beTruthy();
    expect(error.code).to.equal(WHSErrorCodeFetchFailed);
  });
});

context(@"set project attributes", ^{
  static const NSUInteger microsecondsInSecond = 1000000;
  __block WHSProjectStorage *storage;
  __block NSUUID *projectID;
  __block NSDate *originalCreationDate;
  __block NSDate *originalModificationDate;

  beforeEach(^{
    storage = [[WHSProjectStorage alloc] initWithBundleID:bundleID baseURL:baseURL];
    projectID = nn([storage createProjectWithError:nil]);
    auto project = nn([storage fetchSnapshotOfProjectWithID:projectID options:0 error:nil]);
    originalCreationDate = project.creationDate;
    originalModificationDate = project.modificationDate;
  });

  afterEach(^{
    [storage deleteProjectWithID:projectID error:nil];
  });

  it(@"should set creation date", ^{
    NSError *error;
    auto newCreationDate = [originalCreationDate dateByAddingTimeInterval:-5];
    auto result = [storage setCreationDate:newCreationDate toProjectWithID:projectID error:&error];

    expect(result).to.beTruthy();
    auto _Nullable project = [storage fetchSnapshotOfProjectWithID:projectID options:0 error:nil];
    expect(project).notTo.beNil();
    auto expectedInterval = newCreationDate.timeIntervalSince1970;
    auto actualTimeInterval = nn(project).creationDate.timeIntervalSince1970;
    expect(actualTimeInterval).to.beCloseToWithin(expectedInterval, 1.0 / microsecondsInSecond);
  });

  it(@"should return NO and set WHSErrorCodeWriteFailed when fails to set creation date", ^{
    NSError *error;
    auto newCreationDate = [originalCreationDate dateByAddingTimeInterval:-5];
    auto result = [storage setCreationDate:newCreationDate toProjectWithID:[NSUUID UUID]
                                     error:&error];

    expect(result).to.beFalsy();
    expect(error.lt_isLTDomain).to.beTruthy();
    expect(error.code).to.equal(WHSErrorCodeWriteFailed);
  });

  it(@"should set modification date", ^{
    NSError *error;
    auto newModificationDate = [originalModificationDate dateByAddingTimeInterval:-5];
    auto result = [storage setModificationDate:newModificationDate toProjectWithID:projectID
                                         error:&error];

    expect(result).to.beTruthy();
    auto _Nullable project = [storage fetchSnapshotOfProjectWithID:projectID options:0 error:nil];
    expect(project).notTo.beNil();
    auto expectedInterval = newModificationDate.timeIntervalSince1970;
    auto actualTimeInterval = nn(project).modificationDate.timeIntervalSince1970;
    expect(actualTimeInterval).to.beCloseToWithin(expectedInterval, 1.0 / microsecondsInSecond);
  });

  it(@"should return NO and set WHSErrorCodeWriteFailed when fails to set modification date", ^{
    NSError *error;
    auto newModificationDate = [originalModificationDate dateByAddingTimeInterval:-5];
    auto result = [storage setModificationDate:newModificationDate toProjectWithID:[NSUUID UUID]
                                         error:&error];

    expect(result).to.beFalsy();
    expect(error.lt_isLTDomain).to.beTruthy();
    expect(error.code).to.equal(WHSErrorCodeWriteFailed);
  });
});

context(@"observe storage", ^{
  __block WHSProjectStorage *storage;
  __block id observerMock;
  static auto const updatedUserData = @{@"newKey": @"newVal"};

  beforeEach(^{
    storage = [[WHSProjectStorage alloc] initWithBundleID:bundleID baseURL:baseURL];
    observerMock = OCMProtocolMock(@protocol(WHSProjectStorageObserver));
    [storage addObserver:observerMock];
  });

  it(@"should notify observer when project created", ^{
    auto projectID = nn([storage createProjectWithError:nil]);

    OCMVerify([observerMock storage:storage createdProjectWithID:projectID]);
  });

  it(@"should not notify observer after removal when project created", ^{
    [storage removeObserver:observerMock];
    OCMReject([observerMock storage:storage createdProjectWithID:[OCMArg any]]);

    [storage createProjectWithError:nil];
  });

  it(@"should notify multiple observers when project created", ^{
    id observerMock2 = OCMProtocolMock(@protocol(WHSProjectStorageObserver));
    [storage addObserver:observerMock2];

    auto projectID = nn([storage createProjectWithError:nil]);

    OCMVerify([observerMock storage:storage createdProjectWithID:projectID]);
    OCMVerify([observerMock2 storage:storage createdProjectWithID:projectID]);
   });

  it(@"should notify observer when project duplicated", ^{
    auto sourceID = nn([storage createProjectWithError:nil]);
    auto destinationID = nn([storage duplicateProjectWithID:sourceID error:nil]);

    OCMVerify([observerMock storage:storage duplicatedProjectWithID:sourceID
                      destinationID:destinationID]);
  });

  it(@"should not notify observer after removal when project duplicated", ^{
    [storage removeObserver:observerMock];
    OCMReject([observerMock storage:storage duplicatedProjectWithID:[OCMArg any]
                      destinationID:[OCMArg any]]);

    [storage duplicateProjectWithID:nn([storage createProjectWithError:nil]) error:nil];
  });

  it(@"should notify multiple observers when project duplicated", ^{
    id observerMock2 = OCMProtocolMock(@protocol(WHSProjectStorageObserver));
    [storage addObserver:observerMock2];
    auto sourceID = nn([storage createProjectWithError:nil]);
    auto destinationID = nn([storage duplicateProjectWithID:sourceID error:nil]);

    OCMVerify([observerMock storage:storage duplicatedProjectWithID:sourceID
                      destinationID:destinationID]);
    OCMVerify([observerMock2 storage:storage duplicatedProjectWithID:sourceID
                       destinationID:destinationID]);
  });

  context(@"observe project deletion", ^{
    __block NSUUID *projectID;

    beforeEach(^{
      projectID = nn([storage createProjectWithError:nil]);
    });

    afterEach(^{
      [storage deleteProjectWithID:projectID error:nil];
    });

    it(@"should notify observer when project deleted", ^{
      [storage deleteProjectWithID:projectID error:nil];

      OCMVerify([observerMock storage:storage deletedProjectWithID:projectID]);
    });

    it(@"should not notify observer after removal when project deleted", ^{
      [storage removeObserver:observerMock];
      OCMReject([observerMock storage:storage deletedProjectWithID:[OCMArg any]]);

      [storage deleteProjectWithID:projectID error:nil];
    });

    it(@"should notify multiple observers when project deleted", ^{
      id observerMock2 = OCMProtocolMock(@protocol(WHSProjectStorageObserver));
      [storage addObserver:observerMock2];

      [storage deleteProjectWithID:projectID error:nil];

      OCMVerify([observerMock storage:storage deletedProjectWithID:projectID]);
      OCMVerify([observerMock2 storage:storage deletedProjectWithID:projectID]);
    });
  });

  context(@"observe project update", ^{
    __block WHSProjectUpdateRequest *request;

    beforeEach(^{
      auto projectID = nn([storage createProjectWithError:nil]);
      request = [[WHSProjectUpdateRequest alloc] initWithProjectID:projectID];
      request.userData = updatedUserData;
    });

    it(@"should notify observer when project updated", ^{
      [storage updateProjectWithRequest:request error:nil];

      OCMVerify([observerMock storage:storage updatedProjectWithID:request.projectID]);
    });

    it(@"should not notify observer after removal when project updated", ^{
      [storage removeObserver:observerMock];
      OCMReject([observerMock storage:storage updatedProjectWithID:[OCMArg any]]);

      [storage updateProjectWithRequest:request error:nil];
    });

    it(@"should notify multiple observers when project updated", ^{
      id observerMock2 = OCMProtocolMock(@protocol(WHSProjectStorageObserver));
      [storage addObserver:observerMock2];

      [storage updateProjectWithRequest:request error:nil];

      OCMVerify([observerMock storage:storage updatedProjectWithID:request.projectID]);
      OCMVerify([observerMock2 storage:storage updatedProjectWithID:request.projectID]);
    });
  });
});

SpecEnd
