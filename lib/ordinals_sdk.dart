/// Ordinals SDK - A comprehensive Dart SDK for Bitcoin Ordinals and BRC-20
///
/// This library provides tools for:
/// - Creating Bitcoin Ordinals inscriptions using Taproot
/// - Building PSBT (Partially Signed Bitcoin Transactions)
/// - Managing BRC-20 tokens (deploy, mint, transfer)
/// - Integrating with Ordinals marketplaces
///
/// ## Getting Started
///
/// ```dart
/// import 'package:ordinals_sdk/ordinals_sdk.dart';
///
/// // Create a BRC-20 token service
/// final brc20 = BRC20Service(apiKey: 'your-api-key');
///
/// // Get token info
/// final token = await brc20.getToken('ordi');
/// print('Token: ${token.tick}, Supply: ${token.totalSupply}');
/// ```
library ordinals_sdk;

// Core exports
export 'src/core/models/inscription.dart';
export 'src/core/models/utxo.dart';
export 'src/core/psbt_builder.dart';
export 'src/core/transaction_broadcaster.dart';

// BRC-20 exports
export 'src/brc20/brc20_service.dart';
export 'src/brc20/brc20_models.dart';

// Marketplace exports
export 'src/marketplace/marketplace_adapter.dart';

// Utils
export 'src/utils/result.dart';
