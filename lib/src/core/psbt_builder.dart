import 'dart:typed_data';
import 'package:web3_universal_bitcoin/web3_universal_bitcoin.dart';
// Ensure we don't hide explicit imports needed for wrapper if necessary, but PsbtBuilder is in namespace

/// PSBT (Partially Signed Bitcoin Transaction) builder for Ordinals inscriptions
/// Wrapper around [OrdinalPsbtBuilder] from `web3_universal_bitcoin`.
class PSBTBuilder {
  /// Dust limit in satoshis
  static const int dustAmount = OrdinalPsbtBuilder.dustAmount;

  /// Default sequence number (RBF enabled)
  static const int defaultSequence = OrdinalPsbtBuilder.defaultSequence;

  /// Build a Commit transaction for inscription
  static String buildCommitTransaction({
    required List<OrdinalUtxo> utxos,
    required Uint8List inscriptionScript,
    required String changeAddress,
    required String privateKeyWif,
    required int feeRate,
    BitcoinNetwork? network,
    int? amount,
  }) {
    return OrdinalPsbtBuilder.buildCommitTransaction(
      utxos: utxos,
      inscriptionScript: inscriptionScript,
      changeAddress: changeAddress,
      privateKeyWif: privateKeyWif,
      feeRate: feeRate,
      network: network,
      amount: amount,
    );
  }

  /// Build a Reveal transaction for inscription
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
    return OrdinalPsbtBuilder.buildRevealTransaction(
      commitTxId: commitTxId,
      commitVout: commitVout,
      inscriptionScript: inscriptionScript,
      receiverAddress: receiverAddress,
      privateKeyWif: privateKeyWif,
      feeRate: feeRate,
      network: network,
      inputAmount: inputAmount,
    );
  }

  /// Create inscription script for text content
  static Uint8List createTextInscriptionScript(String text) {
    return OrdinalPsbtBuilder.createTextInscriptionScript(text);
  }

  /// Create inscription script for image content
  static Uint8List createImageInscriptionScript(
    Uint8List imageData,
    String mimeType,
  ) {
    return OrdinalPsbtBuilder.createImageInscriptionScript(imageData, mimeType);
  }

  /// Create inscription script for JSON content (e.g., BRC-20)
  static Uint8List createJsonInscriptionScript(Map<String, dynamic> json) {
    return OrdinalPsbtBuilder.createJsonInscriptionScript(json);
  }
}
