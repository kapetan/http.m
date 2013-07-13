//
//  HttpHeaderConstants.m
//  http
//
//  Created by Mirza Kapetanovic on 7/11/13.
//  Copyright (c) 2013 Mirza Kapetanovic. All rights reserved.
//

#import "HttpHeaderConstants.h"

NSInteger ArrayIndexOfString(NSString *const arr[], NSInteger length, NSString *str) {
    for(int i = 0; i < length; i++) {
        NSString *item = arr[i];
        
        if(item && [item isEqualToString:str]) {
            return i;
        }
    }
    
    return -1;
}

NSString *const HttpMethodNames[] = {
    [HttpMethodGet] = @"GET",
    [HttpMethodPost] = @"POST",
    [HttpMethodHead] = @"HEAD",
    [HttpMethodPut] = @"PUT",
    [HttpMethodDelete] = @"DELETE",
    [HttpMethodTrace] = @"TRACE",
    [HttpMethodOptions] = @"OPTIONS",
    [HttpMethodConnect] = @"CONNECT",
    [HttpMethodPath] = @"PATH"
};

NSString *HttpMethodName(HttpMethod method) {
    return HttpMethodNames[method];
}

HttpMethod HttpMethodValue(NSString *name) {
    return (HttpMethod) ArrayIndexOfString(HttpMethodNames, HttpMethodPath + 1, name);
}
