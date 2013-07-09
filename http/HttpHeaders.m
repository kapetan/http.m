//
//  HttpHeader.m
//  http
//
//  Created by Mirza Kapetanovic on 7/2/13.
//  Copyright (c) 2013 Mirza Kapetanovic. All rights reserved.
//

#import "HttpHeaders.h"
#import "HttpError.h"

NSString* NSStringTrimmedByWhiteSpace(NSString *str) {
    return [str stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

@implementation HttpHeaders {
    NSMutableDictionary *headers;
    
    @protected
    NSMutableArray *line;
}

-(id) init {
    if(self = [super init]) {
        headers = [[NSMutableDictionary alloc] init];
        line = [[NSMutableArray alloc] initWithCapacity:3];
    }
    
    return self;
}

-(id) initWithString:(NSString *)str error:(NSError **)error {
    if(self = [super init]) {
        @autoreleasepool {
            NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
            
            NSArray *fields = [str componentsSeparatedByString:@"\r\n"];
            NSArray *firstLine = [[fields objectAtIndex:0]
                             componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            
            NSInteger i = 1;
            NSString *field;
            while(i < [fields count] && [(field = [fields objectAtIndex:i]) length] > 0) {
                NSArray *f = [field componentsSeparatedByString:@":"];
                
                if([f count] != 2) {
                    if(error != NULL) {
                        *error = NSErrorWithReason(HttpErrorUnparsableHeader, @"Invalid header field");
                    }
                    
                    return nil;
                }
                
                NSString *fieldName = [NSStringTrimmedByWhiteSpace([f objectAtIndex:0]) lowercaseString];
                NSString *fieldValue = NSStringTrimmedByWhiteSpace([f objectAtIndex:1]);
                
                if([result objectForKey:fieldName]) {
                    fieldValue = [NSString stringWithFormat:@"%@,%@", [result objectForKey:fieldName], fieldValue];
                }
                
                [result setObject:fieldValue forKey:fieldName];
                
                i++;
            }
            
            if([[fields objectAtIndex:i] length] != 0 || [fields count] - 1 == i) {
                if(error != NULL) {
                    *error = NSErrorWithReason(HttpErrorUnparsableHeader, @"Invalid end of headers");
                }
                
                return nil;
            }
            
            self->line = [[NSMutableArray alloc] initWithArray:firstLine];
            self->headers = result;
        }
    }
    
    return self;
}

-(NSString *) fieldByName:(NSString *)name {
    return [headers objectForKey:[name lowercaseString]];
}

-(void) setField:(NSString *)value byName:(NSString *)name {
    [headers setObject:value forKey:[name lowercaseString]];
}

-(void) removeFieldByName:(NSString *)name {
    [headers removeObjectForKey:[name lowercaseString]];
}

-(NSString *) toString {
    NSString *result;
    
    @autoreleasepool {
        NSString *firstLine = [line componentsJoinedByString:@" "];
        NSMutableArray *fields = [NSMutableArray arrayWithCapacity:[headers count]];
        
        for(NSString *name in headers) {
            NSString *field = [NSString stringWithFormat:@"%@: %@\r\n", name, [headers objectForKey:name]];
            [fields addObject:field];
        }
        
        result = [NSString stringWithFormat:@"%@\r\n%@\r\n", firstLine, [fields componentsJoinedByString:@""]];
        [result retain];
    }
    
    return [result autorelease];
}

-(NSString*) description {
    return [headers description];
}

-(void) dealloc {
    [headers release];
    [line release];
    
    [super dealloc];
}
@end

@implementation HttpRequestHeaders
-(id) init {
    if(self = [super init]) {
        self.method = @"GET";
        self.url = @"/";
        self.httpVersion = @"HTTP/1.1";
    }
    
    return self;
}

-(id) initWithString:(NSString *)headers error:(NSError **)error {
    if(self = [super initWithString:headers error:error]) {
        self.method = [line objectAtIndex:0];
        self.url = [line objectAtIndex:1];
        self.httpVersion = [line objectAtIndex:2];
    }
    
    return self;
}

-(NSString *) toString {
    [line replaceObjectAtIndex:0 withObject:self.method];
    [line replaceObjectAtIndex:1 withObject:self.url];
    [line replaceObjectAtIndex:2 withObject:self.httpVersion];
    
    return [super toString];
}

-(void) dealloc {
    [self.method release];
    [self.url release];
    [self.httpVersion release];
    
    [super dealloc];
}
@end

@implementation HttpResponseHeaders
-(id) init {
    if(self = [super init]) {
        self.httpVersion = @"HTTP/1.1";
        self.statusCode = HttpStatusCodeOk;
    }
    
    return self;
}

-(id) initWithString:(NSString *)headers error:(NSError **)error {
    if(self = [super initWithString:headers error:error]) {
        self.httpVersion = [line objectAtIndex:0];
        self.statusCode = [[line objectAtIndex:1] integerValue];
        self.reasonPhrase = [line objectAtIndex:2];
    }
    
    return self;
}

-(NSString *) toString {
    [line replaceObjectAtIndex:0 withObject:self.httpVersion];
    [line replaceObjectAtIndex:1 withObject:[NSString stringWithFormat:@"%ld", (long)self.statusCode]];
    [line replaceObjectAtIndex:2 withObject:(self.reasonPhrase ? self.reasonPhrase : HttpStatusCodeReasonPhrase(self.statusCode))];
    
    return [super toString];
}

-(void) dealloc {
    [self.httpVersion release];
    [self.reasonPhrase release];
    
    [super dealloc];
}
@end