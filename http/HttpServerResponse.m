//
//  HttpServerResponse.m
//  http
//
//  Created by Mirza Kapetanovic on 7/10/13.
//  Copyright (c) 2013 Mirza Kapetanovic. All rights reserved.
//

#import "HttpServerResponse.h"

void HttpServerResponseReleaseDelegate(HttpServerResponse *response) {
    if([response.delegate isKindOfClass:[HttpServerResponseBlockDelegate class]]) {
        [response.delegate release];
    }
}

@implementation HttpServerResponseBlockDelegate
-(void) responseDidDrain:(HttpServerResponse *)response {
    if(self.drain) self.drain(response);
}

-(void) responseDidEnd:(HttpServerResponse *)response {
    if(self.end) self.end(response);
}

-(void) responseDidClose:(HttpServerResponse *)response {
    if(self.close) self.close(response);
}

-(void) dealloc {
    [self.drain release];
    [self.end release];
    [self.close release];
    
    [super dealloc];
}
@end

@implementation HttpServerResponse {
    BOOL headerSent;
    BOOL chunked;
}

@synthesize header;
@synthesize connection;
@synthesize delegate;

-(id) initWithConnection:(id)conn {
    if(self = [super init]) {
        self->connection = [conn retain];
        self->delegate = [[HttpServerResponseBlockDelegate alloc] init];
        self->header = [[HttpResponseHeader alloc] init];
        
        self->headerSent = NO;
        self->chunked = NO;
    }
    
    return self;
}

-(void) setDelegate:(id)newDelegate {
    HttpServerResponseReleaseDelegate(self);
    delegate = newDelegate;
}

-(BOOL) write:(uint8_t *)data length:(NSUInteger)length {
    if(!headerSent) {
        if(!header.contentLength) {
            [header setValue:@"chunked" forField:@"transfer-encoding"];
        }
        
        [self writeHeaderStatus:header.statusCode];
    }
    
    [self writeChunkHeader:length];
    BOOL result = [connection write:data length:length];
    [self writeChunkTrailer];
    
    return result;
}

-(BOOL) write:(NSData *)data {
    return [self write:(uint8_t *)[data bytes] length:[data length]];
}

-(BOOL) write:(NSString *)data encoding:(NSStringEncoding)encoding {
    return [self write:[data dataUsingEncoding:encoding]];
}

-(void) writeHeaderStatus:(HttpStatusCode)status reasonPhrase:(NSString *)reason headers:(NSDictionary *)headers {
    if(headerSent) {
        return;
    }
    
    header.statusCode = status;
    if(reason) header.reasonPhrase = reason;
    
    if(headers) {
        for(NSString *key in headers) {
            [header setValue:[headers objectForKey:key] forField:key];
        }
    }
    if(!header.date) {
        NSDate *date = [[NSDate alloc] init];
        header.date = date;
        [date release];
    }
    
    [header setValue:@"close" forField:@"connection"];
    
    [connection write:[header toString] encoding:NSASCIIStringEncoding];
    
    headerSent = YES;
    chunked = [[header fieldValue:@"transfer-encoding"] isEqualToString:@"chunked"];
}

-(void) writeHeaderStatus:(HttpStatusCode)status headers:(NSDictionary *)headers {
    [self writeHeaderStatus:status reasonPhrase:nil headers:headers];
}

-(void) writeHeaderStatus:(HttpStatusCode)status {
    [self writeHeaderStatus:status headers:nil];
}

-(void) end {
    [self writeHeaderStatus:header.statusCode];
    [self writeChunkHeader:0];
    [self writeChunkTrailer];
    
    [connection end];
}

-(void) writeChunkHeader:(NSUInteger)length {
    if(!chunked) {
        return;
    }
    
    [connection write:[NSString stringWithFormat:@"%lx\r\n", (unsigned long)length] encoding:NSASCIIStringEncoding];
}

-(void) writeChunkTrailer {
    if(!chunked) {
        return;
    }
    
    [connection write:@"\r\n" encoding:NSASCIIStringEncoding];
}

-(NSString *) description {
    return [header description];
}

-(void) dealloc {
    [connection release];
    [header release];
    HttpServerResponseReleaseDelegate(self);
    
    [super dealloc];
}
@end
