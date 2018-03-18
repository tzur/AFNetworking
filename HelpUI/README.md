# HelpUI - Library for help screens
This library contains views and models to be used for presenting help screens in Lightricks ecosystem products on iOS.

## Table of Contents

1. [The View](#view)
2. [The Model](#model)
3. [Customization](#customization)
4. [Usage](#usage)

## The View <a name="view"></a>
The main view of this library is `HUIView`. This view contains a collection view of help cards. It contains almost no logic, and uses objects of other classes of this library that contains the logic. The layout of this view (and of the collection view it contains) was defined at the design document `HelpUI_Design.jpg` on Google Drive. If however, layout changes are required for your application it should be easy to replace this view with a different one (because it contains no logic), and set the layout as needed.

## The Model <a name="model"></a>
The `HUIDocument` object is the top level help document model that contains sections (`HUISection` objects), that by themselves contain items (`HUIItem` objects). The model is parsed from `JSON`. For example:
```javascript
{
  "title": "Help",
  "sections": [
    {
      "key": "Edit & Trim",
      "items": [
        {
          "type": "video",
          "title": "Edit & Trim",
          "body": "Tap on any clip or layer to edit. Drag edges to trim.",
          "video": "HelpClipEditClip.mp4",
          "associated_feature_item_titles": [
          ]
        }
      ]
    },
    {
      "key": "Arrange",
      "items": [
        {
          "type": "slideshow",
          "transition": "fade",
          "transitionDuration": 0,
          "title": "Arrange",
          "body": "Move a layer in front of or behind other layers.",
          "icon_url": "paintcode://EVDHelpIcons/Arrange",
          "images": [
            "1.jpg",
            "2.jpg"
          ],
          "associated_feature_item_titles": [
            "Arrange"
          ]
        }
      ]
    },
    {
      "key": "Mask",
      "items": [
        {
          "type": "image",
          "title": "Mask",
          "body": "Move the widget to hide and reveal parts of the layer.",
          "icon_url": "paintcode://EVDHelpIcons/Mask",
          "image": "1.jpg",
          "associatedFeatureItemTitles": [
            "Mask"
          ]
        }
      ]
    }
  ]
}
```

## Customization <a name="customization"></a>
Some of the `HelpUI` properties (like colors, fonts, localization, and content aspect ratio) are application specific and are not dictated by the ecosystem design. To change the default values of these properties use `HUISettings`. Notice that there is no default localization, so if localization is required the `localizationBlock` property of `HUISettings` has to be set. In addition, if help cards with static image are used, an `LTImageLoader` should be supplied to `HUISettings`.

## Usage <a name="usage"></a>
In order to use this library in your application:

1. In your view controller create the view `HUIView` using the initializer `initWithFrame`: 
```objc
HUIView *helpView = [[HUIView alloc] initWithFrame:CGRectZero];
```
2. Use `HUIDocumentProvider`'s `helpDocumentFromPath` method to fetch the `JSON` file and create `HUIDocument`.
```objc
HUIDocumentProvider *provider = [[HUIDocumentProvider alloc] init];
HUIDocument *helpDocument = [provider helpDocumentFromPath:featureHierarchyPath];
```
3. Create `HUIDocumentDataSource` by its initializer `initWithHelpDocument`.
```objc
HUIDocumentDataSource *helpDataSource = [[HUIDocumentDataSource alloc] initWithHelpDocument:helpDocument];
```
4. Set the data source to the `HUIView`'s `dataSource` property.
```objc
helpView.dataSource = helpDataSource;
```
If scrolling to section is needed :

1. Get the wanted section from `HUIDocument`.
```objc
NSString *sectionKey = [helpDocument sectionKeyForPath:featureHierarchyPath];
HUISection *section = [helpDocument sectionForKey:sectionKey];
```
2. Scroll to this section by the `HUIView`'s method `showSection:atScrollPosition:animated:`.
```objc
NSUInteger index = [helpDocument.sections indexOfObject:section];
[helpView showSection:index atScrollPosition:UICollectionViewScrollPositionTop animated:YES];
```
**Note:** when scrolling right after the creation of the `HUIView`, `-[HUIView invalidateLayout]` must be called before calling the scrolling method.
