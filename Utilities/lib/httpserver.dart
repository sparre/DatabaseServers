library utilities.httpserver;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:route/server.dart';

import 'package:Utilities/common.dart';

final ContentType JSON_MIME_TYPE = new ContentType('application', 'json', charset: 'UTF-8');

void addCorsHeaders(HttpResponse res) {
  res.headers
    ..add("Access-Control-Allow-Origin", "*")
    ..add("Access-Control-Allow-Methods", "POST, GET, PUT, DELETE, OPTIONS")
    ..add("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept");
}

Filter auth(Uri authUrl) {
  return (HttpRequest request) {

    try {
      if(request.uri.queryParameters.containsKey('token')) {      
        String path = 'token/${request.uri.queryParameters['token']}/validate';
        Uri url = new Uri(scheme: authUrl.scheme, host: authUrl.host, port: authUrl.port, path: path);
        return http.get(url).then((response) {
          if (response.statusCode == 200) {
            return true;
          } else {
            request.response.statusCode = HttpStatus.FORBIDDEN;
            writeAndClose(request, JSON.encode({'description': 'Authorization failure.'}));
            return false;
          }
        }).catchError((error) {
          serverError(request, 'utilities.httpserver.auth() ${error} config.authUrl: "${authUrl}" final authurl: ${url}');
          return false;
        });
        
      } else {
        request.response.statusCode = HttpStatus.UNAUTHORIZED;
        writeAndClose(request, JSON.encode({'description': 'No token was specified'}));
        return new Future.value(false);
      }
    } catch (e) {
      logger.critical('utilities.httpserver.auth() ${e} authUrl: "${authUrl}"');
    }
  };
}


Future<String> extractContent(HttpRequest request) {
  Completer completer = new Completer();
  List<int> completeRawContent = new List<int>();

  request.listen((List<int> data) {
    completeRawContent.addAll(data);
  }, onError: (error) => completer.completeError(error),
     onDone: () {
    String content = UTF8.decode(completeRawContent);
    completer.complete(content);
  }, cancelOnError: true);

  return completer.future;
}

String mapToUrlFormEncodedPostBody(Map body) { 
  return body.keys.map((key) {
    try {    
      return '$key=${Uri.encodeQueryComponent(body[key])}';
    } catch (e) {
      logger.error('mapToUrlFormEncodedPostBody() Key "${key}", value "${body[key]}"');
      throw e;
    }
  }).join('&');
}

String queryParameter(Uri uri, String key) => uri.queryParameters.containsKey(key) ? uri.queryParameters[key] : null;

void page404(HttpRequest request) {
  addCorsHeaders(request.response);
  
  log('404: ${request.uri}');
  request.response.statusCode = HttpStatus.NOT_FOUND;
  request.response.write(JSON.encode({'error':'No handler found for ' + request.uri.toString() }));
  request.response.close();
}

int pathParameter(Uri uri, String key) {
  try {
    return int.parse(uri.pathSegments.elementAt(uri.pathSegments.indexOf(key) + 1));
  } catch(error) {
    log('utilities.httpserver.pathParameter failed $error Key: $key Uri: $uri');
    return null;
  }
}

void serverError(HttpRequest request, String logMessage) {
  logger.errorContext(logMessage, "serverError");
  request.response.statusCode = HttpStatus.INTERNAL_SERVER_ERROR;
  writeAndClose(request, JSON.encode({'error': 'Internal Server Error'}));
}

void clientError(HttpRequest request, String reason) {
  logger.error(reason);
  request.response.statusCode = HttpStatus.BAD_REQUEST;
  writeAndClose(request, JSON.encode({'error': reason}));
}

void resourceNotFound(HttpRequest request) {
  addCorsHeaders(request.response);
  
  log(HttpStatus.NOT_FOUND.toString() +': ${request.uri}');
  request.response.statusCode = HttpStatus.NOT_FOUND;
  request.response.write(JSON.encode({'error':'Resource not found.'}));
  request.response.close();
}

void start(int port, void setupRoutes(HttpServer server)) {
  HttpServer.bind(InternetAddress.ANY_IP_V4, port)
    .then(setupRoutes)
    .catchError((e) {
      logger.error('utilities.httpserver.start() -> HttpServer.bind() error: ${e}');
      throw e;
    });
}

void writeAndClose(HttpRequest request, String text) {
  String time = new DateTime.now().toString();
  
  StringBuffer sb        = new StringBuffer();
  final String logPrefix = request.response.statusCode == 200 ? 'Access' : 'Error';

  sb.write('${logPrefix} - ');
  sb.write('${request.uri} - ');
  
  if(request.connectionInfo != null) {
    sb.write('${request.connectionInfo.remoteAddress} - ');
  } else {
    sb.write('Unknown remote address - ');
  }
  
  sb.write(request.response.statusCode);
  log(sb.toString());
  
  addCorsHeaders(request.response);
  request.response.headers.contentType = JSON_MIME_TYPE;

  request.response
    ..write(text)
    ..write('\n')
    ..close();
}

Future<int> getUserID (HttpRequest request, Uri authUrl) {
  try {
    if(request.uri.queryParameters.containsKey('token')) {      
      String path = 'token/${request.uri.queryParameters['token']}';
      Uri url = new Uri(scheme: authUrl.scheme, host: authUrl.host, port: authUrl.port, path: path);
      return http.get(url).then((response) {
        if (response.statusCode == 200) {
          return JSON.decode(response.body)['id'];
        } else {
          return 0;
        }
      }).catchError((error) {
        return 0;
      });
      
    } else {
      return new Future.value(false);
    }
  } catch (e) {
    logger.critical('utilities.httpserver.auth() ${e} authUrl: "${authUrl}"');
  }
}

