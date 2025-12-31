/// UTXO (Unspent Transaction Output) model
class UTXO {
  /// Transaction ID
  final String txid;

  /// Output index
  final int vout;

  /// Value in satoshis
  final int value;

  /// Whether this is a SegWit output
  final bool isSegwit;

  /// Address associated with this UTXO
  final String? address;

  /// Transaction status
  final Map<String, dynamic>? status;

  /// Script pubkey (optional)
  final String? scriptPubKey;

  UTXO({
    required this.txid,
    required this.vout,
    required this.value,
    this.isSegwit = false,
    this.address,
    this.status,
    this.scriptPubKey,
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
  Map<String, dynamic> toJson() => {
    'txid': txid,
    'vout': vout,
    'value': value,
    'isSegwit': isSegwit,
    if (address != null) 'address': address,
    if (status != null) 'status': status,
    if (scriptPubKey != null) 'scriptPubKey': scriptPubKey,
  };

  /// Get the outpoint string (txid:vout)
  String get outpoint => '$txid:$vout';

  /// Whether this UTXO is confirmed
  bool get isConfirmed => status?['confirmed'] == true;

  @override
  String toString() => 'UTXO($outpoint, $value sats)';
}
