# Fiber

Fiber is a framework providing simple reactive API for common networking tasks in iOS.

## Reactive Interface For HTTP Clients

### HTTP Request

`FBRHTTPClient` provides a reactive interface for HTTP data sessions such as RESTful APIs and
 file downloading. The data being sent/received by the underlying session is buffered in memory, 
 hence it's not recommeneded to use `FBRHTTPClient` for downloading large files.

```objc
// A client with a default configuration and without relative URL.
auto client = [FBRHTTPClient client];

// An example for a file `GET` request and writing to the disk on complete, without any headers or
// parameters:
[[client 
    GET:fooFileURL withParameters:nil headers:nil]
    subscribeNext:^(LTProgress<FBRHTTPResponse *> *progress) {
      if (!progress.result) {
        // Do something with the progress.
        return;
      }

      NSError *error;
      [progress.result.content writeToFile:filePath options:0 error:&error];
    } error:^(NSError *error) {
      // Handle errors.
    }];
```

`FBRHTTPClient` can be provided with a custom configuration that can be used to control various 
connection parameters, and a base URL so the HTTP request methods will be relative to it 
(e.g if the base URL is set to `http://api.foo.com` and the POST method is invoked with `/bar` as 
the URL string parameter, then the POST request will be sent to http://api.foo.com/bar).

```objc
// An example for a client with a custom configuration and relative URL.
auto client = [FBRHTTPClient clientWithSessionConfiguration:configuration baseURL:baseURL];
```

> Supports only `HTTP` / `HTTPS` protocols.

> Supports only forground sessions. The request freezes when the app goes to background.

### HTTP Session Configuration

`FBRHTTPSessionConfiguration` object defines the behavior and policies for an HTTP session used by 
an `FBRHTTPClient`. Use this object to configure timeouts, headers, caching policies, 
connection requirements, query encoding, security policy and more. 
See [NSURLSessionConfiguration](https://developer.apple.com/documentation/foundation/nsurlsessionconiguration)
for more information.

An example for session configuration that uses no persistent storage for caches, cookies, or
credentials, and uses a default request marshalling and security policy:
```objc
auto sessionConfiguration = [FBRHTTPSessionConfiguration 
    initWithSessionConfiguration:[NSURLSessionConfiguration ephemeralSessionConfiguration]
    requestMarshalling:[FBRHTTPSessionRequestMarshalling init]
    securityPolicy:[FBRHTTPSessionSecurityPolicy standardSecurityPolicy]];
```

### See Also

* `FBRHTTPResponse` contains data and [metadata](https://developer.apple.com/documentation/foundation/nshttpurlresponse?language=objc)
 as received in response to a HTTP request.

* `LTProgress` Represents an instantaneous progress information about some task that eventually 
yields some result.
