# http.m

An async HTTP server writen in Objective-C. Developed and tested in OS X 10.8. It has no dependencies other that the Foundation framework.

# Usage

Include `HttpServer.h` in your file. The server is async and needs to run in a runloop. The interface is somewhat inspired by the http server in `node.js`.

```objective-c
#import "HttpServer.h"

int main(int argc, const char * argv[]) {
	@autoreleasepool {
		HttpServer *server = [[HttpServer alloc] init];
		HttpServerBlockDelegate *serverDelegate = server.delegate;
		
		serverDelegate.request = ^(HttpServer *server, HttpServerRequest *request, HttpServerResponse *response) {		
			[response writeHeaderStatus:HttpStatusCodeOk headers:@{ @"content-type" : @"text/plain", @"content-length" : @"12" }];
			[response write:@"Hello World\n" encoding:NSASCIIStringEncoding];
			[response end];
		};
		
		[server listenOnPort:8080];

		[[NSRunLoop currentRunLoop] run];
	}
	
	return 0;
}
```

Visiting `localhost:8080` in a browser should result in a "Hello World" message.

When listening for incoming requests, either use the default block delegate, or implement the `HttpServerDelegate` interface and assign an instance using the `HttpServer.delegate` property. The block delegate defines a property for every event and expects a block to be assigned.

The request and response objects also expose multiple events which can be received using `HttpServerRequestDelegate` and `HttpServerResponseDelegate` (or the corresponding block delegates).

```objective-c
#import "HttpServer.h"

int main(int argc, const char * argv[]) {
	@autoreleasepool {
		HttpServer *server = [[HttpServer alloc] init];
		HttpServerBlockDelegate *serverDelegate = server.delegate;
		
		serverDelegate.request = ^(HttpServer *server, HttpServerRequest *request, HttpServerResponse *response) {
			HttpServerRequestBlockDelegate *requestDelegate = request.delegate;
			HttpServerResponseBlockDelegate *responseDelegate = response.delegate;

			NSMutableData body = [[NSMutableData alloc] init];
			
			requestDelegate.data = ^(HttpServerRequest *request, NSData *data) {
				[body appendData data];
			};
			requestDelegate.end = ^(HttpServerRequest *request) {
				NSLog(@"%@", [[NSString alloc] initWithData:body encoding:NSUTF8StringEncoding]);

				response.header.statusCode = HttpStatusCodeOk;
				[response setValue:@"text/plain" forField:@"content-type"];

				// Echo the body back to the client.
				[response write:body];
				[response end];

				[body release];
			};
			
			responseDelegate.end = ^(HttpServerResponse *response) {
				// All data flushed
			};
			responseDelegate.close = ^(HttpServerResponse *response) {
				// Connection closed before response.end could flush all the data
			};
		};
		
		[server listenOnPort:8080];

		[[NSRunLoop currentRunLoop] run];
	}
	
	return 0;
}
```

`response.write` never fails, instead the message is buffered in memory to be sent later. The method returns false when the buffer exceeds an internal limit. The drain event is fired when the buffer is empty again. Use this to throttle the response body, instead of taking up too much memory.

When no `content-length` value is set and the `response.write` method is called, chunked transfer encoding is used. Note that when calling one of the `response.writeHeaderStatus` methods the `transfer-encoding` should be set explicitly.

# Limitations

There are multiple limitations, which may be fixed in the future.

* Connections aren't pooled, and are closed after each response
* No special handling of HEAD and UPGRADE methods 
* No support for chunk encoded requests
