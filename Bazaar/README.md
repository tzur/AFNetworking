# Bazaar

Bazaar is a library for managing an in-app store using Apple's
purchasing system. Its main role is to provide interface for making and
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
expired/cancelled.

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

A protocol that provides interface of purchase related actions:
purchasing of products, restoring purchases etc.

### BZRStore

The main class of Bazaar. Implements both
`BZRProductsInfoProvider` and `BZRProductsManager`. There should only be
one instance of `BZRStore` and it should be shared amongst all the
objects that need to have access to it.

**Note** `BZRStore` should be created as soon as possible during the
application runtime. This is because the products' prices are fetched
in every run of the application. The earlier the prices are fetched,
the shorter the user would have to wait when the application want to
show prices.

### BZRStoreConfiguration

`BZRStore` is initialized with an instance of `BZRStoreConfiguration`.
The convenience initializer of `BZRStoreConfiguration` is created with
only one parameter: the path to the product list JSON file. The format
of the product list file is specified [below](##product-list-json-file).

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

## Further reading

- [Validating receipt with the App Store](https://developer.apple.com/library/content/releasenotes/General/ValidateAppStoreReceipt/Chapters/ValidateRemotely.html#//apple_ref/doc/uid/TP40010573-CH104-SW1)
