# Trump

Never mind the library name!!
This is an example application to preload resources for use with iOS applications.

It is based on a module/file approach to loading, with multiple files under a module 

If you want, you can adapt this to meet your needs
## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Usage

Initialize this sdk with some intercepotrs 

```
NSArray <TRSourceProtocol> *interceptors = [NSArray <TRSourceProtocol> arrayWithObjects: [TRSafetyInterceptor new], [TRDDNavInterceptor new], [TRFalconInterceptor new], nil];
[TRSourceManager startWithInterceptors:interceptors];
```

to get source

```
TRSource *source = [TRSourceManager sourceWithModule:@"Falcon" file:@"somefont.ttf"];

NSString *fontPath = source.filePath;
```

// or the source contains a dir, like this as you see below

```
TRSource *source = [TRSourceManager sourceWithModule:@"Safety" file:@"images.zip" isDir:YES];

NSString *imgpath0 = [source subfilePathForName:@"image0@2x.png"];

NSString *imgpath1 = [source subfilePathForName:@"image1@2x.png"];
```

## Feature 
- error retry 
- breakpoints transfer
- online update
- md5 verification

## Adapt
this is a initial version, give me an issue is you want to adapt

## Author

HiIgor

## License

Trump is available under the MIT license. See the LICENSE file for more info.
