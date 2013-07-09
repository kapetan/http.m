//
//  HttpStatusCodes.m
//  http
//
//  Created by Mirza Kapetanovic on 7/9/13.
//  Copyright (c) 2013 Mirza Kapetanovic. All rights reserved.
//

#import "HttpStatusCodes.h"

NSString *const HttpStatusCodeReason[] = {
    [HttpStatusCodeContinue] = @"Continue",
    [HttpStatusCodeSwitchingProtocols] = @"Switching Protocols",
    [HttpStatusCodeProcessing] = @"Processing",
    [HttpStatusCodeOk] = @"OK",
    [HttpStatusCodeCreated] = @"Created",
    [HttpStatusCodeAccepted] = @"Accepted",
    [HttpStatusCodeMultipleChoices] = @"Multiple Choices",
    [HttpStatusCodeMovedPermanently] = @"Moved Permanently",
    [HttpStatusCodeFound] = @"Found",
    [HttpStatusCodeSeeOther] = @"See Other",
    [HttpStatusCodeNotModified] = @"Not Modified",
    [HttpStatusCodeTemporaryRedirect] = @"Temporary Redirect",
    [HttpStatusCodePermanentRedirect] = @"Permanent Redirect",
    [HttpStatusCodeBadRequest] = @"Bad Request",
    [HttpStatusCodeUnauthorized] = @"Unauthorized",
    [HttpStatusCodePaymentRequired] = @"Payment Required",
    [HttpStatusCodeForbidden] = @"Forbidden",
    [HttpStatusCodeNotFound] = @"Not Found",
    [HttpStatusCodeMethodNotAllowed] = @"Method Not Allowed",
    [HttpStatusCodeConflict] = @"Conflict",
    [HttpStatusCodeLengthRequired] = @"Length Required",
    [HttpStatusCodeInternalServerError] = @"Internal Server Error",
    [HttpStatusCodeBadGateway] = @"Bad Gateway",
    [HttpStatusCodeServiceUnavailable] = @"Service Unavailable",
    [HttpStatusCodeHttpVersionNotSupported] = @"Http Version Not Supported"
};

NSString *HttpStatusCodeReasonPhrase(HttpStatusCode code)  {
    return HttpStatusCodeReason[code];
}
