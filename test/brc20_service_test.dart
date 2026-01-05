import 'package:decimal/decimal.dart';
import 'package:dio/dio.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:ordinals_sdk/ordinals_sdk.dart';
import 'package:ordinals_sdk/src/core/transaction_broadcaster.dart';
import 'package:test/test.dart';

import 'brc20_service_test.mocks.dart';

@GenerateMocks([Dio, TransactionBroadcaster])
void main() {
  group('BRC20Service', () {
    late BRC20Service service;
    late MockDio mockDio;
    late MockTransactionBroadcaster mockBroadcaster;

    const validMainnetWif =
        'KwDiBf89QgGbjEhKnhXJuH7LrciVrZi3qYjgd9M7rFU73sVHnoWn';
    const address = '17VZNX1SN5NtKa8UQFxwQbFeFc3iqRYhem';
    final utxos = [
      {
        'txid':
            '7fe2c92e920b777429b49b4f9d4c7b8c8d8c8d8c8d8c8d8c8d8c8d8c8d8c8d8c',
        'vout': 0,
        'value': 20000,
        'address': address
      }
    ];

    setUp(() {
      mockDio = MockDio();
      mockBroadcaster = MockTransactionBroadcaster();
      when(mockDio.options).thenReturn(BaseOptions());

      service = BRC20Service(
        dio: mockDio,
        broadcaster: mockBroadcaster,
        isTestnet: false,
      );
    });

    test('deployToken should broadcast commit and reveal transactions',
        () async {
      when(mockDio.get(any, queryParameters: anyNamed('queryParameters')))
          .thenThrow(DioException(
        requestOptions: RequestOptions(path: ''),
        response: Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 404,
        ),
      ));

      when(mockBroadcaster.broadcast(any)).thenAnswer((_) async =>
          '7fe2c92e920b777429b49b4f9d4c7b8c8d8c8d8c8d8c8d8c8d8c8d8c8d8c8d8c');

      final params = BRC20DeployParams(
        tick: 'test',
        maxSupply: Decimal.parse('21000000'),
        limitPerMint: Decimal.parse('1000'),
      );

      final result = await service.deployToken(
        params: params,
        privateKeyWif: validMainnetWif,
        address: address,
        utxos: utxos,
        feeRate: 10,
      );

      expect(result.isSuccess, isTrue);
      verify(mockBroadcaster.broadcast(any)).called(2);
    });

    test('mintToken should broadcast commit and reveal transactions', () async {
      when(mockDio.get('/brc-20/tokens/ordi')).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: ''),
            data: {
              'token': {
                'ticker': 'ordi',
                'max_supply': '21000000',
                'minted_supply': '10000000',
                'mint_limit': '1000'
              }
            },
            statusCode: 200,
          ));

      when(mockBroadcaster.broadcast(any)).thenAnswer((_) async =>
          '7fe2c92e920b777429b49b4f9d4c7b8c8d8c8d8c8d8c8d8c8d8c8d8c8d8c8d8c');

      final params =
          BRC20MintParams(tick: 'ordi', amount: Decimal.parse('1000'));

      final result = await service.mintToken(
        params: params,
        privateKeyWif: validMainnetWif,
        address: address,
        utxos: utxos,
        feeRate: 10,
      );

      if (!result.isSuccess) print('Mint failed: ${result.errorOrNull}');
      expect(result.isSuccess, isTrue);
      verify(mockBroadcaster.broadcast(any)).called(2);
    });

    test('createTransferInscription should verify balance and broadcast',
        () async {
      when(mockDio.get('/brc-20/balances/$address',
              queryParameters: anyNamed('queryParameters')))
          .thenAnswer((_) async => Response(
                requestOptions: RequestOptions(path: ''),
                data: {
                  'results': [
                    {
                      'ticker': 'ordi',
                      'available_balance': '5000',
                      'transferable_balance': '0',
                      'overall_balance': '5000'
                    }
                  ]
                },
                statusCode: 200,
              ));

      when(mockBroadcaster.broadcast(any)).thenAnswer((_) async =>
          '7fe2c92e920b777429b49b4f9d4c7b8c8d8c8d8c8d8c8d8c8d8c8d8c8d8c8d8c');

      final params =
          BRC20TransferParams(tick: 'ordi', amount: Decimal.parse('1000'));

      final result = await service.createTransferInscription(
        params: params,
        privateKeyWif: validMainnetWif,
        address: address,
        utxos: utxos,
        feeRate: 10,
      );

      expect(result.isSuccess, isTrue);
      verify(mockBroadcaster.broadcast(any)).called(2);
    });

    test('mintToken should fail if amount exceeds limit', () async {
      when(mockDio.get('/brc-20/tokens/ordi')).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: ''),
            data: {
              'token': {
                'ticker': 'ordi',
                'max_supply': '21000000',
                'minted_supply': '10000000',
                'mint_limit': '1000'
              }
            },
            statusCode: 200,
          ));

      final params =
          BRC20MintParams(tick: 'ordi', amount: Decimal.parse('2000'));
      final result = await service.mintToken(
        params: params,
        privateKeyWif: validMainnetWif,
        address: address,
        utxos: utxos,
        feeRate: 10,
      );

      expect(result.isFailure, isTrue);
      expect(result.errorOrNull, contains('Amount exceeds mint limit'));
    });

    test('createTransferInscription should fail if insufficient balance',
        () async {
      when(mockDio.get('/brc-20/balances/$address',
              queryParameters: anyNamed('queryParameters')))
          .thenAnswer((_) async => Response(
                requestOptions: RequestOptions(path: ''),
                data: {
                  'results': [
                    {
                      'ticker': 'ordi',
                      'available_balance': '500',
                      'transferable_balance': '0',
                      'overall_balance': '500'
                    }
                  ]
                },
                statusCode: 200,
              ));

      final params =
          BRC20TransferParams(tick: 'ordi', amount: Decimal.parse('1000'));
      final result = await service.createTransferInscription(
        params: params,
        privateKeyWif: validMainnetWif,
        address: address,
        utxos: utxos,
        feeRate: 10,
      );

      expect(result.isFailure, isTrue);
      expect(result.errorOrNull, contains('Insufficient balance'));
    });
  });
}
