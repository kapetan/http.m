//
//  HttpHeader.m
//  http
//
//  Created by Mirza Kapetanovic on 7/2/13.
//  Copyright (c) 2013 Mirza Kapetanovic. All rights reserved.
//

#import "HttpHeader.h"
#import "HttpError.h"

NSString* NSStringTrimmedByWhiteSpace(NSString *str) {
    return [str stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

NSDateFormatter *NSDateFormatterCreateRFC1123() {
    NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    
    [formatter setLocale:locale];
    [formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    [formatter setDateFormat:@"EEE',' dd MMM yyyy HH':'mm':'ss zzz"];
    
    [locale release];
    
    return formatter;
}

@implementation HttpHeader {
    NSMutableDictionary *headers;
    NSDateFormatter *formatter;
    
    @protected
    NSMutableArray *line;
}

-(id) init {
    if(self = [super init]) {
        NSNull *n = [NSNull null];
        
        self->headers = [[NSMutableDictionary alloc] init];
        self->line = [[NSMutableArray alloc] initWithObjects:n, n, n, nil];
        self->formatter = NSDateFormatterCreateRFC1123();
    }
    
    return self;
}

-(id) initWithString:(NSString *)str error:(NSError **)error {
    if(self = [super init]) {
        NSMutableDictionary *result = self->headers = [[NSMutableDictionary alloc] init];
        
        NSArray *fields = [str componentsSeparatedByString:@"\r\n"];
        NSArray *firstLine = [[fields objectAtIndex:0]
                         componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        
        NSInteger i = 1;
        NSString *field;
        while(i < [fields count] && [(field = [fields objectAtIndex:i]) length] > 0) {
            NSRange separator = [field rangeOfString:@":"];
            
            if(separator.location == NSNotFound) {
                if(error != NULL) {
                    *error = NSErrorWithReason(HttpErrorUnparsableHeader, @"Invalid header field");
                }
                
                [self release];
                return nil;
            }
            
            NSString *fieldName = [NSStringTrimmedByWhiteSpace([field substringToIndex:separator.location]) lowercaseString];
            NSString *fieldValue = NSStringTrimmedByWhiteSpace([field substringFromIndex:separator.location + 1]);
            
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
            
            [self release];
            return nil;
        }
        
        self->line = [[NSMutableArray alloc] initWithArray:firstLine];
        self->formatter = NSDateFormatterCreateRFC1123();
    }
    
    return self;
}

-(NSString *) fieldValue:(NSString *)name {
    return [headers objectForKey:[name lowercaseString]];
}

-(void) setValue:(NSString *)value forField:(NSString *)name {
    [headers setObject:value forKey:[name lowercaseString]];
}

-(void) removeField:(NSString *)name {
    [headers removeObjectForKey:[name lowercaseString]];
}

-(NSInteger) contentLength {
    NSString *length = [self fieldValue:@"content-length"];
    
    if(length) {
        return [length integerValue];
    }
    
    return 0;
}

-(void) setContentLength:(NSInteger)contentLength {
    [self setValue:[NSString stringWithFormat:@"%ld", (long)contentLength] forField:@"content-length"];
}

-(NSDate *) date {
    NSString *date = [self fieldValue:@"date"];
    
    if(date) {
        return [formatter dateFromString:date];
    }
    
    return nil;
}

-(void) setDate:(NSDate *)date {
    [self setValue:[formatter stringFromDate:date] forField:@"date"];
}

-(NSString *) toString {
    NSString *result;
    
    NSString *firstLine = [line componentsJoinedByString:@" "];
    NSMutableArray *fields = [NSMutableArray arrayWithCapacity:[headers count]];
        
    for(NSString *name in headers) {
        NSString *field = [NSString stringWithFormat:@"%@: %@\r\n", name, [headers objectForKey:name]];
        [fields addObject:field];
    }
        
    result = [NSString stringWithFormat:@"%@\r\n%@\r\n", firstLine, [fields componentsJoinedByString:@""]];
    [result retain];
    
    return [result autorelease];
}

-(NSString *) lineToString {
    return [line componentsJoinedByString:@" "];
}

-(NSString*) description {
    return [headers description];
}

-(void) dealloc {
    [headers release];
    [line release];
    [formatter release];
    
    [super dealloc];
}
@end

@implementation HttpRequestHeader
-(id) init {
    if(self = [super init]) {
        self.method = HttpMethodGet;
        self.url = @"/";
        self.httpVersion = @"HTTP/1.1";
    }
    
    return self;
}

-(HttpMethod) method {
    return HttpMethodValue([line objectAtIndex:0]);
}

-(void) setMethod:(HttpMethod)method {
    [line replaceObjectAtIndex:0 withObject:HttpMethodName(method)];
}

-(NSString *) url {
    return [line objectAtIndex:1];
}

-(void) setUrl:(NSString *)url {
    [line replaceObjectAtIndex:1 withObject:url];
}

-(NSString *) httpVersion {
    return [line objectAtIndex:2];
}

-(void) setHttpVersion:(NSString *)httpVersion {
    [line replaceObjectAtIndex:2 withObject:httpVersion];
}

-(BOOL) hasBody {
    return self.contentLength > 0;
}
@end

@implementation HttpResponseHeader {
    BOOL reasonPhraseAssigned;
}

-(id) init {
    if(self = [super init]) {
        self.httpVersion = @"HTTP/1.1";
        self.statusCode = HttpStatusCodeOk;
        
        self->reasonPhraseAssigned = NO;
    }
    
    return self;
}

-(id) initWithString:(NSString *)headers error:(NSError **)error {
    if(self = [super initWithString:headers error:error]) {
        self->reasonPhraseAssigned = NO;
    }
    
    return self;
}

-(NSString *) httpVersion {
    return [line objectAtIndex:0];
}

-(void) setHttpVersion:(NSString *)httpVersion {
    [line replaceObjectAtIndex:0 withObject:httpVersion];
}

-(HttpStatusCode) statusCode {
    return (HttpStatusCode) [[line objectAtIndex:1] integerValue];
}

-(void) setStatusCode:(HttpStatusCode)statusCode {
    [line replaceObjectAtIndex:1 withObject:[NSString stringWithFormat:@"%ld", (long) statusCode]];
    
    if(!reasonPhraseAssigned) {
        self.reasonPhrase = HttpStatusCodeReasonName(HttpStatusCodeOk);
        reasonPhraseAssigned = NO;
    }
}

-(NSString *) reasonPhrase {
    return [line objectAtIndex:2];
}

-(void) setReasonPhrase:(NSString *)reasonPhrase {
    [line replaceObjectAtIndex:2 withObject:reasonPhrase];
    reasonPhraseAssigned = YES;
}
@end