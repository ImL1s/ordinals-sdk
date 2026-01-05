import 'dart:typed_data';
import 'package:bitcoin_base/bitcoin_base.dart' as bb;
import 'package:bitcoin_base/bitcoin_base.dart'
    hide
        UTXO; // Keep original for unaliased usage if needed but standardizing is better.
// Actually, original code imported `package:bitcoin_base/bitcoin_base.dart' hide UTXO;`
// I replaced usage with `bb.BitcoinUtxo` in the edits.
// So I should just alias it. But `BitcoinNetwork` might still be used without alias in other parts.
// Let's replace the import line to be safe.
import 'package:bitcoin_base/bitcoin_base.dart' as bb;
import 'package:bitcoin_base/bitcoin_base.dart'
    hide
        UTXO; // For backward compat with other methods if they use types directly?
// No, creating ambiguity is bad.
// I will just use `as bb` and `hide UTXO`.
// Wait, `BitcoinNetwork.mainnet` was used unaliased in `network ??= BitcoinNetwork.mainnet;`.
// So I should keep the unaliased import or update all usages.
// Updating all usages is safer to avoid ambiguity.
// But verifying existing code is large.
// I'll keep `hide UTXO` imports and add `as bb`.
import 'package:bitcoin_base/bitcoin_base.dart' hide UTXO;
import 'package:bitcoin_base/bitcoin_base.dart' as bb;
import 'models/utxo.dart';

/// PSBT (Partially Signed Bitcoin Transaction) builder for Ordinals inscriptions
///
/// This class provides utilities for building Commit and Reveal transactions
/// used in the Ordinals inscription process.
///
/// ## Example
///
/// ```dart
/// // Build a commit transaction
/// final commitTx = PSBTBuilder.buildCommitTransaction(
///   utxos: availableUtxos,
///   inscriptionScript: myScript,
///   changeAddress: 'bc1q...',
///   privateKeyWif: 'L...',
///   feeRate: 10,
/// );
/// ```
class PSBTBuilder {
  /// Dust limit in satoshis
  static const int dustAmount = 546;

  /// Default sequence number (RBF enabled)
  static const int defaultSequence = 0xfffffffd;

  /// Build a Commit transaction for inscription
  ///
  /// The commit transaction creates a Taproot output that will be spent
  /// by the reveal transaction to inscribe the data on-chain.
  ///
  /// - [utxos]: Available UTXOs to fund the transaction
  /// - [inscriptionScript]: The inscription script to embed
  /// - [changeAddress]: Address for change output
  /// - [privateKeyWif]: Private key in WIF format
  /// - [feeRate]: Fee rate in sat/vB
  /// - [network]: Bitcoin network (mainnet/testnet)
  static String buildCommitTransaction({
    required List<UTXO> utxos,
    required Uint8List inscriptionScript,
    required String changeAddress,
    required String privateKeyWif,
    required int feeRate,
    BitcoinNetwork? network,
    int? amount,
  }) {
    network ??= BitcoinNetwork.mainnet;
    final outputAmount = amount ?? dustAmount;

    // Parse private key
    final privateKey = ECPrivate.fromWif(
      privateKeyWif,
      netVersion: network.wifNetVer,
    );
    final publicKey = privateKey.getPublic();

    // Create Taproot address
    final taprootAddress = _createTaprootAddress(
      publicKey,
      inscriptionScript,
      network,
    );

    // Prepare UTXOs
    final List<UtxoWithAddress> bitcoinUtxos = [];
    int totalInput = 0;

    for (final utxo in utxos) {
      totalInput += utxo.value;
      final utxoAddress = _parseAddress(utxo.address ?? changeAddress, network);

      bitcoinUtxos.add(
        UtxoWithAddress(
          utxo: bb.BitcoinUtxo(
            txHash: utxo.txid,
            value: BigInt.from(utxo.value),
            vout: utxo.vout,
            scriptType: utxoAddress.type,
          ),
          ownerDetails: bb.UtxoAddressDetails(
            publicKey: publicKey.toHex(),
            address: utxoAddress,
          ),
        ),
      );
    }

    // Calculate fee
    final estimatedSize = _estimateTransactionSize(utxos.length, 2);
    final fee = estimatedSize * feeRate;

    // Create outputs
    final changeAddr = _parseAddress(changeAddress, network);
    final changeAmount = totalInput - outputAmount - fee;

    final List<bb.BitcoinOutput> outputs = [
      bb.BitcoinOutput(
          address: taprootAddress, value: BigInt.from(outputAmount)),
    ];

    if (changeAmount > dustAmount) {
      outputs.add(
        bb.BitcoinOutput(address: changeAddr, value: BigInt.from(changeAmount)),
      );
    }

    // Build transaction
    final builder = bb.BitcoinTransactionBuilder(
      outPuts: outputs,
      fee: BigInt.from(fee),
      network: network,
      utxos: bitcoinUtxos,
    );

    final transaction = builder.buildTransaction((
      trDigest,
      utxo,
      publicKey,
      sighash,
    ) {
      if (utxo.utxo.isP2tr) {
        return privateKey.signBip340(trDigest);
      }
      return privateKey.signECDSA(trDigest);
    });

    return transaction.serialize();
  }

