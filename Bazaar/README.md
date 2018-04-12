# Bazaar

Bazaar is a library for managing an in-app store using Apple's
purchasing system. Its main role is to provide an interface for making and
restoring purchases, managing subscriptions, controlling access to
products and providing relevant information to the application.

Bazaar is NOT responsible for stuff not related to Apple's in-app
purchases, in particular: downloading content that is not directly
related to in-app purchases, managing whether a feature is hidden or
not, purchasing products not via StoreKit.

## Glossary

- Product - a synonym for an in-app purchase. Can represent a
non-consumable payment purchase or a subscription purchase. In
`Facetune 2` for example, some of the features and every subscription are
backed up by a product.

- Product identifier - an identifier associated with a certain product.
This is the identifier that appears in iTunes Connect. The product
identifier naming should follow the conventions specified in
[this document](https://docs.google.com/document/d/15rKWGAIIxJoRUUGkBjP-RhZpyYT3zMMcP4pyPu3tOjM/edit?ts=591cd338#heading=h.fophvxup2rqk).

- iTunes Connect - Apple's dashboard for managing applications,
distributing beta versions and more. In this context, it is used to add
in-app purchases to our applications. However, the product teams should
not add products to iTunes Connect themselves. The PX team are
responsible for that and have a script that adds the products
automatically ensuring product IDs are following the conventions defined
in the doc above.

- StoreKit - Apple's library that Bazaar uses to make purchases.

- Receipt - A file produced by Apple that describes the purchases made by
the user. Each purchase entry includes the date of the purchase,
expiration date (for subscriptions), transaction id, and more.

- Active subscription - A subscription that the user owns and is not
expired/canceled.

- Validatricks - Lightricks' receipt validation server. This is the
server from which Bazaar asks for the latest receipt. The validation
is done using the App Store (More on validating using the App Store
[here](https://developer.apple.com/library/content/releasenotes/General/ValidateAppStoreReceipt/Chapters/ValidateRemotely.html#//apple_ref/doc/uid/TP40010573-CH104-SW1)).

## Linking with Bazaar

1. Drag `Bazaar.xcodeproj` from Finder into Xcode's project-navigator of
the project you want to link with Bazaar (typically it is put under
`Libraries` group).
2. Add all third-party submodules Bazaar is using to your Xcode project:
`UICKeyChainStore`, `SSZipArchive`, `AFNetworking`, `Mantle`. They are
found in `Foundations/third_party`.
3. Drag all `Foundations` libraries Bazaar is using to your Xcode
project: `LTKit`, `Fiber`.
4. Go to `Build Phases` tab in your project settings -> `Link Binary with
Libraries` and add: `libBazaar`, `libLTKit`, `libFiber`,
`libUICKeyChainStore`, `AFNetworking.framework`, `Mantle.framework`,
`StoreKit.framework` and `ZipArchive.framework`.
5. Go to 'Build Phases' tab in your project settings ->
'Embed Frameworks' and add: `AFNetworking.framework`,
`Mantle.framework`, `ZipArchive.framework`.

## Bazaar's interface

The integration with Bazaar mostly includes instantiating a single
class - `BZRStore` which implements two protocols: `BZRProductsInfoProvider`
and `BZRProductsManager`.

### BZRProductsInfoProvider

A protocol that provides a read-only access to all sorts of information
regarding user purchases through KVO compliant properties. The most
interesting property is the one named `allowedProducts`, which
is a set of product identifiers that the user is allowed to use. This means
that the application should allow access to every product that is
associated with a product identifier that appears in that set.

### BZRProductsManager

A protocol that provides an interface to purchase-related actions:
purchasing of products, restoring purchases etc.

### Initialization of BZRStore 

`BZRStore` is initialized with an instance of `BZRStoreConfiguration` by calling

```objc
- (instancetype)initWithConfiguration:(BZRStoreConfiguration *)configuration
```

There should be only a single instance of `BZRStore`, which should be 
shared amongst all the objects that need to have access to it.

**Note** The instance should be created as soon as possible during the
application runtime. This is because the products prices are fetched
in every run of the application. The sooner the prices are fetched,
the shorter the user would have to wait when the application wants to show prices.

### BZRStoreConfiguration

The convenience initializer of `BZRStoreConfiguration` is invoked with
two parameters: the path to the product list JSON file and decryption key if the JSON file is
[encrypted](#json-files-compression-and-encryption). The format of the product list file is
specified [below](#product-list-json-file).

The purpose of this class is twofold:
- Providing a convenient initializer that initializes with the
  configuration needed for most cases.
- Providing a way to change the configuration easily. This is done by
  exposing all the classes that `BZRStore` needs from
  `BZRStoreConfiguration` as read-write properties.

## Product list JSON file

The product list JSON contains a list of all the products that the
application wants Bazaar to manage.
Here is an example JSON that contains two products:

```
[
  {
    "identifier": "com.lightricks.Facetune2.Retouch.Structure",
    "productType": "nonConsumable",
    "isSubscribersOnly": true,
    "contentFetcherParameters": {
      "type": "BZRRemoteContentFetcher",
      "URL": "https:///foo/bar.zip"
    }
  },
  {
    "identifier": "com.lightricks.Facetune2.V2.FullPrice.1MonthTrial.FullAccess.Monthly",
    "productType": "renewableSubscription",
    "discountedProducts": [
      "com.lightricks.Facetune2.V2.25Off.1MonthTrial.FullAccess.Monthly",
      "com.lightricks.Facetune2.V2.50Off.1MonthTrial.FullAccess.Monthly",
      "com.lightricks.Facetune2.V2.75Off.1MonthTrial.FullAccess.Monthly"
    ]
  }
]
```

- `identifier` - The product's identifier as defined on ITC.
- `productType` - The product's type. Can be one of
`nonConsumable`/ `consumable`/ `renewableSubscription`/
`nonRenewingSubscription`.
- `isSubscribersOnly` - Flag indicating whether the product should be
available only to subscribers. `false` by default. Note that if this is
false purchasing this product will issue a payment request to StoreKit,
and if this is true then purchase requests will only succeed if the user
has an active subscription that allows access to this product and in
that case, StoreKit will not be involved in the process.
- `discountedProducts` - list of product identifiers that are
discounts of the product with `identifier`. The products should
typically have the same subscription duration.
- `contentFetcherParameters` - parameters needed in order to fetch
additional product content after it has been purchased/acquired. `type`
is a mandatory field which specifies the method by which fetching
should be done. In the example above, `URL` is the URL where the
content can be found. If `contentFetcherParameters` is not specified,
it is assumed that the product has no additional content.

> ❗️In order to protect the product list content from attackers, it's recommended to
encrypt the product json file. Bazaar supports product list decryption by passing to
`BZRStoreConfiguration` the decryption key. 
See this [section](#json-files-compression-and-encryption) for integrating JSON files encryption
into the application in build time.

## JSON files compression and encryption

Bazaar's product list provider supports compressed and encrypted file using LZFSE algorithm for
compression and AES-128 algorithm for encryption.
The suggested flow for achieving this with Foundations tools is as the following: 
- Add a User-Defined setting at the project Build Settings named `JSON_ENCRYPTION_KEY` with a valid
hex string of a length of 32 bytes.
- Make sure the [python modules](#installing-pip) `pycrypto` and `pylzfse` are installed. If needed,
run `pip install pycrypto` and `pip install git+https://github.com/dimkr/pylzfse`.
- Add a Build Rule to your project for files with names matching `*.secure.json` that runs custom
script:
```
python ../Foundations/BuildTools/EncryptFile.py $JSON_ENCRYPTION_KEY "$INPUT_FILE_PATH" 
    "$TARGET_BUILD_DIR/$CONTENTS_FOLDER_PATH/$INPUT_FILE_BASE.json"
```
and output the encrypted file to the contents folder path:
```
$(TARGET_BUILD_DIR)/$(CONTENTS_FOLDER_PATH)/${INPUT_FILE_BASE}.json
```
- To avoid duplication of this key in the project code, add a preprocessing macro that injects
the key.
At the project `Build Settings` -> `Preprocessor Macros` -> 
    Add `JSON_ENCRYPTION_KEY="\"$JSON_ENCRYPTION_KEY\""`
- Then you can easily get the key and finally pass it to the Bazaar configuration:
```objc
static NSString * const kProductListEncryptionKey = @JSON_ENCRYPTION_KEY;
BZRStoreConfiguration *storeConfiguration =
     [[BZRStoreConfiguration alloc] initWithProductsListJSONFilePath:productsPath
                                            productListDecryptionKey:kProductListEncryptionKey];
```

## Making Purchases

To make a purchase, call `BZRStore`'s `purchaseProduct` method, which
accepts a `productIdentifier`. It returns a `RACSignal` that completes
when the purchase completed successfully and errs otherwise.

**Note** One might think that after purchasing a subscription product,
all the products that represent features are immediately enabled. This
is not the case. In order to make all of them available, one
should call `purchaseProduct` for every product, or just call
`acquireAllEnabledProducts`, which errs if the user doesn't have an
active subscription.

## Shared Keychain

By default, Bazaar writes the user subscription status and purchases information to a shared 
storage using Apple's [Keychain Storage](https://developer.apple.com/library/content/documentation/Security/Conceptual/keychainServConcepts/02concepts/concepts.html).
This enables the information to be shared with other apps that have the same app
identifier prefix (also called [team ID](https://developer.apple.com/library/content/documentation/IDEs/Conceptual/AppDistributionGuide/MaintainingProfiles/MaintainingProfiles.html)).

**Note** If you do not want Bazaar to write to the shared keychain storage, initialize
`BZRStoreConfiguration` with `keychainAccessGroup` set to `nil`.

Follow these steps in order to allow Bazaar to write to the shared keychain storage in your app:
1. Go to the project-navigator and select the target -> Capabilities -> turn on `Keychain Sharing` 
and change the key to be `com.lightricks.shared`.
2. Go to the project target -> `Info` -> add the key `AppIdentifierPrefix` with a string value 
`${AppIdentifierPrefix}`.
> ❗️Failing to do this step will result in Bazaar throwing an exception unless `keychainAccessGroup`
is set to `nil`.

Once this is set up, other applications can read the subscription status of your application.
For example, in order to know whether the user is a Facetune 2 subscriber:

```objc
  auto sharedUserInfoReader = [[BZRSharedUserInfoReader alloc] init];
  BOOL isFacetune2Subscriber =
      [sharedUserInfoReader isSubscriberOfAppWithBundleIdentifier:@"com.lightricks.Facetune2"];
```

## iCloud User ID

### The Problem - Uniquely Identifying Users.

We would like to be able to identify users across devices. This will assist in many tasks that are very hard or
impossible to accomplish without the ability to identify users. For once we want to let users access their
subscription across devices without the need to restore purchases, with multi-app subscription this task
becomes very important and not just nice to have. Also, we want to be able to assist users when they run into
troubles with their subscription. Having an ID for the user allows us to better understand the history of purchases
made by this user on all the devices he uses. Additionally having a way to identify users may improve our analytics 
data and assist with increasing the effectiveness of our marketing spend.

Classically this problem of user identity is solved by using some login mechanism that lets the user pick some unique
user ID (eg. email or user name) and a password in a sign-up process. Then the user can sign-in on different devices
using the same credentials used at sign-up. Alternatively, in order to spare the need for managing user credentials and
implementing user authentication, it is common to turn to 3rd party single-sign-on services like those provided by
Google or Facebook. These 3rd party services implement the authentication process and user management for you and 
provide you with the basic user information that you need, a unique user ID along with some proof of authenticity.
Unfortunately, if we had chosen to use one of these mechanisms we would be forced to add a "login" step to the 
subscription funnel, which has the potential to deter many of our users and prevent them from completing this 
process and purchase subscription.

### The Solution - "Silent Login" Using iCloud User-Record ID.

It appears that iCloud provides an easy way to identify users across devices based on their iCloud account
information without any in-app login mechanism and without even requesting for special permissions. In order to
get this unique identifier, an application needs to declare it uses iCloud and it should define an iCloud container
on the [iCloud dashboard](https://icloud.developer.apple.com/dashboard). An iCloud container is, as its name suggest,
a container of various types of data. Different pieces of data are called records and each record has its own unique 
identifier. Records are added by the app developer in code or via the dashboard, however, there's a basic record
that exists for every container which is called the "user record". The ID of this user record is unique for every
user who accesses the container.

From Apple's `CKContainer` documentation:
> "Every user who accesses a container has a corresponding user record in that container. By default, user records
contain no identifying personal information about the user or their iCloud account. User records provide a way to
differentiate one user of the app from another through the use of a unique identifier. Every user gets their own unique
identifier in a container. Because there is a record that has the same identifier as the user identifier, you can use
the record to store information about the current user. Always do so carefully, though, and with the understanding that
any data you add to the user record can be seen by other users of the app. Never store sensitive personal information
in the user record. This user record is not to be confused with the user’s CKUserIdentity, which is a separate record
and by default does not contain any personally identifying information."

In order to get unique user identifiers, Lightricks have created an iCloud container designated for Bazaar usage. The
identifier of this container is "iCloud.com.lightricks.Bazaar" and is shared amongst all Lightricks applications. 
Bazaar uses the user-record ID of this container as the unique user identifier.

### How Should Apps Use The iCloud User ID?

Basically, applications don't have much use for this user ID, Bazaar is already using it for its own purposes.
However, it may be useful for apps to send iCloud account information to analytics in order to associate the iCloud
user ID with the IDFV of the current device. It is also useful to print the iCloud user ID to the log in order to
assist with troubleshooting when users send requests to the support team. 

In order to get the iCloud user ID and send it to analytics or print it, the app needs to create an instance of the 
`BZRiCloudUserIDProvider` class and observe its `userID` property for changes. Note that fetching the iCloud user ID is
an asynchronous operation and this is why one needs to observe the property and just query its value right after the
initialization.

> Note that the account information may change during the runtime if the user signs out of his iCloud account or
decides to restrict the access to certain apps.

Usage example:
```objc
self.iCloudUserIDProvider = [[BZRiCloudUserIDProvider alloc] init];
@weakify(self);
[RACObserve(self.iCloudUserIDProvider, userID) subscribeNext:^(NSString * _Nullable userID) {
  @strongify(self);
  LogInfo(@"iCloud User ID updated: %@", userID);
  auto event = [[FTKinesisUserIDChangedEvent alloc] initWithUserID:userID];
  [self.eventBus post:event];
}];
```

In order to get more details regarding the iCloud account status apps can use `BZRCloudKitAccountInfoProvider`
which provides a lower level interface to the iCloud account information.

### How Bazaar Uses The iCloud User ID?

Bazaar uses iCloud user ID to associate the application receipt with the user identifier. When Bazaar validates
the application receipt file with Validatricks (our receipt validation server) he provides the server with the user ID,
if available, and the server associates the receipt file with the user ID. This way Bazaar can later (from other
devices or even if the user is signed out of the AppStore) ask the server about user purchases by sending only
the iCloud user ID without sending the receipt file itself. This is used mainly to support multi-app subscription
where one application does not necessarily have access to the receipt file of another application in which the
user may have purchased a multi-app subscription.

## Multi-app Subscription

Multi-app subscription is a subscription that the user purchases in one
application that unlocks content in a different application, assuming
they are from the same developer. Bazaar can be configured to support
multi-app subscriptions from other applications. It needs to be aware of
two things: which applications can unlock content for the current
application, and which subscriptions should be considered multi-app
subscriptions. The two parameters are provided thus:

- `bundledApplicationIDs` - bundle identifiers of other applications
  that may contain a multi-app subscription that unlocks content for the current application. This will tell Bazaar 
  to read receipt data of these apps from the shared keychain and validate & update receipt data for these apps in 
  the keychain when needed.
- `multiAppSubscriptionMarker` - substring of a product identifier.
  Subscription whose product identifier contains this string is
  considered a multi-app subscription for the current application.

An example code to enable multi-app subscription with substring
`.multiApp.` for the applications with identifiers `com.lightricks.foo`
and `com.lightricks.bar`:

```objc
// ...Code that gets the other parameters for `BZRStoreConfiguration`.

NSString *multiAppSubscriptionMarker = @".multiApp.";
NSSet<NSString *> *bundledApplicationIDs = [NSSet setWithObjects:@"com.lightricks.foo", @"com.lightricks.bar", nil];
BZRStoreConfiguration *storeConfiguration =
     [[BZRStoreConfiguration alloc] initWithProductsListJSONFilePath:productsPath
                                            productListDecryptionKey:kProductListEncryptionKey
                                          multiAppSubscriptionMarker:multiAppSubscriptionMarker
                                               bundledApplicationIDs:bundledApplicationIDs];
```

**Note** The applications also have to read and write from the same
keychain storage, which Bazaar takes care of by default (as described
in [Shared Keychain](#shared-keychain)).

**Note** Due to the fact that Bazaar needs the receipt of another
application in order to perform validation, there are cases where the
current application cannot be aware of another application's multi-app
subscription. Currently, the only solution is to restore purchases in
the other application. These cases are thoroughly discussed [in this document](https://docs.google.com/document/d/1Tgdc869E48FKpCHefPqr1xbPgjSSEH6Q1bMDhh2CxOk/edit#heading=h.sv24ekae7r9n).

---

## Troubleshooting

### Installing pip

If you have python but don't have pip installed, run `sudo easy_install pip`.
If you don't have python installed, run `brew install python`, it will include `pip` as well.

## Further reading

- [Validating receipt with the App Store](https://developer.apple.com/library/content/releasenotes/General/ValidateAppStoreReceipt/Chapters/ValidateRemotely.html#//apple_ref/doc/uid/TP40010573-CH104-SW1)
