import 'package:decimal/decimal.dart';

/// BRC-20 operation types
enum BRC20Operation { deploy, mint, transfer, transferInscription }

/// BRC-20 token information
class BRC20Token {
  /// Token ticker (4 characters)
  final String tick;

  /// Maximum supply
  final Decimal maxSupply;

  /// Limit per mint
  final Decimal limitPerMint;

  /// Current minted supply
  final Decimal mintedSupply;

  /// Number of decimal places
  final int decimals;

  /// Deploy inscription ID
  final String? deployInscriptionId;

  /// Deploy block height
  final int? deployHeight;

  /// Deploy timestamp
  final DateTime? deployTimestamp;

  /// Number of holders
  final int? holderCount;

  /// Number of total transactions
  final int? transactionCount;

  BRC20Token({
    required this.tick,
    required this.maxSupply,
    required this.limitPerMint,
    required this.mintedSupply,
    this.decimals = 18,
    this.deployInscriptionId,
    this.deployHeight,
    this.deployTimestamp,
    this.holderCount,
    this.transactionCount,
  });

  /// Create from JSON (Hiro API format)
  factory BRC20Token.fromHiroJson(Map<String, dynamic> json) {
    return BRC20Token(
      tick: json['ticker'] as String,
      maxSupply: Decimal.parse(json['max_supply']?.toString() ?? '0'),
      limitPerMint: Decimal.parse(json['mint_limit']?.toString() ?? '0'),
      mintedSupply: Decimal.parse(json['minted_supply']?.toString() ?? '0'),
      decimals: json['decimals'] as int? ?? 18,
      deployInscriptionId: json['deploy_inscription_id'] as String?,
      deployHeight: json['deploy_block_height'] as int?,
      holderCount: json['holder_count'] as int?,
      transactionCount: json['tx_count'] as int?,
    );
  }

  /// Create from JSON (UniSat API format)
  factory BRC20Token.fromUniSatJson(Map<String, dynamic> json) {
    return BRC20Token(
      tick: json['tick'] as String,
      maxSupply: Decimal.parse(json['max']?.toString() ?? '0'),
      limitPerMint: Decimal.parse(json['lim']?.toString() ?? '0'),
      mintedSupply: Decimal.parse(json['totalMinted']?.toString() ?? '0'),
      decimals: json['decimal'] as int? ?? 18,
      deployInscriptionId: json['inscriptionId'] as String?,
      holderCount: json['holdersCount'] as int?,
      transactionCount: json['txCount'] as int?,
    );
  }

  /// Whether the token is fully minted
  bool get isFullyMinted => mintedSupply >= maxSupply;

  /// Remaining mintable supply
  Decimal get remainingSupply => maxSupply - mintedSupply;

  /// Minted percentage
  double get mintedPercentage => maxSupply > Decimal.zero
      ? (mintedSupply / maxSupply).toDouble() * 100
      : 0;

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
    'tick': tick,
    'maxSupply': maxSupply.toString(),
    'limitPerMint': limitPerMint.toString(),
    'mintedSupply': mintedSupply.toString(),
    'decimals': decimals,
    if (deployInscriptionId != null) 'deployInscriptionId': deployInscriptionId,
    if (deployHeight != null) 'deployHeight': deployHeight,
    if (holderCount != null) 'holderCount': holderCount,
    if (transactionCount != null) 'transactionCount': transactionCount,
  };

  @override
  String toString() => 'BRC20Token($tick, supply: $mintedSupply/$maxSupply)';
}

/// BRC-20 balance for an address
class BRC20Balance {
  /// Token ticker
  final String tick;

  /// Available balance (transferable)
  final Decimal availableBalance;

  /// Transferable balance (in transfer inscriptions)
  final Decimal transferableBalance;

  /// Overall balance
  final Decimal overallBalance;

  BRC20Balance({
    required this.tick,
    required this.availableBalance,
    required this.transferableBalance,
    required this.overallBalance,
  });

