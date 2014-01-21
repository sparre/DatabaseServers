part of authenticationserver.router;

void validateToken(HttpRequest request) {
  String token = queryParameter(request.uri, 'token');
  
  if(token != null && token.isNotEmpty) {
    cache.loadToken(token).then((_) {
      request.response.statusCode = 200;
      writeAndClose(request, '{}');
    }).catchError((_) {
      request.response.statusCode = 401;
      writeAndClose(request, '{}');
    });
  } else {
    request.response.statusCode = 401;
    writeAndClose(request, '{}');
  }
}