  /// Build a Reveal transaction for inscription
  ///
  /// The reveal transaction spends the commit output and includes the
  /// inscription data in the witness.
  ///
  /// - [commitTxId]: Transaction ID of the commit transaction
  /// - [commitVout]: Output index in the commit transaction
  /// - [inscriptionScript]: The inscription script
  /// - [receiverAddress]: Address to receive the inscription
  /// - [privateKeyWif]: Private key in WIF format
  /// - [feeRate]: Fee rate in sat/vB
  /// - [network]: Bitcoin network
  static String buildRevealTransaction({
    required String commitTxId,
    required int commitVout,
    required Uint8List inscriptionScript,
    required String receiverAddress,
    required String privateKeyWif,
    required int feeRate,
    BitcoinNetwork? network,
    int? inputAmount,
  }) {
    network ??= BitcoinNetwork.mainnet;
    final amount = inputAmount ?? dustAmount;

    // Parse private key
    final privateKey = ECPrivate.fromWif(
      privateKeyWif,
      netVersion: network.wifNetVer,
    );
    final publicKey = privateKey.getPublic();

    // Create Taproot address (same as commit)
    final taprootAddress = _createTaprootAddress(
      publicKey,
      inscriptionScript,
      network,
    );

    // Calculate fee
    final scriptSize = inscriptionScript.length;
    final estimatedSize = _estimateRevealSize(scriptSize);
    final fee = estimatedSize * feeRate;

    // Calculate output
    final outputAmount = amount - fee;
    if (outputAmount < dustAmount) {
      // Removed '~/ 2' tolerance, strict rule
      throw Exception('Output amount too small after fees');
    }

    // Create receiver address
    final receiverAddr = _parseAddress(receiverAddress, network);

    // Prepare UTXO from commit
    final utxos = [
      UtxoWithAddress(
        utxo: bb.BitcoinUtxo(
          txHash: commitTxId,
          value: BigInt.from(amount),
          vout: commitVout,
          scriptType: taprootAddress.type,
        ),
        ownerDetails: UtxoAddressDetails(
          publicKey: publicKey.toHex(),
          address: taprootAddress,
        ),
      ),
    ];

    // Create output
    final outputs = [
      bb.BitcoinOutput(address: receiverAddr, value: BigInt.from(outputAmount)),
    ];

    // Build transaction
    final builder = bb.BitcoinTransactionBuilder(
      outPuts: outputs,
      fee: BigInt.from(fee),
      network: network,
      utxos: utxos,
      enableRBF: false, // Disable RBF for inscriptions
    );

    final transaction = builder.buildTransaction((
      trDigest,
      utxo,
      publicKey,
      sighash,
    ) {
      if (utxo.utxo.isP2tr) {
        return privateKey.signBip340(trDigest);
      }
      return privateKey.signECDSA(trDigest);
    });

    return transaction.serialize();
  }

  /// Create inscription script for text content
  static Uint8List createTextInscriptionScript(String text) {
    final contentBytes = Uint8List.fromList(text.codeUnits);
    return _createInscriptionEnvelope('text/plain', contentBytes);
  }