  /// Create from JSON
  factory BRC20Balance.fromJson(Map<String, dynamic> json) {
    return BRC20Balance(
      tick: json['tick'] as String? ?? json['ticker'] as String,
      availableBalance: Decimal.parse(
        json['available_balance']?.toString() ??
            json['availableBalance']?.toString() ??
            '0',
      ),
      transferableBalance: Decimal.parse(
        json['transferable_balance']?.toString() ??
            json['transferableBalance']?.toString() ??
            '0',
      ),
      overallBalance: Decimal.parse(
        json['overall_balance']?.toString() ??
            json['overallBalance']?.toString() ??
            '0',
      ),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
    'tick': tick,
    'availableBalance': availableBalance.toString(),
    'transferableBalance': transferableBalance.toString(),
    'overallBalance': overallBalance.toString(),
  };

  @override
  String toString() =>
      'BRC20Balance($tick, available: $availableBalance, transferable: $transferableBalance)';
}

/// BRC-20 activity record
class BRC20Activity {
  /// Transaction ID
  final String txId;

  /// Block height
  final int? blockHeight;

  /// Timestamp
  final DateTime? timestamp;

  /// Operation type
  final BRC20Operation operation;

  /// Token ticker
  final String tick;

  /// Amount
  final Decimal amount;

  /// From address
  final String? fromAddress;

  /// To address
  final String? toAddress;

  /// Inscription ID
  final String? inscriptionId;

  BRC20Activity({
    required this.txId,
    this.blockHeight,
    this.timestamp,
    required this.operation,
    required this.tick,
    required this.amount,
    this.fromAddress,
    this.toAddress,
    this.inscriptionId,
  });

  /// Create from JSON
  factory BRC20Activity.fromJson(Map<String, dynamic> json) {
    return BRC20Activity(
      txId: json['tx_id'] as String? ?? json['txId'] as String,
      blockHeight: json['block_height'] as int? ?? json['blockHeight'] as int?,
      timestamp: json['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int)
          : null,
      operation: _parseOperation(json['operation'] as String?),
      tick: json['tick'] as String? ?? json['ticker'] as String,
      amount: Decimal.parse(json['amount']?.toString() ?? '0'),
      fromAddress: json['from_address'] as String? ?? json['from'] as String?,
      toAddress: json['to_address'] as String? ?? json['to'] as String?,
      inscriptionId: json['inscription_id'] as String?,
    );
  }

  static BRC20Operation _parseOperation(String? op) {
    switch (op?.toLowerCase()) {
      case 'deploy':
        return BRC20Operation.deploy;
      case 'mint':
        return BRC20Operation.mint;
      case 'transfer':
        return BRC20Operation.transfer;
      case 'transfer_inscription':
      case 'transferinscription':
        return BRC20Operation.transferInscription;
      default:
        return BRC20Operation.transfer;
    }
  }

  @override
  String toString() => 'BRC20Activity($operation $amount $tick, tx: $txId)';
}

/// BRC-20 deploy parameters
class BRC20DeployParams {
  /// Token ticker (must be 4 characters)
  final String tick;

  /// Maximum supply
  final Decimal maxSupply;

  /// Limit per mint
  final Decimal limitPerMint;

  /// Number of decimal places
  final int decimals;

  BRC20DeployParams({
    required this.tick,
    required this.maxSupply,
    required this.limitPerMint,
    this.decimals = 18,
  }) {
    if (tick.length != 4) {
      throw ArgumentError('BRC-20 ticker must be exactly 4 characters');
    }
  }

  /// Convert to inscription JSON
  Map<String, dynamic> toInscriptionJson() => {
    'p': 'brc-20',
    'op': 'deploy',
    'tick': tick,
    'max': maxSupply.toString(),
    'lim': limitPerMint.toString(),
    if (decimals != 18) 'dec': decimals.toString(),
  };
}

/// BRC-20 mint parameters
class BRC20MintParams {
  /// Token ticker
  final String tick;

  /// Amount to mint
  final Decimal amount;

  BRC20MintParams({required this.tick, required this.amount});

  /// Convert to inscription JSON
  Map<String, dynamic> toInscriptionJson() => {
    'p': 'brc-20',
    'op': 'mint',
    'tick': tick,
    'amt': amount.toString(),
  };
}

/// BRC-20 transfer parameters
class BRC20TransferParams {
  /// Token ticker
  final String tick;

  /// Amount to transfer
  final Decimal amount;

  BRC20TransferParams({required this.tick, required this.amount});

  /// Convert to inscription JSON
  Map<String, dynamic> toInscriptionJson() => {
    'p': 'brc-20',
    'op': 'transfer',
    'tick': tick,
    'amt': amount.toString(),
  };
}
