# Laboratory - Experiments Framework
This document describes the general assumptions, design, features, inputs and outputs of our experiments framework.

## Table of Contents

1. [Vision](#vision)
2. [Experiments Theory](#experiments-theory)
3. [Laboratory (Lab)](#laboratory-lab)
4. [Analytics](#analytics)
5. [API](#api)

## Vision
The intent of the framework is to:

1. Allow developers to easily add experiments to apps.
2. Allow analysts to easily analyze result of the experiments from their analytics framework.
3. Allow developers to easily test their experiments.

## Experiments Theory
### Assignment
Key and value pair used to control a single application behavior. The key name should describe the affected behavior, and the value is the parameter associated with the behavior.
Developers, who must know the key name for the behavior, will request the value for that key and use the value to control the behavior.

Since different [sources](#sources) may support different types, and to make analyzing results of experiments easy, we try to restrict values to strings and numbers.

By convention, keys must use `lowerCamelCase`.

Example: Assignment has key `subscribeScreenFontColor` and value `red`.

### Variant
Set of assignments. Each set of assignments has a name. The name of the variant is meant to be used by analysts and should be short and meaningful. 

By convention, variant names must be `UpperCamelCase`, for example `SubscriptionScreenThemeDracula`.

### Experiment
A set of keys for assignments, one or more variants and a Name. One of the variants is called the baseline variant which, in addition to being a variant, defines how the app should behave when the experiment is [not active](#active-experiments-and-variants).

If we would like to test whether one behavior is better than the other, we need to define an experiment. In an experiment, **each variant must supply assignments for all keys defined by the experiment**.

By convention, experiment names must use `UpperCamelCase`.

#### Experiment Example
An experiment called `SubscriptionScreenTheme` has the keys `subscribeScreenFontColor` which defines the color of the font in the subscribe screen and `subscribeScreenFontSize` that defines the font size of the subscribe screen.
The options for `subscribeScreenFontSize` are `10` and `12`. The options for `subscribeScreenFontColor` are `blue` and `yellow`. We end up with 4 variants:

|                                  | `subscribeScreenFontSize` | `subscribeScreenFontColor` |
|----------------------------------|---------------------------|----------------------------|
| SubscriptionScreenThemeSmallBlue | `10`                      | `blue`                     |
| SubscriptionScreenThemeLargeBlue | `12`                      | `blue`                     |
| SubscriptionScreenThemeSmallRed  | `10`                      | `yellow`                   |
| SubscriptionScreenThemeLargeRed  | `12`                      | `yellow`                   |

This experiment can also be implemented using only one key called `theme` which has the 4 above mentioned options for its values.
**Note**: It is up to the app to convert the `blue` and `yellow` strings to specific color objects. Another option is to set the `subscribeScreenFontColor` to the hex value of the color.

### Active Experiments and Variants
Only one variant for each experiment can be assigned to a device at specific point in time, by using the [`SubscriptionScreenTheme` example](#experiment-example) again, only one of the variants can be assigned to a device. This selected variant is called the active variant.
Moreover, not all experiments must run on a device. An experiment can be designed to run on a device that specify a specific condition, like specific app version, OS version, or country. An experiment that is running on a device and therefore has an active variant is called an active experiment.
When an experiment is not active, it’s expected that the baseline variant will be used.

### Source
An entity that manages experiments, variants and assignments. The most basic information a source can provide is a set of active variants on a device, with their assignment and experiment name. The source can store its data locally or remotely.

## Laboratory (Lab)
Lab is a framework that enables developers to conduct experiments (A/B testing) using a simple and unified interface for all sources. The framework adds one restrictions on the building blocks defined in the previous chapter: Sources cannot expose two active experiments with assignments sharing the same key. This restriction applies for any two experiments, no matter from what source. If you want to run two experiments with the same key at the same time, you have to make sure they cannot run on the same device together. For example, the first experiment can run only on iPads and the second experiment can run on other devices. To help with this issue, see [Active Experiment Token](#active-experiments-token).

### Sources
The framework contains implementations for 2 sources:

1. `LABLocalSource` - Source containing hard-coded experiments, their variants and the assignments for the variants. This source has logic to decide if an experiment is active and which variant is active.
2. `LABTaplyticsSource` - Provides experiments data from Taplytics and is built around the Taplytics SDK. Once initialized, the source pulls the data from Taplytics servers and exposes only the active variants.

### Active Experiments Token
The framework provides a simple way to prevent two experiments from being  active together. The framework provides a class that generates a persistent token which is a number between 0 and 1, this number is called the active experiments token. The provided class persists the token, the app should initialize the class and provide it to the sources it creates. Any source that consumes this token also provides a way to specify an active experiments token range for an experiment.

The experiment is defined to be active if the active experiments token for that device is in the active experiments token range of that experiment. Since the token is persistent, when you define two experiments with two non-intersecting ranges, they can have the same key.
For example: We create Experiment A with range [0.1,0.3] Experiment B with range [0.5, 0.8] and Experiment C with range [0.7, 0.9]. Experiments A and B can contain the same key, but Experiment B and C cannot contain the same key since if the token has the value 0.75, both experiments will be active.

### Assignments Manager
Usually, application-side developers are not interested in the variants and experiment names, but only in the assignments provided by the active variants of all the sources. The Assignments manager is the main entry point to the Lab framework and exposes a dictionary containing all the assignments from all the sources. The manager takes care of analytics for the experiments [(more on that later)](#analytics). Once you initialize your sources, you also initialize the assignments manager with these sources, then you can access the active assignments to get the data from the sources you created the manager with.

### User experience stabilization
Some sources (like Taplytics) can be controlled remotely, that means that assignments can change when the source fetches the latest data. This can cause a problem since the user can see two different behaviors of the app, and analyzing such cases is impossible.

Sources can opt in and implement user experience stabilization. When a source is called to stabilize the user experience, it should not change its assignments in order to provide a stable user experience.

This creates another problem - once stabilization is called, the assignments can no longer be changed, and if there is a bug in a certain variant, all the users who received this buggy variant are stuck with the variant. Each source should handle this problem. The Taplytics source uses an override mechanism to override keys locked by the call the stabilize user experience described [later](#changing-experiments-1).

The most important things in calling this method is the timing, since stabilization is persistent, meaning once you stabilized the assignments, they are stable for that device for good. You need to test your experiments thoroughly before releasing your app, in order to avoid changing experiments once it’s in the wild. See the documentation for each source regarding changes to running experiments.

Regardless of changing running experiments, stabilization also prevents new experiments from being exposed on devices where stabilization was called. This is done in order to have a more "pure” dataset as users who have seen many experiments, may "pollute” the dataset since they have been affected by a number of experiments.

### User affected by experiment
The assignments manager lets you report when a user has been affected by an assignment, together with a reason. This is done in order to create analytics event and later in analyzing the results of experiments. When you report that a user has been affected, you provide the assignment that affected the user and the reason (or way) the user has been affected. The simplest way for an experiment to affect the user is to be displayed. So the most common reason is "displayed". **It's expected the *every* experiment will report this as this is the main source for analyzing results of experiments**.The use of other reasons other than "displayed" should be coordinated with the Marketing and Analytics team. See the [analytics chapter](#analytics) for more details. 

### Responsibilities
 * It’s the responsibility of the developer to define all the experiments, the variants for each experiments and the assignments for all the variants.
 * It’s the responsibility of the framework to get all the assignments, resolve them and provide API to get the assignments.
 * It’s also the responsibility of the framework to provide an easy way for applications to send analytics events.

At this point it’s not the responsibility of the framework to interact with an analytics framework (Intelligence FTW!!!1) to analyze the results of the experiments.

The assignment values are transparent to the framework and it’s not the responsibility to run code according to the assignment value.

## Analytics
Experiments are not worth much without reporting back the active assignments for the device and whether or not the user did an action. For example, we need to send the exact variant the user has, and an event that shows that user was affected by the experiment.

### Generated events
The assignment manager provides an interface for applications to report when an experiment has affected a user. The application provides the assignment that affected the user, and a string value stating the "reason” or how the user was affected.

When the app reports that an assignment has affected a user, the framework, in turn, generates an event containing all the relevant data (assignment, variant, experiment, source and reason) to send to the analytics framework. When analyzing how experiments affect users, an analyst should use data generated by these events.

The framework generates this event when a new assignment has been activated on a device, or when an assignment has been deactivated on a device.

### Integration with analytics framework
The framework provides a delegate that's called whenever an analytics data is generated. As mentioned before, it's up to the application to convert the data to an analytics event and forward it to the analytics framework. Note that not all events must be sent, for example once a user was affected by an experiment and an event with "displayed" reason was sent for that experiment, there's no need to send that event again for that experiment. Consult with the Analytics team before implementing this part.

### Table structure
All events should be in a single table, with all the parameters of the event - value, key, variant, experiment, source and reason. They table should also contain other fields common in analytics tables like id_for_vendor.

In order to analyze the results of an experiment, you can query all the users (well, id_for_vendor values) that have been affected with the "displayed” reason for example. You can cross reference with other tables to get more meaningful results.

For specific examples, using reDash:

* Look at the `editor_usage_assignment_state_changed` table (Photofox).
* View queries:
   * Photofox AB testing - full experiment list
   * Laboratory General AB Testing Results Template
   * Photofox Displayed Taplytics Assignments

## API

### LABAssignmetnsManager
This is the main entry point to the framework. It’s both a protocol and a class providing the default behavior for the protocol. Let’s start with the basics:
```objc
- (instancetype)initWithAssignmentSources:(NSArray<id<LABAssignmentsSource>> *)sources
                                 delegate:(id<LABAssignmentsManagerDelegate>)delegate;
```
The initializer is called with an array of sources, that you need to initialize beforehand. Then the manager will merge all the assignments from all the sources and expose them in the `activeAssignments` property. The `delegate` parameter is used to provide an easy way for the application to connect the analytics events emitted by the framework to any analytics framework.

```objc
@property (readonly, nonatomic) NSDictionary<NSString *, LABAssignment *> *activeAssignments;
```
Mapping between the **active** assignment keys and an object that contains the value of the assignments, the originating variant, experiments and source.

```objc
- (void)stabilizeUserExperienceAssignments;
```
This call hints to all sources to not change the assignments in order to provide a stable user experience. Right now, only the Taplytics source adheres to this hint and will prevent new data from Taplytics servers to be exposed.

```objc
- (void)reportAssignmentAffectedUser:(id<LABAssignment>)assignment reason:(NSString *)reason;
```
Generates data to send to the analytics framework through the analytics delegate provided in the initializer.

### Local source
Local source is a source that contain experiments defined in the code of the application.

#### LABLocalVariant
```objc
/// Initializes with the \c name of the variant, \c probabilityWeight to affect the probability
/// of this variant to be selected, and the \c assignments for this variant.
- (instancetype)initWithName:(NSString *)name probabilityWeight:(NSUInteger)probabilityWeight
                 assignments:(NSDictionary<NSString *, id> *)assignments;
```
This class follows the "classic" definition for a variant, with the addition of `probabilityWeight` which is explained in the next sections.

#### LABLocalExperiment
```objc
- (instancetype)initWithName:(NSString *)name keys:(NSArray<NSString *> *)keys
                    variants:(NSArray<LABLocalVariant *> *)variants
            activeTokenRange:(LABExperimentsTokenRange)activeTokenRange;
```
This class follows the classic definition for experiment, together with the `activeTokenRange` that was [previously explained](#active-experiments-token).

#### LABLocalSource
```objc
- (instancetype)initWithExperiments:(NSArray<LABLocalExperiment *> *)experiments
           experimentsTokenProvider:(id<LABExperimentsTokenProvider>)experimentsTokenProvider;
```
The source receives an array of defined experiments, and is required to expose only the active assignments, so the experiments needs to decide two things:
1. Whether an experiment is active - this is done by testing if the `activeTokenExperiment` provided by the `experimentsTokenProvider` is in the `activeTokenRange` of the experiment.
2. The active variant for each experiment - The active variant is randomly selected using weighted discrete uniform distribution using the `probabilityWeight` of every variant at the weights. For example, If we have 3 variants, A with probability weight of 1, B with probability weight of 2 and C with probability weight of 2, A has 20% to be the active variant, B and C have 40% each to be the active variant.

Once the active experiments and variants have been decided, the experiment activity status and active variant names are persistent.

### Taplytics source
#### LABTaplyticsSource
```objc
- (instancetype)initWithAPIKey:(NSString *)apiKey
      experimentsTokenProvider:(LABExperimentsTokenProvider *)experimentsTokenProvider
                    customData:(NSDictionary<NSString *, id> *)customData;
```
The source receives the Taplytics apiKey for the application, generated by Taplytics. The experiments token provider, which is used to pass the token as a user attribute to Taplytics, and any other custom data to be used as user attributes in Taplytics. You can use these user attributes to filter the devices that will receive the experiment. For example, you can provide the number of times the user clicked on a certain button, and set an experiment to be active only one devices where the user clicked at least 5 times on that button.

## Conducting experiments
Creating, maintaining and analyzing experiments is an art. The target of this framework is to help you master this art. This may look simple at first glance, and new experiments are relatively simple tasks, but changing experiments when they have already begun is a complex task with many moving parts. You must have intimate knowledge of how the sources works in order to successfully deploy an experiment and get meaningful results.

Every source behaves differently, therefore every source requires a different approach and should be used in different scenario. The following sections discuss the technical details of conducting experiments using the framework.

When designing experiments, you need to consider every experiment and key EVER created as users can have data from old experiments, due to assignment stabilization. Don’t reuse keys and experiment names.

### Local source
#### Creating experiments
Once you’ve decided on your variants and experiment, you need to create an instance of LABLocalVariant for each variant and an instance of LABLocalExperiment for each experiment. For example: 
```objc
auto baseline = [[LABLocalVariant alloc] initWithName:@"baseline" probabilityWeight:2
                                            assignments: @{
    kSubscriptionPromptImageNameKey: @"SubscribeOnLaunchImage.jpg"
}];

auto second = [[LABLocalVariant alloc] initWithName:@"SubscribeOnLaunchImage_b"
                                  probabilityWeight:1 assignments: @{
  kSubscriptionPromptImageNameKey: @"SubscribeOnLaunchImage_b.jpg"
}];

auto third = [[LABLocalVariant alloc] initWithName:@"SubscribeOnLaunchImage_c"
                                 probabilityWeight:1 assignments: @{
  kSubscriptionPromptImageNameKey: @"SubscribeOnLaunchImage_c.jpg"
}];

NSArray<NSString *> *keys = @[kSubscriptionPromptImageNameKey];
NSArray<LABLocalVariant *> *variants = @[baseline, second, third];
return [[LABLocalExperiment alloc] initWithName:@"subscriptionPromptImage" keys:keys
                                       variants:variants activeTokenRange:{0.2, 0.4}];
```
The above code creates a local experiment named `subscriptionPromptImage` with 3 variants and a single assignment. The baseline variant has 0.5 probability to be selected, while the other two have 0.25 probability each. 

If your experiment has only one key which happens to be an LTEnum, you can use a convenience method to create an experiment with a variant for each field in the enum:
```objc
auto experiment = [LABLocalExperiment experimentFromEnum:LABTestLocalSourceEnum.class
                                                withName:@"foo" activeTokenRange:{0.3, 0.7}];
```
The above code creates a local experiment named `foo` with a variant for each enum value, each variant has the same probability to be selected.

### Changing experiments
Due to the nature of the local source, any change in the variants/experiment will require a new version to be released. Changing an existing experiment is not advised. but if necessary it requires planning. When changing a running experiment please consider the following:

* Local source only keeps the experiment name and chosen variant name, so any change to the assignments themselves will change in any user that already has the variant that changed.
* Data about deleted experiments is removed from the device. For example
   * Version 1 has experiment E, and a device has selected variant A. 
   * Version 2 removes experiment E.
   * Version 3 brings back experiment E, but the device can now select any variant.
   
   This is another reason why you should not reuse experiments names
* Deleted variant will be treated as a new experiment and a new variant will be selected.
For example:
   * Version 1 has experiment E, with variants A and B. The device chose variant B.
   * Version 2 has experiment E, with variants A and C. The device will randomly select variant A or C.

* If the active token range changes, the change will not take effect in devices where the experiment was already active. With stabilization, this can a powerful tool.

#### Concluding experiments
Once a winner has been decided. You’ll need to implement the winning behavior, and remove any code related to the experiment - both experiment definition and any other remains.

### Taplytics source
Managing experiments in Taplytics is **hard and error-prone**. In addition overriding values will **immediately affect users**, so be extremely careful, as you may **crash the app on millions of devices**. If you accidentally created a variable with the wrong type, you can change that only by asking Taplytics support to change that, so make sure not to make any mistake.

#### Creating experiments
Use the web interface to create an experiment, variants and keys. Once you’re happy with the experiment, you need to add another key to the experiment so LAB will be able to use it.
Add a key called `__Keys_<experiment name>`, give the the type JSON and they it’s value to be a JSON array, with all the keys of the experiment as it’s values.

If the assignment manager or Taplytics source do not recognize the experiment, look at the log, as the experiment might have been misconfigured.

#### Changing experiments
This is the most complex part in this library. Make sure you know what you’re doing and you know the consequences. Testing this is not trivial and may result in crashing the app for millions of users.

For example, if you added a new key to your experiment and added the code in the app to handle it, You’ll have to test the case what happens if the key doesn’t exist, as devices that already have this experiment, will never have the new key.

If you need to override a value after stabilization has been called you can use the override mechanism: Add a new key to the experiment with the name `__Override_<experiment name>`, and give it the type JSON. Set its value to the name of the key you want to override. The override will occur on each variant separately, for example

Your experiment `E` has two variants - `A` and `B`, each has 2 keys - `KeyC` and `KeyD`. `A` sets `KeyC` to `foo` and `B` sets `KeyC` to `bar`. If you add the key `__Override_E` with value `["KeyC"]`, immediately every time you change variant `B`'s value for `KeyC`, every user with variant `B` will get that value. **Attention: Taplytics will not ask you before setting the value, it’s effect is immediate.**

This feature is very powerful and therefore extremely dangerous. Use it sparingly and only in emergencies, for example, when a variant is crashing the app. It’s suggested that in this case, a new version of the app will be released with a new experiment. Do not use this method to conclude experiments unless you absolutely know what you’re doing.

#### Concluding experiments
Once a winning variant was found, use the web interface to conclude the experiment. This will set the percentage of the winning variant to 100% and the others to 0%. This means that for devices that called stabilize will keep the old variant data, but new devices will always get the winning variant.
In the next version of the app, remove any remains of the experiment.

## Integrating with your app
### Basic integration
The first thing to do is create an object that creates the assignment manager and the sources, then you’ll have access to the active assignments.

`LABAssignmentManager` returns a dictionary mapping between keys (strings) to `LABAssigment` object, it’s recommended to create another object that converts this dictionary to concrete objects to be used everywhere in the app. But keep in mind that in order to report that a user has been affected by assignment, you need a `LABAssignment` object.

Remember that for inactive assignments, there will be no `LABAssignment` object for that assignment key. Any code that uses values from assignments, must handle all the possible values for that assignment, and `nil`. It is expected that in this case, the behavior will be like the baseline variant.

LAB also contains `LABAssignmentValue` object, which contains `LABAssignment` and the value of the assignment object with a concrete type.

You can create a class with all the known keys mapped to` LABAssignmentValue` objects. Any class can use the the value of the `LABAssignmentValue` to display an experiments and the assignment object to report it affected the user. You can also serialize and deserialize this object for later reporting it affected the user.

It’s also recommended to make the above classes globally available for ease of use, since any class can use experiments.

### Debug screen
***Saves the need for compiling the code for each variant selection!*** 

LAB framework comes with a built in option for switching between all available experiments and variants, from a running application, in order to check that the experiments are configured correctly and produce expected results. 

***WARNING***
- Integration of this feature should be done **only** for Debug builds, and should not be available for release builds.
- The debug screen allows activation of multiple experiments at once, and may cause abnormal activation of experiments, mainly, intersecting experiments that would otherwise never be active together on the same device.


#### Debug Screen Structure
Debug screen is implemented on top of the `Tweaks` library by Facebook. `Tweaks` provides a shake screen that becomes visible once the device is gently shaken.

##### Components
- `FBTweak`: A class that controls one property. Hold all available values for that property. 
- `FBTweakCollection`: A collection of tweaks.
- `FBTweakCategory`: Holds many tweak collections.
- `FBTweakStore`: Singleton that holds `FBTweakCategory` object. Accessed by the built in tweaks screen.
- `FBTweakShakeWindow`: The window to be used in DEBUG builds, that reveals the debug screen upon a shake.

##### Screen UI
The screen is a navigation view of tables:
- `Main`: A table of all available categories. Has a `reset` button on the top left corner that resets all `Tweaks` to their default value 
- `Category`: A table of all available Collections and their Tweaks. A collection is a table section, and the items are the tweaks.

#### Available Categories for LAB
- `Experiments`: contains all available experiments. Experiments from a single source are under a section with its name.
- `Settings`: contains setting for categories.

#### Updating Experiments Data 
Due to the non-reactive  nature of the underlying `Tweaks` library, there is a special category named `Settings` that has controls for updating and resetting each of the available categories in the main debug screen.

`Settings` provides a collection for each tweaks category with the following tweaks:
- `Update`: Causes an update to the related category’s data ones switched on.
- `Status`: Displayes the status of the related category.
- `Reset`: resets all tweaks in the related category.

The UI is non reactive, so in order to see that an update was completed, one needs to leave the `Settings` category and enter it again. If the `Update` switch is back to its initial place, then the update is done. `Status` will display an `Error` message in case the update was not successful.

#### LABDebugSource
A source that multiplexes other `LABAssignmentsSource`s and acts under two hats:
1. A regular source that exposes `activeVariants`.
2. A mutable source that exposes all possible experiments and allows selection of active variants for experiments.

#### Integration
Set the underlying `UIWindow` to be an `FBTweakShakeWindow` in `AppDelegate`:
```objc
...
#ifdef DEBUG
  self.window = [[FBTweakShakeWindow alloc] init];
#else
  self.window = [[UIWindow alloc] init];
#endif
  [self.window makeKeyAndVisible];
...
```

Initialize `LABAssignmentsManager` with the debug source:
```objc
auto sources = @[localSource, taplyticsSource];
#ifdef DEBUG
sources = [[LABDebugSource alloc] initWithSources:sources];
#endif
auto assignmentsManager = [[LABAssignmentsManager alloc] initWithAssignmentSources:sources
                                                                          delegate:self];

```

Initialize `LABDebugSourceTweakCollectionsProvider` with the debug source:
```objc
auto debugSourceCollectionsProvider = [[LABDebugSourceTweakCollectionsProvider alloc]
                                       initWithDebugSource:debugSource];
```

Initialize `LABTweakCategoriesProvider` with the `LABDebugSourceTweakCollectionsProvider` instance:
```objc
auto categoriesProvider = [[LABTweakCategoriesProvider alloc] initWithProviders:@{
  @"Experiments": debugSourceCollectionsProvider,
  ...
  ...
}];
```

Populate categories to `FBTweakStore` singleton:
```objc
auto tweakStore = [FBTweakStore sharedInstance];
for (FBTweakCategory *category in categoriesProvider.categories) {
  [tweakStore addTweakCategory:category];
}
```
