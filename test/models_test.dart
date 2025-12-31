import 'package:test/test.dart';
import 'package:ordinals_sdk/ordinals_sdk.dart';

void main() {
  group('UTXO', () {
    test('should create from constructor', () {
      final utxo = UTXO(
        txid: 'abc123...',
        vout: 0,
        value: 10000,
        address: 'bc1q...',
      );

      expect(utxo.txid, equals('abc123...'));
      expect(utxo.vout, equals(0));
      expect(utxo.value, equals(10000));
      expect(utxo.address, equals('bc1q...'));
      expect(utxo.outpoint, equals('abc123...:0'));
    });

    test('should create from JSON', () {
      final json = {
        'txid': 'def456...',
        'vout': 1,
        'value': 50000,
        'address': 'bc1p...',
        'isSegwit': true,
        'status': {'confirmed': true},
      };

      final utxo = UTXO.fromJson(json);
      expect(utxo.txid, equals('def456...'));
      expect(utxo.vout, equals(1));
      expect(utxo.value, equals(50000));
      expect(utxo.isSegwit, isTrue);
      expect(utxo.isConfirmed, isTrue);
    });

    test('should convert to JSON', () {
      final utxo = UTXO(
        txid: 'xyz789...',
        vout: 2,
        value: 546,
        address: 'tb1q...',
      );

      final json = utxo.toJson();
      expect(json['txid'], equals('xyz789...'));
      expect(json['vout'], equals(2));
      expect(json['value'], equals(546));
    });
  });

  group('Inscription', () {
    test('should create from Hiro JSON', () {
      final json = {
        'id': 'abc123i0',
        'number': 12345,
        'content_type': 'text/plain',
        'content_length': 100,
        'genesis_tx_id': 'tx123...',
        'genesis_block_height': 800000,
        'address': 'bc1p...',
        'output': 'tx123...:0',
        'sat_rarity': 'common',
      };

      final inscription = Inscription.fromHiroJson(json);
      expect(inscription.id, equals('abc123i0'));
      expect(inscription.number, equals(12345));
      expect(inscription.contentType, equals('text/plain'));
      expect(inscription.genesisTxId, equals('tx123...'));
      expect(inscription.isText, isTrue);
      expect(inscription.isImage, isFalse);
    });

    test('should create from UniSat JSON', () {
      final json = {
        'inscriptionId': 'def456i0',
        'inscriptionNumber': 67890,
        'contentType': 'image/png',
        'address': 'bc1q...',
      };

      final inscription = Inscription.fromUniSatJson(json);
      expect(inscription.id, equals('def456i0'));
      expect(inscription.number, equals(67890));
      expect(inscription.contentType, equals('image/png'));
      expect(inscription.isImage, isTrue);
    });

    test('should detect BRC-20 inscriptions', () {
      final brc20 = Inscription(
        id: 'brc20i0',
        contentType: 'text/plain',
        metadata: {'protocol': 'brc-20'},
      );
      expect(brc20.isBRC20, isTrue);

      final jsonBrc20 = Inscription(
        id: 'json123',
        contentType: 'application/json',
      );
      expect(jsonBrc20.isBRC20, isTrue);

      final image = Inscription(
        id: 'img123',
        contentType: 'image/png',
      );
      expect(image.isBRC20, isFalse);
    });
  });
}
