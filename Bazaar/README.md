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
Facetune 2 for example, some of the features and every subscription are
backed up by a product.

- Product identifier - an identifier associated with a certain product.
This is the identifier that appears in iTunes Connect. The product
identifier naming should follow the conventions specified in
[this document](https://docs.google.com/document/d/15rKWGAIIxJoRUUGkBjP-RhZpyYT3zMMcP4pyPu3tOjM/edit?ts=591cd338#heading=h.fophvxup2rqk).

- iTunes Connect - Apple's dashboard for managing applications,
distributing beta versions and more. In this context, it is used to add
in-app purchases to our applications. However, the product teams should
not add products to iTunes Connect themselves. The PX team are
responsible for that, and have a script that adds the products
automatically ensuring product IDs are following the conventions defined
in the doc above.

- StoreKit - Apple's library that Bazaar uses to make purchases.

- Receipt - A file produced by Apple that describes the purchases made by
the user. Each purchase entry includes the date of the purchase,
expiration date (for subscriptions), transaction id, and more.

- Active subscription - A subscription that the user owns and is not
expired / canceled.

- Validatricks - Lightricks' receipt validation server. This is the
server from which Bazaar asks for the latest receipt. The validation
is done using the App Store (More on validating using the App Store
[here](https://developer.apple.com/library/content/releasenotes/General/ValidateAppStoreReceipt/Chapters/ValidateRemotely.html#//apple_ref/doc/uid/TP40010573-CH104-SW1)).

## Linking with Bazaar

1. Drag `Bazaar.xcodeproj` from Finder into Xcode's project-navigator of
the project you want to link with Bazaar (typically it is put under
`Libraries` group).
2. Add all third party submodules Bazaar is using to your Xcode project:
`UICKeyChainStore`, `SSZipArchive`, `AFNetworking`, `Mantle`. They are
found in `Foundations/third_party`.
3. Drag all `Foundations` libraries Bazaar is using to your Xcode
project: `LTKit`, `Fiber`.
4. Go to `Build Phases` tab in you project settings -> `Link Binary with
Libraries` and add: `libBazaar`, `libLTKit`, `libFiber`,
`libUICKeyChainStore`, `AFNetworking.framework`, `Mantle.framework`,
`StoreKit.framework` and `ZipArchive.framework`.
5. Go to 'Build Phases' tab in your project settings ->
'Embed Frameworks' and add: `AFNetworking.framework`,
`Mantle.framework`, `ZipArchive.framework`.

## Bazaar interface

The integration with Bazaar mostly includes instantiating a single
class - `BZRStore`. Below is a detailed description of the interface of
this class.

### BZRProductsInfoProvider

A protocol that provides a readonly access to all sorts of information
regarding user purchases through KVO compliant properties. The most
interesting property is the one named `allowedProducts`, which
is a set product identifiers that the user is allowed to use. This means
that the application should allow access to every product that is
associated with a product identifier that appears in that set.

### BZRProductsManager

A protocol that provides an interface of purchase related actions:
purchasing of products, restoring purchases etc.

### BZRStore

The main class of Bazaar. Implements both
`BZRProductsInfoProvider` and `BZRProductsManager`. There should only be
one instance of `BZRStore` and it should be shared amongst all the
objects that need to have access to it.

**Note** `BZRStore` should be created as soon as possible during the
application runtime. This is because the products' prices are fetched
in every run of the application. The earlier the prices are fetched,
the shorter the user would have to wait when the application wants to
show prices.

### BZRStoreConfiguration

`BZRStore` is initialized with an instance of `BZRStoreConfiguration`.
The convenience initializer of `BZRStoreConfiguration` is created with
two parameters: the path to the product list JSON file and decryption key if the JSON file is
[encrypted](#json-files-compression-and-encryption) . The format of the product list file is
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
that case StoreKit will not be involved in the process.
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

## Making purchases

To make a purchase, call `BZRStore`'s `purchaseProduct` method, which
accepts a `productIdentifier`. It returns a `RACSignal` that completes
when the purchase completed successfully, and errs otherwise.

**Note** One might think that after purchasing a subscription product,
all the products that represent features are immediately enabled. This
is not the case. In order to make all of them available, one
should call `purchaseProduct` for every product, or just call
`acquireAllEnabledProducts`, which errs if the user doesn't have an
active subscription.

## Shared Keychain

By default, Bazaar writes the user subscription status and purchases information to a shared 
storage using Apple's [Keychain Storage](https://developer.apple.com/library/content/documentation/Security/Conceptual/keychainServConcepts/02concepts/concepts.html).
This enables the information to be shared among other apps that have the same app
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

---

## Troubleshooting

### Installing pip

If you don't have pip installed, make sure you install python from Homebrew via `brew install
python`. If `pip` command doesn't work after `brew install python`, try to run `brew unlink python
&& brew link --overwrite python`.

## Further reading

- [Validating receipt with the App Store](https://developer.apple.com/library/content/releasenotes/General/ValidateAppStoreReceipt/Chapters/ValidateRemotely.html#//apple_ref/doc/uid/TP40010573-CH104-SW1)
