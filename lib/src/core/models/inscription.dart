/// Ordinal inscription model
class Inscription {
  /// Unique inscription ID (txid:index format)
  final String id;

  /// Inscription number
  final int? number;

  /// Content type (MIME type)
  final String? contentType;

  /// Content length in bytes
  final int? contentLength;

  /// Genesis transaction ID
  final String? genesisTxId;

  /// Genesis block height
  final int? genesisHeight;

  /// Genesis timestamp
  final DateTime? genesisTimestamp;

  /// Current owner address
  final String? address;

  /// Current output (txid:vout)
  final String? output;

  /// Offset within the output
  final int? offset;

  /// Sat (ordinal) number
  final int? sat;

  /// Sat rarity
  final String? satRarity;

  /// Content URL
  final String? contentUrl;

  /// Preview URL
  final String? previewUrl;

  /// Metadata
  final Map<String, dynamic>? metadata;

  Inscription({
    required this.id,
    this.number,
    this.contentType,
    this.contentLength,
    this.genesisTxId,
    this.genesisHeight,
    this.genesisTimestamp,
    this.address,
    this.output,
    this.offset,
    this.sat,
    this.satRarity,
    this.contentUrl,
    this.previewUrl,
    this.metadata,
  });

  /// Create from JSON (Hiro API format)
  factory Inscription.fromHiroJson(Map<String, dynamic> json) {
    return Inscription(
      id: json['id'] as String,
      number: json['number'] as int?,
      contentType: json['content_type'] as String?,
      contentLength: json['content_length'] as int?,
      genesisTxId: json['genesis_tx_id'] as String?,
      genesisHeight: json['genesis_block_height'] as int?,
      genesisTimestamp: json['genesis_timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              json['genesis_timestamp'] as int,
            )
          : null,
      address: json['address'] as String?,
      output: json['output'] as String?,
      offset: json['offset'] as int?,
      sat: json['sat_ordinal'] as int?,
      satRarity: json['sat_rarity'] as String?,
      contentUrl: json['content_link'] as String?,
      previewUrl: json['preview_link'] as String?,
      metadata: json['meta'] as Map<String, dynamic>?,
    );
  }

  /// Create from JSON (UniSat API format)
  factory Inscription.fromUniSatJson(Map<String, dynamic> json) {
    return Inscription(
      id: json['inscriptionId'] as String,
      number: json['inscriptionNumber'] as int?,
      contentType: json['contentType'] as String?,
      contentLength: json['contentLength'] as int?,
      genesisTxId: json['genesisTransaction'] as String?,
      genesisHeight: json['genesisBlockHeight'] as int?,
      address: json['address'] as String?,
      output: json['output'] as String?,
      offset: json['outputValue'] as int?,
      contentUrl: json['contentUrl'] as String?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    if (number != null) 'number': number,
    if (contentType != null) 'contentType': contentType,
    if (contentLength != null) 'contentLength': contentLength,
    if (genesisTxId != null) 'genesisTxId': genesisTxId,
    if (genesisHeight != null) 'genesisHeight': genesisHeight,
    if (genesisTimestamp != null)
      'genesisTimestamp': genesisTimestamp!.millisecondsSinceEpoch,
    if (address != null) 'address': address,
    if (output != null) 'output': output,
    if (offset != null) 'offset': offset,
    if (sat != null) 'sat': sat,
    if (satRarity != null) 'satRarity': satRarity,
    if (contentUrl != null) 'contentUrl': contentUrl,
    if (previewUrl != null) 'previewUrl': previewUrl,
    if (metadata != null) 'metadata': metadata,
  };

  /// Whether this is a text inscription
  bool get isText =>
      contentType?.startsWith('text/') == true ||
      contentType == 'application/json';

  /// Whether this is an image inscription
  bool get isImage => contentType?.startsWith('image/') == true;

  /// Whether this is a BRC-20 inscription
  bool get isBRC20 =>
      contentType == 'text/plain' ||
      contentType == 'application/json' ||
      (metadata?['protocol'] == 'brc-20');

  @override
  String toString() => 'Inscription($id, #$number)';
}

/// Paginated list of inscriptions
class InscriptionList {
  final List<Inscription> items;
  final int total;
  final int offset;
  final int limit;

  InscriptionList({
    required this.items,
    required this.total,
    required this.offset,
    required this.limit,
  });

  bool get hasMore => offset + items.length < total;
  int get nextOffset => offset + limit;
}
