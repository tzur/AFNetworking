# Warehouse - Library for persistent storage of projects
This library supplies tools to store projects and manage the stored projects. The library supports operations such as project creation, update, fetch, deletion etc. The operations are done by the `WHSProjectStorage` object. The current implementation stores the projects in the file system, inside the application's sandbox, and the `WHSProjectStorage` object is initialized with a base URL for the storage to be located under.

## Table of Contents

1. [What Is A Project?](#project)
2. [The Project Snapshot Concept](#snapshot)
3. [User Data And Assets](#userdata)
4. [Project Operations](#operations)
5. [Usage Examples](#examples)

## What Is A Project? <a name="project"></a>
A project is a persistent representation of a user's work in an application. It contains all the data that is needed to recreate the user's work at the time it was saved. It contains a list of steps, each representing a discrete change that the user has done. While the user is working, the application adds steps to the project. The project also has a step cursor that indicates the current step. The user can navigate in the list of steps to return to a previous state of the project (aka `undo`) and go forward (aka `redo`) and the step cursor is updated accordingly. In addition to the project data, metadata such as creation date of the project is also available from the storage.

## The Project Snapshot Concept <a name="snapshot"></a>
A project is a mutable entity, its state changes with time as the user adds steps to it and navigates in it. The project snapshot is the state of the project in the storage at a certain point of time. The snapshot is represented by a `WHSProjectSnapshot` object that is a simple value object. This object is a correct representation of the project in the storage only until the next update of the project. If the application holds a snapshot, it is the application's responsibility to update the snapshot it holds after updating the project.

## User Data And Assets <a name="userdata"></a>
There are two kinds of application specific data in a project: user data and assets.

### User Data
The `userData` property of the project snapshot is appropriate for small amount of data because it cannot be partially updated. It is an `NSData` object the application can overwrite when updating the project. The user data changes atomically with the state of the project during update. 

### Assets
Assets are managed by the application in a directory provided by `Warehouse` and called `assetsURL`. As opposed to user data, assets can be large (images, video, or other binary data) and can be changed at any time by the application. These changes don't change any property of the snapshot, they only affect the content of the `assetsURL` directory.

### Steps User Data And Assets
Each step of the project has its own `userData` and `assetsURL` in addition to the general `userData` and `assetsURL` of the project that is common to all the steps. Large assets that are used by multiple steps should be saved at the project's `assetsURL` and referenced by each step that uses them instead of being saved in a specific step or duplicated to several steps.

### A Word About Atomicity
As mentioned before, changes to the assets directory are not performed atomically with project updates. This should be taken into consideration when using the assets directory. If changes to the assets directory should be done when updating a project, the actions should be done in an order that can't cause inconsistent project in the storage. For example, if a step that is using an asset from the project assets directory is being deleted, the application should first perform the project update that deletes the step and modifies the reference count of the asset in the user data atomically. Only after the update the asset can be deleted (if reference count is zero). This way, if the update fails, the asset is still in the storage and the project state is consistent. If the update succeeds but the deletion of the asset fails the only side effect is an unreferenced asset that can be cleaned up in a periodic cleanup action.    

## Project Operations <a name="operations"></a> 
The `WHSProjectStorage` class, that is responsible for all project operations, is not thread safe. In addition, each storage that is initialized with the same base URL is using the same file system location. It is the application's responsibility to synchronize the usage of all the `WHSProjectStorage` objects with the same base URL. However, it is possible to use several `WHSProjectStorage` objects with a different base URL concurrently as they don't share resources (assuming none of the base URLs is located under the other). In order to observe the storage changes the application can add an observer to `WHSProjectStorage`. The observer is notified by an appropriate method call when the application invokes a storage method that updates the storage. The project IDs that were involved in the update are sent as parameters to the observer method. The supported project operations are:
* Creating a project
* Deleting a project
* Duplicating a project
* Fetching a project snapshot (fetch a step, and fetch projects list are also supported)
* Updating a project

In addition, updating project's creation and modification date is supported to allow migration of already existing projects into `Warehouse`. Updating and fetching are a little more complex than the other operations and are explained in more details below.

### Fetching project snapshot
Some properties of the project snapshot have a size that is unbound and is usage dependent (list of steps, user data). Fetching of a project is a common operation, and In order to optimize it these properties are not fetched by default. In order to fetch these properties, application can give the relevant `WHSProjectFetchOptions` to the fetch method (for example: `WHSProjectFetchOptionsFetchUserData`).

### Updating a project
An update of a project can include one or more of the following:
* An update of the user data of the project 
* Addition of steps
* Deletion of steps
* Change of step cursor position

Generally, an update requset can contain any combination of these changes. However, the most common update operations are undo (move step cursor one step back), redo (move step cursor one step forward), and add step (delete all steps after the steps cursor, add a new step in the location of the step cursor, and move step cursor one step forward). An update request for one of these common operations can be easily created by the relevant convenience initializer of `WHSProjectUpdateRequest`. After a request is created, the application can examine it in order to decide if action is needed from it before invoking the actual update (updating reference counts, for example). If needed, it can break the request to a few smaller requests, and perform its actions between the different parts of the update.

An update request is processed by performing the following steps:
1. First new steps are created in the storage.
2. Then project metadata and user data are updated atomically. The project metadata is the information about the project's state in the storage. It contains the list of steps of the project.
3. Finally steps are being deleted from the storage.

This order guarantees that the project is in a consistent state after the update even in case of failure. A failure to create a new step or to update the project data is considered a failure. In this case the storage will try to delete the steps already added in this update, but even if this fails the only side effect is unreferenced steps in the storage. A failure to delete steps from the storage after they were removed from the steps list in the data update stage is not considered a failure and will have the same side effect.

## Usage Examples <a name="examples"></a>

### Add Step
```objc
NSError *error;
auto projectStorage = [[WHSProjectStorage alloc] init];

// Write the assets of the step to add to a temporary directory. This directory will be the
// assetsSourceURL of the step to add. In this example the only asset is a thumbnail of the step. 
auto tempURL = [NSURL fileURLWithPath:NSTemporaryDirectory()];
tempURL = [[NSFileManager defaultManager] URLForDirectory:NSItemReplacementDirectory
                                                 inDomain:NSUserDomainMask
                                        appropriateForURL:tempURL create:YES error:&error];
auto thumbnailURL = [[tempURL URLByAppendingPathComponent:@"thumbnail" isDirectory:NO]
                     URLByAppendingPathExtension:@"png"];
[UIImagePNGRepresentation(<UIImage of thumbnail>) writeToURL:thumbnailURL 
                                                     options:NSDataWritingAtomic error:&error];

// Create the user data of the step to add. In this example the user data of the step is a 
// property list dictionary containing a single entry with a textual description of the current
// step.
auto stepDescription = @"best step ever!!!1!";
auto stepUserDataDictionary = @{@"description": stepDescription};
auto stepUserData = [NSPropertyListSerialization 
                     dataWithPropertyList:stepUserDataDictionary
                     format:NSPropertyListXMLFormat_v1_0 options:0 error:&error];

// Fetch the current snapshot. StepIDs is needed in order to create the add step request.
// User data is needed in order to update it.
auto options = WHSProjectFetchOptionsFetchStepsIDs | WHSProjectFetchOptionsFetchUserData;
auto snapshot = [projectStorage fetchSnapshotOfProjectWithID:<projectID> options:options
                                                       error:&error];

// The project user data in this example is also a property list dictionary contains the
// description of the current step. Thus it also need to be updated when adding a new step.  
NSData *projectUserData = snapshot.userData;
NSMutableDictionary *projectUserDataDictionary = [NSPropertyListSerialization
                                                  propertyListWithData:projectUserData
                                                  options:NSPropertyListMutableContainersAndLeaves
                                                  format:nil error:&error];
projectUserDataDictionary[@"currentStepDescription"] = stepDescription;
projectUserData = [NSPropertyListSerialization dataWithPropertyList:projectUserDataDictionary
                                                             format:NSPropertyListXMLFormat_v1_0 
                                                             options:0 error:&error];

// create the update request and update
auto stepContent = [WHSStepContent stepContentWithUserData:stepUserData assetsSourceURL:tempURL];
auto request = [WHSProjectUpdateRequest requestForAddStep:snapshot stepContent:stepContent];
request.userData = projectUserData;
[projectStorage updateProjectWithRequest:request error:&error];
```

### Undo
```objc
NSError *error;
auto projectStorage = [[WHSProjectStorage alloc] init];

// Fetch the current snapshot. StepIDs is needed in order to create the undo request.
// User data is needed in order to update it.
auto options = WHSProjectFetchOptionsFetchStepsIDs | WHSProjectFetchOptionsFetchUserData;
auto snapshot = [projectStorage fetchSnapshotOfProjectWithID:<projectID> options:options
                                                       error:&error];

if (!snapshot.canUndo) {
  return;
}

auto request = [WHSProjectUpdateRequest requestForUndo:snapshot];

// Fetch the step that will be current after the update in order to get the wanted project data.
// In This example, the project's user data contains a text that describes the current step.
NSString *currentStepDescription;
NSInteger stepIndexAfterUpdate = request.stepCursor.unsignedIntegerValue - 1;
if (stepIndexAfterUpdate >= 0) {
  auto step = [projectStorage fetchStepWithID:snapshot.stepsIDs[stepIndexAfterUpdate]
                            fromProjectWithID:snapshot.ID error:&error];
  // In this example, the step user data is a property list dictionary.
  NSMutableDictionary *stepUserDataDictionary = [NSPropertyListSerialization
                                                 propertyListWithData:step.userData
                                                 options:NSPropertyListMutableContainersAndLeaves
                                                 format:nil error:&error];
  currentStepDescription = stepUserDataDictionary[@"description"];
} else {
  currentStepDescription = @"Project is empty";
}

// In this example, the project user data is also a property list dictionary.
NSData *userData = snapshot.userData;
NSMutableDictionary *userDataDictionary = [NSPropertyListSerialization
                                           propertyListWithData:userData
                                           options:NSPropertyListMutableContainersAndLeaves
                                            format:nil error:&error];
userDataDictionary[@"currentStepDescription"] = currentStepDescription;
userData = [NSPropertyListSerialization dataWithPropertyList:userDataDictionary
                                                      format:NSPropertyListXMLFormat_v1_0 options:0
                                                       error:&error];
request.userData = userData;

// perform the undo
[projectStorage updateProjectWithRequest:request error:&error];
```
