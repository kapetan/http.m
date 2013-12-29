//
//  HttpServer.m
//  http
//
//  Created by Mirza Kapetanovic on 7/10/13.
//  Copyright (c) 2013 Mirza Kapetanovic. All rights reserved.
//

#import "HttpServer.h"

#import "HttpError.h"

NSUInteger const HttpHeaderSizeLimit = 1024 * 1024;

void HttpServerReleaseDelegate(HttpServer *server) {
    if([server.delegate isKindOfClass:[HttpServerBlockDelegate class]]) {
        [server.delegate release];
    }
}

@implementation HttpServerBlockDelegate
-(void) server:(HttpServer *)server acceptedConnection:(TcpConnection *)connection {
    if(self.accept) self.accept(server, connection);
}

-(void) server:(HttpServer *)server request:(HttpServerRequest *)request response:(HttpServerResponse *)response {
    if(self.request) self.request(server, request, response);
}

-(void) serverDidClose:(HttpServer *)server {
    if(self.close) self.close(server);
}

-(void) server:(HttpServer *)server errorOccurred:(NSError *)error {
    if(self.error) self.error(server, error);
}

-(void) server:(HttpServer *)server client:(TcpConnection *)connection errorOccurred:(NSError *)error {
    if(self.clientError) self.clientError(server, connection, error);
}

-(void) dealloc {
    [self.accept release];
    [self.request release];
    [self.close release];
    [self.error release];
    [self.clientError release];
    
    [super dealloc];
}
@end

@implementation HttpServerAcceptDelegate {
    HttpServer *httpServer;
}

-(id) initWithServer:(HttpServer *)server {
    if(self = [super init]) {
        self->httpServer = server;
    }
    
    return self;
}

-(void) server:(TcpServer *)server acceptedConnection:(TcpConnection *)connection {
    [httpServer addConnection:connection];
    [httpServer.delegate server:httpServer acceptedConnection:connection];
}

-(void) server:(TcpServer *)server errorOccurred:(NSError *)error {
    [httpServer.delegate server:httpServer errorOccurred:error];
}

-(void) serverDidClose:(TcpServer *)server {
    [httpServer removeAllConnections];
    [httpServer.delegate serverDidClose:httpServer];
}
@end

// This is a bit ugly. TcpConnection, has a HttpServerConnectionDelegate, which owns a HttpServerRequest and HttpServerResponse,
// which again retain the same TcpConnection. HttpServer also retains the TcpConnection in the connections array.
@implementation HttpServerConnectionDelegate {
    NSMutableData *headerBuffer;
    NSInteger bodyLength;
    BOOL connectionClosed;
    
    HttpServer *server;
    
    HttpServerRequest *request;
    HttpServerResponse *response;
}

-(id) initWithServer:(HttpServer *)httpServer {
    if(self = [super init]) {
        self->server = httpServer;
        self->headerBuffer = [[NSMutableData alloc] init];
        self->bodyLength = 0;
        self->connectionClosed = NO;
    }
    
    return self;
}

-(void) connectionDidOpen:(TcpConnection *)connection {}

-(void) connectionDidDrain:(TcpConnection *)connection {
    [response.delegate responseDidDrain:response];
}

-(void) connectionDidClose:(TcpConnection *)connection {
    if(!connection.finished) {
        [response.delegate responseDidClose:response];
    }
    
    [server removeConnection:connection];
    connectionClosed = YES;
}

-(void) connectionDidEnd:(TcpConnection *)connection {
    if(!request || bodyLength) {
        // Did not read the entire request
        [connection destroy];
    }
}

-(void) connectionDidFinish:(TcpConnection *)connection {
    [response.delegate responseDidFinish:response];
    [connection destroy];
}

-(void) connection:(TcpConnection *)connection errorOccurred:(NSError *)error {
    [server.delegate server:server client:connection errorOccurred:error];
}

