import 'package:test/test.dart';
import 'package:decimal/decimal.dart';
import 'package:ordinals_sdk/ordinals_sdk.dart';

void main() {
  group('BRC20Token', () {
    test('should create from Hiro JSON', () {
      final json = {
        'ticker': 'ordi',
        'max_supply': '21000000',
        'mint_limit': '1000',
        'minted_supply': '15000000',
        'decimals': 18,
        'deploy_inscription_id': 'abc123i0',
        'holder_count': 50000,
      };

      final token = BRC20Token.fromHiroJson(json);
      expect(token.tick, equals('ordi'));
      expect(token.maxSupply, equals(Decimal.parse('21000000')));
      expect(token.limitPerMint, equals(Decimal.parse('1000')));
      expect(token.mintedSupply, equals(Decimal.parse('15000000')));
      expect(token.holderCount, equals(50000));
      expect(token.isFullyMinted, isFalse);
    });

    test('should create from UniSat JSON', () {
      final json = {
        'tick': 'sats',
        'max': '2100000000000000',
        'lim': '100000000',
        'totalMinted': '2100000000000000',
        'holdersCount': 100000,
      };

      final token = BRC20Token.fromUniSatJson(json);
      expect(token.tick, equals('sats'));
      expect(token.isFullyMinted, isTrue);
      expect(token.remainingSupply, equals(Decimal.zero));
    });

    test('should calculate minted percentage', () {
      final token = BRC20Token(
        tick: 'test',
        maxSupply: Decimal.parse('100'),
        limitPerMint: Decimal.parse('10'),
        mintedSupply: Decimal.parse('75'),
      );

      expect(token.mintedPercentage, equals(75.0));
    });
  });

  group('BRC20Balance', () {
    test('should create from JSON', () {
      final json = {
        'tick': 'ordi',
        'available_balance': '1000',
        'transferable_balance': '500',
        'overall_balance': '1500',
      };

      final balance = BRC20Balance.fromJson(json);
      expect(balance.tick, equals('ordi'));
      expect(balance.availableBalance, equals(Decimal.parse('1000')));
      expect(balance.transferableBalance, equals(Decimal.parse('500')));
      expect(balance.overallBalance, equals(Decimal.parse('1500')));
    });
  });

  group('BRC20Activity', () {
    test('should parse operation types', () {
      final deployJson = {
        'tx_id': 'tx1',
        'tick': 'test',
        'operation': 'deploy',
        'amount': '21000000',
      };
      final deploy = BRC20Activity.fromJson(deployJson);
      expect(deploy.operation, equals(BRC20Operation.deploy));

      final mintJson = {
        'tx_id': 'tx2',
        'tick': 'test',
        'operation': 'mint',
        'amount': '1000',
      };
      final mint = BRC20Activity.fromJson(mintJson);
      expect(mint.operation, equals(BRC20Operation.mint));

      final transferJson = {
        'tx_id': 'tx3',
        'tick': 'test',
        'operation': 'transfer',
        'amount': '500',
      };
      final transfer = BRC20Activity.fromJson(transferJson);
      expect(transfer.operation, equals(BRC20Operation.transfer));
    });
  });

  group('BRC20DeployParams', () {
    test('should create valid params', () {
      final params = BRC20DeployParams(
        tick: 'test',
        maxSupply: Decimal.parse('21000000'),
        limitPerMint: Decimal.parse('1000'),
      );

      expect(params.tick, equals('test'));
      expect(params.decimals, equals(18));
    });

    test('should throw for invalid ticker length', () {
      expect(
        () => BRC20DeployParams(
          tick: 'toolong',
          maxSupply: Decimal.parse('21000000'),
          limitPerMint: Decimal.parse('1000'),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should generate correct inscription JSON', () {
      final params = BRC20DeployParams(
        tick: 'test',
        maxSupply: Decimal.parse('21000000'),
        limitPerMint: Decimal.parse('1000'),
        decimals: 8,
      );

      final json = params.toInscriptionJson();
      expect(json['p'], equals('brc-20'));
      expect(json['op'], equals('deploy'));
      expect(json['tick'], equals('test'));
      expect(json['max'], equals('21000000'));
      expect(json['lim'], equals('1000'));
      expect(json['dec'], equals('8'));
    });
  });

  group('BRC20MintParams', () {
    test('should generate correct inscription JSON', () {
      final params = BRC20MintParams(
        tick: 'ordi',
        amount: Decimal.parse('1000'),
      );

      final json = params.toInscriptionJson();
      expect(json['p'], equals('brc-20'));
      expect(json['op'], equals('mint'));
      expect(json['tick'], equals('ordi'));
      expect(json['amt'], equals('1000'));
    });
  });

  group('BRC20TransferParams', () {
    test('should generate correct inscription JSON', () {
      final params = BRC20TransferParams(
        tick: 'sats',
        amount: Decimal.parse('100000'),
      );

      final json = params.toInscriptionJson();
      expect(json['p'], equals('brc-20'));
      expect(json['op'], equals('transfer'));
      expect(json['tick'], equals('sats'));
      expect(json['amt'], equals('100000'));
    });
  });
}
