#import <Foundation/Foundation.h>

#import "../http/HttpServer.h"

static HttpServer *CreateEchoServer() {
    HttpServer *server = [[HttpServer alloc] init];
    HttpServerBlockDelegate *serverDelegate = server.delegate;
    
    serverDelegate.request = ^(HttpServer *server, HttpServerRequest *request, HttpServerResponse *response) {
        HttpServerRequestBlockDelegate *requestDelegate = request.delegate;
        HttpServerResponseBlockDelegate *responseDelegate = response.delegate;
        
        NSMutableData *body = [[NSMutableData alloc] init];
        
        requestDelegate.data = ^(HttpServerRequest *request, NSData *data) {
            [body appendData:data];
        };
        requestDelegate.end = ^(HttpServerRequest *request) {
            response.header.statusCode = HttpStatusCodeOk;
            [response.header setValue:@"text/plain" forField:@"content-type"];
            
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
    
    return server;
}