-(void) connection:(TcpConnection *)connection didReceiveData:(NSData *)data {
    if(request) {
        [self requestBody:connection data:data];
        return;
    }
    
    [headerBuffer appendData:data];
    
    if([headerBuffer length] > HttpHeaderSizeLimit) {
        // Header too long
        [connection destroy];
        return;
    }
    
    NSRange terminator = [headerBuffer rangeOfData:[NSData dataWithBytes:"\r\n\r\n" length:4]
                                           options:0
                                             range:NSMakeRange(0, [headerBuffer length])];
    
    if(terminator.location == NSNotFound) {
        return;
    }
    
    NSUInteger separator = terminator.location + terminator.length;
    NSData *headerData = [headerBuffer subdataWithRange:NSMakeRange(0, separator)];
    
    NSError *error;
    NSString *headerString = [[NSString alloc] initWithData:headerData encoding:NSASCIIStringEncoding];
    HttpRequestHeader *header = [[HttpRequestHeader alloc] initWithString:headerString error:&error];
    
    [headerString release];
    
    if(!header) {
        // Invalid header
        [connection destroy];
        return;
    }
    
    HttpServerRequest *serverRequest = request = [[HttpServerRequest alloc] initWithConnection:connection header:header];
    HttpServerResponse *serverResponse = response = [[HttpServerResponse alloc] initWithConnection:connection];
    
    [header release];
    bodyLength = serverRequest.header.contentLength;
    
    [server.delegate server:server request:serverRequest response:serverResponse];
    
    if(connectionClosed) return;
    
    if([headerBuffer length] > separator) {
        // We have received part of the body
        NSData *body = [headerBuffer subdataWithRange:NSMakeRange(separator, [headerBuffer length] - separator)];
        [self performSelector:@selector(requestBody:) withObject:@[connection, body] afterDelay:0];
    } else if(!bodyLength) {
        [serverRequest.delegate performSelector:@selector(requestDidEnd:) withObject:serverRequest afterDelay:0];
    }
    
    [headerBuffer release];
    headerBuffer = nil;
}

-(void) connectionDidSendData:(TcpConnection *)connection {}

-(void) requestBody:(NSArray *)arguments {
    [self requestBody:[arguments objectAtIndex:0] data:[arguments objectAtIndex:1]];
}

-(void) requestBody:(TcpConnection *)connection data:(NSData *)data {
    bodyLength -= [data length];
    
    if(bodyLength < 0) {
        [server.delegate server:server client:connection
                  errorOccurred:NSErrorWithReason(HttpErrorUnexpectedBody, @"Unexpected body length")];
        
        [connection destroy];
        return;
    }
    
    [request.delegate request:request didReceiveData:data];
    
    if(connectionClosed) return;
    
    if(!bodyLength) {
        [request.delegate requestDidEnd:request];
    }
}

-(void) dealloc {
    [headerBuffer release];
    [request release];
    [response release];
    
    [super dealloc];
}
@end

@implementation HttpServer {
    TcpServer *server;
}

@synthesize delegate;
@synthesize connections;

-(id) init {
    if(self = [super init]) {
        self->server = [[TcpServer alloc] init];
        self->delegate = [[HttpServerBlockDelegate alloc] init];
        self->connections = [[NSMutableArray alloc] init];
    }
    
    return self;
}

-(void) listenOnPort:(NSInteger)port {
    server.delegate = [[HttpServerAcceptDelegate alloc] initWithServer:self];
    [server listenOnPort:port];
}

-(void) close {
    [server close];
}

-(void) setDelegate:(id)newDelegate {
    HttpServerReleaseDelegate(self);
    delegate = newDelegate;
}

-(void) removeConnection:(TcpConnection *)connection {
    [connection.delegate release];
    connection.delegate = nil;
    
    [connections removeObject:connection];
}

-(void) addConnection:(TcpConnection *)connection {
    if(server.closed) {
        [connection destroy];
        return;
    }
    
    connection.delegate = [[HttpServerConnectionDelegate alloc] initWithServer:self];
    [connections addObject:connection];
}

-(void) removeAllConnections {
    NSArray *conns = [[NSArray alloc] initWithArray:connections];
    
    for(TcpConnection *connection in conns) {
        [connection destroy];
    }
    
    [conns release];
}

-(void) dealloc {
    HttpServerReleaseDelegate(self);
    server.delegate = nil;
    
    [server release];
    [connections release];
    
    [super dealloc];
}
@end
