import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'Exceptions/http_exception.dart';
import 'Exceptions/rpc_exception.dart';

class RPCClient {
  String host;
  int port;
  String username;
  String password;
  bool useSSL;
  Dio? _dioClient;
  late String _url;
  late Map<String, String> _headers;

  RPCClient({
    required this.host,
    required this.port,
    required this.username,
    required this.password,
    required this.useSSL,
  });

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.isGetter) {
      var s = invocation.memberName.toString();
      s = s.substring(8, s.length - 2);
      var ret = s.toLowerCase();
      return call(ret, []);
    }

    if (invocation.isSetter) {
      var s = invocation.memberName.toString();
      s = s.substring(8, s.length - 2);
      var method = s.toLowerCase();
      List<dynamic>? args = [];
      if (invocation.positionalArguments.length > 1) {
        args = invocation.positionalArguments;
      } else {
        if (invocation.positionalArguments.first is List) {
          args = invocation.positionalArguments.first;
        } else {
          args = [invocation.positionalArguments.first];
        }
      }
      return call(method, args);
    }

    if (invocation.isMethod) {
      var s = invocation.memberName.toString();
      s = s.substring(8, s.length - 2);
      var method = s.toLowerCase();
      List<dynamic>? args = [];
      if (invocation.positionalArguments.length > 1) {
        args = invocation.positionalArguments;
      } else {
        if (invocation.positionalArguments.first is List) {
          args = invocation.positionalArguments.first;
        } else {
          args = [invocation.positionalArguments.first];
        }
      }
      return call(method, args);
    }
  }

  String getConnectionString() {
    var urlString = 'http://';
    if (useSSL) {
      urlString = 'https://';
    }
    return '$urlString$host:$port';
  }

  Future<dynamic> call(var methodName, [var params]) async {
    // init values
    if (_dioClient == null) {
      _headers = {
        'Content-Type': 'application/json',
        'authorization':
            'Basic ${base64.encode(utf8.encode('$username:$password'))}'
      };
      _url = getConnectionString();
      _dioClient = Dio();
      _dioClient!.interceptors.add(
        RetryInterceptor(
          dio: _dioClient!,
          logPrint: null,
          retries: 5,
        ),
      );
    }
    var body = {
      'jsonrpc': '2.0',
      'method': methodName,
      'params': params ?? [],
      'id': '1'
    };

    try {
      var response = await _dioClient!.post(
        _url,
        data: body,
        options: Options(
          headers: _headers,
        ),
      );
      if (response.statusCode == HttpStatus.ok) {
        var body = response.data;
        if (body['error'] != null) {
          var error = body['error']['message'];
          throw RPCException(
            errorCode: error['code'],
            errorMsg: error['message'],
            method: methodName,
            params: params,
          );
        }
        return body['result'];
      }
    } on DioError catch (e) {
      if (e.type == DioErrorType.badResponse) {
        var errorResponseBody = e.message;

        switch (errorResponseBody) {
          case "The request returned an invalid status code of 401.":
            throw HTTPException(
              code: 401,
              message: 'Unauthorized',
            );
          case "The request returned an invalid status code of 403.":
            throw HTTPException(
              code: 403,
              message: 'Forbidden',
            );
          case "Http status error [404]":
            if (errorResponseBody != null) {
              throw RPCException(
                errorCode: 404,
                errorMsg: errorResponseBody,
                method: methodName,
                params: params ?? [],
              );
            }
            throw HTTPException(
              code: 500,
              message: 'Internal Server Error',
            );
          default:
            if (errorResponseBody != null) {
              throw RPCException(
                errorCode: 400,
                errorMsg: errorResponseBody,
                method: methodName,
                params: params ?? [],
              );
            }
            throw HTTPException(
              code: 500,
              message: 'Internal Server Error',
            );
        }
      } else if (e.type == DioErrorType.unknown) {
        throw HTTPException(
          code: 500,
          message: e.error.toString(),
        );
      }
    }
  }
}
