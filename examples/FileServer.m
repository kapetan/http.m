#import <Foundation/Foundation.h>

#import "../http/HttpServer.h"

static NSString *mainHtml = @"<!DOCTYPE html> <html> <head> <title>%@</title> </head> <body> <h1>%@</h1> <table style=\"border:none;\"> <thead> <tr> <td></td><td></td> </tr> </thead> <tbody> %@ </tbody> </table> </body> </html>";

static NSString *entryHtml = @"<tr><td>%@</td><td><a href=\"%@\">%@</a></td></tr>";

static NSString *RenderDirectory(NSString *base, NSString *url, NSArray *files, NSFileManager *fs) {
    NSMutableArray *entries = [NSMutableArray array];
    
    for(NSString *fileName in files) {
        NSString *filePath = [url stringByAppendingPathComponent:fileName];
        
        // Remove base prefix to use for link href
        NSString *filePathRelative = [filePath
                                      stringByReplacingOccurrencesOfString:base
                                      withString:@"/" options:0 range:NSMakeRange(0, [base length])];
        
        BOOL isDirectory;
        [fs fileExistsAtPath:filePath isDirectory:&isDirectory];
        
        [entries addObject:[NSString stringWithFormat:entryHtml, (isDirectory ? @"D" : @"F"),
                            [filePathRelative stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding], fileName]];
    }
    
    return [NSString stringWithFormat:mainHtml, url, url, [entries componentsJoinedByString:@""]];
}

static HttpServer *CreateFileServer(NSString *base) {
    NSDictionary *mimeTypes = @{
        @[@"txt", @"m", @"h", @"markdown", @"md"] : @"text/plain",
        @[@"js"] : @"application/javascript",
        @[@"css"] : @"text/css",
        @[@"pdf"] : @"application/pdf",
        @[@"html", @"htm"] : @"text/html",
        @[@"jpg", @"jpeg"] : @"image/jpeg",
        @[@"png"] : @"image/png",
        @[@"gif"] : @"image/gif",
        @[@"bmp"] : @"image/bmp"
    };
    
    NSFileManager *fs = [NSFileManager defaultManager];

    HttpServer *server = [[HttpServer alloc] init];
    HttpServerBlockDelegate *serverDelegate = server.delegate;
    
    serverDelegate.request = ^(HttpServer *server, HttpServerRequest *request, HttpServerResponse *response) {
        if(request.header.contentLength) {
            // Refuse requests with a body
            [request.connection close];
            return;
        }
        
        // Resolve requested path to absolute url
        NSString *url = [base stringByAppendingPathComponent:
                         [request.header.url.pathname stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        
        BOOL isDirectory;
        BOOL exists = [fs fileExistsAtPath:url isDirectory:&isDirectory];
        
        if(!exists) {
            [response writeHeaderStatus:HttpStatusCodeNotFound
                                headers:@{ @"content-type" : @"text/plain; charset=utf-8", @"transfer-encoding" : @"chunked" }];
            [response write:[NSString stringWithFormat:@"%@ - Not Found", url] encoding:NSASCIIStringEncoding];
            [response end];
            
            return;
        }
        
        if(isDirectory) {
            NSError *error;
            NSArray *files = [fs contentsOfDirectoryAtPath:url error:&error];
            
            if(!files) {
                [response writeHeaderStatus:HttpStatusCodeInternalServerError];
                [response write:[error localizedDescription] encoding:NSUTF8StringEncoding];
                [response end];
                
                return;
            }
            
            // Render directory contents
            [response writeHeaderStatus:HttpStatusCodeOk
                                headers:@{ @"content-type" : @"text/html; charset=utf-8", @"transfer-encoding" : @"chunked" }];
            [response write:RenderDirectory(base, url, files, fs) encoding:NSUTF8StringEncoding];
            [response end];
            
            return;
        }
        
        NSString *extension = [[url pathExtension] lowercaseString];
        NSString *type = @"application/octet-stream";
        
        for(NSArray *key in mimeTypes) {
            if([key containsObject:extension]) {
                type = [mimeTypes objectForKey:key];
                break;
            }
        }
        
        if([type hasPrefix:@"text"]) {
            type = [NSString stringWithFormat:@"%@; charset=utf-8", type];
        }
        
        [response writeHeaderStatus:HttpStatusCodeOk headers:@{ @"content-type" : type, @"transfer-encoding" : @"chunked" }];
        [response write:[NSData dataWithContentsOfFile:url]];
        [response end];
    };
    
    return server;
}
