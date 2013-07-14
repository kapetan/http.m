#import <Foundation/Foundation.h>

#import "../http/HttpServer.h"

static HttpServer *CreateHelloServer() {
    HttpServer *server = [[HttpServer alloc] init];
    HttpServerBlockDelegate *serverDelegate = server.delegate;
    
    serverDelegate.request = ^(HttpServer *server, HttpServerRequest *request, HttpServerResponse *response) {
        [response writeHeaderStatus:HttpStatusCodeOk headers:@{ @"content-type" : @"text/plain", @"content-length" : @"12" }];
        [response write:@"Hello World\n" encoding:NSASCIIStringEncoding];
        [response end];
    };
    
    return server;
}
