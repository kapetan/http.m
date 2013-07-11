//
//  HttpHeaderConstants.h
//  http
//
//  Created by Mirza Kapetanovic on 7/11/13.
//  Copyright (c) 2013 Mirza Kapetanovic. All rights reserved.
//

#import <Foundation/Foundation.h>

NSInteger ArrayIndexOfString(NSString *const arr[], NSInteger length, NSString *str);

typedef enum {
    HttpMethodGet = 0,
    HttpMethodPost,
    HttpMethodHead,
    HttpMethodPut,
    HttpMethodDelete,
    HttpMethodTrace,
    HttpMethodOptions,
    HttpMethodConnect,
    HttpMethodPath
} HttpMethod;

NSString *const HttpMethodNames[HttpMethodPath + 1];
NSString *HttpMethodName(HttpMethod method);
HttpMethod HttpMethodValue(NSString *name);

typedef enum {
    HttpHeaderTransferEncodingChunked = 0,
    HttpHeaderTransferEncodingCompress,
    HttpHeaderTransferEncodingDeflate,
    HttpHeaderTransferEncodingGzip,
    HttpHeaderTransferEncodingIdentity
} HttpHeaderTransferEncoding;

NSString *const HttpHeaderTransferEncodingNames[HttpHeaderTransferEncodingIdentity + 1];
NSString *HttpHeaderTransferEncodingName(HttpHeaderTransferEncoding encoding);
HttpHeaderTransferEncoding HttpHeaderTransferEncodingValue(NSString *name);