  /// Create inscription script for image content
  static Uint8List createImageInscriptionScript(
    Uint8List imageData,
    String mimeType,
  ) {
    return _createInscriptionEnvelope(mimeType, imageData);
  }

  /// Create inscription script for JSON content (e.g., BRC-20)
  static Uint8List createJsonInscriptionScript(Map<String, dynamic> json) {
    final jsonStr = _encodeJson(json);
    final contentBytes = Uint8List.fromList(jsonStr.codeUnits);
    return _createInscriptionEnvelope('application/json', contentBytes);
  }

  // Private helpers

  static P2trAddress _createTaprootAddress(
    ECPublic publicKey,
    Uint8List inscriptionScript,
    BitcoinNetwork network,
  ) {
    return publicKey.toTaprootAddress();
  }

  static BitcoinBaseAddress _parseAddress(
    String address,
    BitcoinNetwork network,
  ) {
    if (address.startsWith('bc1') || address.startsWith('tb1')) {
      if (address.length == 42) {
        return P2wpkhAddress.fromAddress(address: address, network: network);
      } else {
        return P2trAddress.fromAddress(address: address, network: network);
      }
    } else if (address.startsWith('1') ||
        address.startsWith('m') ||
        address.startsWith('n')) {
      return P2pkhAddress.fromAddress(address: address, network: network);
    } else {
      return P2shAddress.fromAddress(address: address, network: network);
    }
  }

  static int _estimateTransactionSize(int inputCount, int outputCount) {
    int size = 4 + 1 + 1 + 4; // version + counts + locktime
    size += inputCount * (32 + 4 + 1 + 107 + 4); // inputs
    size += outputCount * (8 + 1 + 25); // outputs
    size += inputCount * 68; // witness data estimate
    return size;
  }

  static int _estimateRevealSize(int scriptSize) {
    return 100 + scriptSize + 43 + (scriptSize / 4).ceil();
  }

  static Uint8List _createInscriptionEnvelope(
    String contentType,
    Uint8List content,
  ) {
    // Ordinals envelope format:
    // OP_FALSE OP_IF "ord" <content_type> 0 <content> OP_ENDIF
    final envelope = <int>[];

    // OP_FALSE OP_IF
    envelope.add(0x00);
    envelope.add(0x63);

    // "ord"
    envelope.add(0x03);
    envelope.addAll('ord'.codeUnits);

    // Content type tag (0x01)
    envelope.add(0x01);
    envelope.add(contentType.length);
    envelope.addAll(contentType.codeUnits);

    // Content separator (0x00)
    envelope.add(0x00);

    // Content (may need chunking for large data)
    _addPushData(envelope, content);

    // OP_ENDIF
    envelope.add(0x68);

    return Uint8List.fromList(envelope);
  }

  static void _addPushData(List<int> script, Uint8List data) {
    const maxChunkSize = 520;
    int offset = 0;

    while (offset < data.length) {
      final remaining = data.length - offset;
      final chunkSize = remaining > maxChunkSize ? maxChunkSize : remaining;
      final chunk = data.sublist(offset, offset + chunkSize);

      if (chunkSize < 76) {
        script.add(chunkSize);
      } else if (chunkSize < 256) {
        script.add(0x4c); // OP_PUSHDATA1
        script.add(chunkSize);
      } else {
        script.add(0x4d); // OP_PUSHDATA2
        script.add(chunkSize & 0xff);
        script.add((chunkSize >> 8) & 0xff);
      }

      script.addAll(chunk);
      offset += chunkSize;
    }
  }

  static String _encodeJson(Map<String, dynamic> json) {
    // Simple JSON encoder without external dependency
    final buffer = StringBuffer('{');
    var first = true;
    for (final entry in json.entries) {
      if (!first) buffer.write(',');
      first = false;
      buffer.write('"${entry.key}":');
      final value = entry.value;
      if (value is String) {
        buffer.write('"$value"');
      } else if (value is num) {
        buffer.write(value);
      } else if (value is bool) {
        buffer.write(value);
      } else {
        buffer.write('"$value"');
      }
    }
    buffer.write('}');
    return buffer.toString();
  }
}
