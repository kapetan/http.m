//
//  main.m
//  http
//
//  Created by Mirza Kapetanovic on 7/2/13.
//  Copyright (c) 2013 Mirza Kapetanovic. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "HttpServer.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        HttpServer *server = [[HttpServer alloc] init];
        HttpServerBlockDelegate *delegate = server.delegate;
        
        delegate.request = ^(HttpServer *server, HttpServerRequest *request, HttpServerResponse *response) {
            NSLog(@"Request received");
            
            HttpServerRequestBlockDelegate *delegate = request.delegate;
            
            delegate.data = ^(HttpServerRequest *request, NSData *data) {
                NSLog(@"Request data %lu", (unsigned long)[data length]);
            };
            delegate.end = ^(HttpServerRequest *request) {
                NSLog(@"Request end");
                
                //response.header.contentLength = 5;
                
                [response write:@"HELLO" encoding:NSASCIIStringEncoding];
                [response end];
            };
            delegate.error = ^(HttpServerRequest *request, NSError *error) {
                NSLog(@"Request error - %@", error);
            };
        };
        
        [server listenOnPort:8080];
        [[NSRunLoop currentRunLoop] run];
    }
    
    return 0;
}

