import 'package:web3_universal_bitcoin/web3_universal_bitcoin.dart';

/// UTXO (Unspent Transaction Output) model
class UTXO extends OrdinalUtxo {
  /// Transaction status
  final Map<String, dynamic>? status;

  UTXO({
    required super.txid,
    required super.vout,
    required super.value,
    super.isSegwit = false,
    super.address,
    this.status,
    super.scriptPubKey,
  });

  /// Create from JSON
  factory UTXO.fromJson(Map<String, dynamic> json) {
    return UTXO(
      txid: json['txid'] as String,
      vout: json['vout'] as int,
      value: json['value'] as int,
      isSegwit: json['isSegwit'] as bool? ?? false,
      address: json['address'] as String?,
      status: json['status'] as Map<String, dynamic>?,
      scriptPubKey: json['scriptPubKey'] as String?,
    );
  }

  /// Convert to JSON
  @override
  Map<String, dynamic> toJson() => {
        ...super.toJson(),
        if (status != null) 'status': status,
      };

  /// Whether this UTXO is confirmed
  bool get isConfirmed => status?['confirmed'] == true;

  @override
  String toString() => 'UTXO($outpoint, $value sats)';
}
