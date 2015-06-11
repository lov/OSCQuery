//
//  Header.h
//  OSCQueryTest
//
//  Created by Tamas Nagy on 10/06/15.
//  Copyright (c) 2015 Imimot Kft. All rights reserved.
//

#define OSCQUERY_FULL_PATH @"FULL_PATH"
#define OSCQUERY_DESCRIPTION @"DESCRIPTION"
#define OSCQUERY_CONTENTS @"CONTENTS"
#define OSCQUERY_TYPE @"TYPE"
#define OSCQUERY_RANGE @"RANGE"

#define ROOT_NODE_DESCRIPTION @"root node"

#define OSC_TYPE_INT @"i"
#define OSC_TYPE_FLOAT @"f"
#define OSC_TYPE_STRING @"s"
#define OSC_TYPE_NIL @"N"

#define OSC_QUERY_REPLY_RECEIVED @"QUERYREPLY"

#define HTTP_HEADER 0
#define HTTP_BODY 10
#define HTTP_REQUEST_GET 20
#define HTTP_REQUEST_UNKNOWN 29
#define HTTP_RESPONSE 30

#define HTTP_STATUS_OK 200
#define HTTP_STATUS_NO_CONTENT 204
#define HTTP_STATUS_BAD_REQUEST 400
#define HTTP_STATUS_NOT_FOUND 404
#define HTTP_STATUS_TIMEOUT 408

#define HTTP_CONTENT_TYPE_JSON @"application/json"

#define HTTP_SUPPORTED_VERSION @"HTTP/1.1"

#define HTTP_NOLENGTH -1

#define HTTP_RESPONSE_HEADER_200_OK @"HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nConnection: keep-alive\r\nCache-Control: no-cache,must-revalidate\r\n"
#define HTTP_RESPONSE_HEADER_CRLF @"\r\n"

// header for a HTTP GET - _%GETURL%_ should be replaced with the GET address
// _%HOST%_ should be replaced with the host address
// \r\n\r\n at the end closes the header
#define HTTP_GET_HEADER @"GET _%GETURL%_ HTTP/1.1\r\nAccept: application/json\r\nHost: _%HOST%_\r\n\r\n"
