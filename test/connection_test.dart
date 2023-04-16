import 'package:dart_coin_rpc/dart_coin_rpc.dart';
import 'package:test/test.dart';

void main() async {
  RPCClient client = RPCClient(
    username: 'rpc',
    password: 'password',
    port: 9902,
    host: '127.0.0.1',
    useSSL: false,
  );
  group(
    'success',
    () {
      test(
        'try call with parameters',
        () async {
          var res = await client.call(
            'validateaddress',
            ["p92W3t7YkKfQEPDb7cG9jQ6iMh7cpKLvwK"],
          ) as Map;
          assert(res["isvalid"] == true);
        },
      );
      test(
        'try call without parameters',
        () async {
          var res = await client.call('help') as String;
          assert(res.contains('walletlock'));
        },
      );
    },
  );
  group(
    'failure',
    () {
      test(
        'try wrong credentials',
        () async {
          var client = RPCClient(
            username: 'rpc',
            password: 'verywrongpassword',
            port: 9902,
            host: '127.0.0.1',
            useSSL: false,
          );
          expect(
            () async => await client.call('help'),
            throwsA(
              isA<HTTPException>(),
            ),
          );
        },
      );
      test(
        'try wrong port',
        () async {
          var wrongClient = RPCClient(
            username: 'rpc',
            password: 'verywrongpassword',
            port: 9999,
            host: '127.0.0.1',
            useSSL: false,
          );
          expect(
            () async => await wrongClient.call('help'),
            throwsA(
              isA<HTTPException>(),
            ),
          );
        },
      );
      test(
        'try invalid method',
        () async {
          expect(
            () async => await client.call('helpwontbeprovided'),
            throwsA(
              isA<RPCException>(),
            ),
          );
        },
      );
      test(
        'try sendrawtransaction with invalid hex',
        () async {
          expect(
            () async => await client.call(
              'sendrawtransaction',
              ["asdf"],
            ),
            throwsA(
              isA<RPCException>(),
            ),
          );
        },
      );
    },
  );
}
