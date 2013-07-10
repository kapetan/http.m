//
//  HttpRequest.m
//  http
//
//  Created by Mirza Kapetanovic on 7/9/13.
//  Copyright (c) 2013 Mirza Kapetanovic. All rights reserved.
//

#import "HttpServerRequest.h"

void HttpServerRequestReleaseDelegate(HttpServerRequest *request) {
    if([request.delegate isKindOfClass:[HttpServerRequestBlockDelegate class]]) {
        [request.delegate release];
    }
}

@implementation HttpServerRequestBlockDelegate
-(void) request:(HttpServerRequest *)request didReceiveData:(NSData *)data {
    if(self.data) self.data(request, data);
}

-(void) request:(HttpServerRequest *)request errorOccuredd:(NSError *)error {
    if(self.error) self.error(request, error);
}

-(void) requestDidEnd:(HttpServerRequest *)request {
    if(self.end) self.end(request);
}

-(void) dealloc {
    [self.data release];
    [self.error release];
    [self.end release];
    
    [super dealloc];
}
@end

@implementation HttpServerRequest
@synthesize header;
@synthesize connection;
@synthesize delegate;

-(id) initWithConnection:(TcpConnection *)conn header:(HttpRequestHeader *)head {
    if(self = [super init]) {
        self->connection = [conn retain];
        self->header = [head retain];
        self->delegate = [[HttpServerRequestBlockDelegate alloc] init];
    }
    
    return self;
}

-(void) setDelegate:(id)newDelegate {
    HttpServerRequestReleaseDelegate(self);
    delegate = newDelegate;
}

-(NSString *) description {
    return [header description];
}

-(void) dealloc {
    [connection release];
    [header release];
    HttpServerRequestReleaseDelegate(self);
    
    [super dealloc];
}
@end
