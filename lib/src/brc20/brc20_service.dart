import 'package:dio/dio.dart';
import 'package:decimal/decimal.dart';

import '../utils/result.dart';
import '../core/psbt_builder.dart';
import '../core/models/utxo.dart';
import 'brc20_models.dart';

/// BRC-20 token service for interacting with the BRC-20 protocol
///
/// This service provides methods for:
/// - Deploying new BRC-20 tokens
/// - Minting existing tokens
/// - Creating transfer inscriptions
/// - Querying token information and balances
///
/// ## Example
///
/// ```dart
/// final brc20 = BRC20Service(apiKey: 'your-api-key');
///
/// // Get token info
/// final token = await brc20.getToken('ordi');
/// print('Minted: ${token.mintedSupply}/${token.maxSupply}');
///
/// // Get balance
/// final balance = await brc20.getBalance('bc1q...', 'ordi');
/// print('Available: ${balance.availableBalance}');
/// ```
class BRC20Service {
  final Dio _dio;
  final String? _apiKey;

  /// Base URL for the Ordinals API
  String baseUrl;

  /// Network (mainnet or testnet)
  final bool isTestnet;

  BRC20Service({
    String? apiKey,
    String? baseUrl,
    this.isTestnet = false,
    Dio? dio,
  })  : _apiKey = apiKey,
        baseUrl = baseUrl ??
            (isTestnet
                ? 'https://api.hiro.so/ordinals/v1'
                : 'https://api.hiro.so/ordinals/v1'),
        _dio = dio ?? Dio() {
    _setupDio();
  }

  void _setupDio() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.headers = {
      'Content-Type': 'application/json',
      if (_apiKey != null) 'x-api-key': _apiKey,
    };
  }

  /// Deploy a new BRC-20 token
  ///
  /// Creates and broadcasts the inscription transaction for a new token.
  ///
  /// - [params]: Deploy parameters (tick, maxSupply, limitPerMint)
  /// - [privateKeyWif]: Private key in WIF format
  /// - [address]: Sender address
  /// - [utxos]: Available UTXOs for funding
  /// - [feeRate]: Fee rate in sat/vB
  /// - [receiverAddress]: Optional receiver address for the inscription
  Future<Result<String>> deployToken({
    required BRC20DeployParams params,
    required String privateKeyWif,
    required String address,
    required List<Map<String, dynamic>> utxos,
    required int feeRate,
    String? receiverAddress,
  }) async {
    try {
      // Check if token already exists
      final existingToken = await getToken(params.tick);
      if (existingToken.isSuccess) {
        return Result.failure('Token ${params.tick} already exists');
      }

      // Create inscription script
      final inscriptionScript = PSBTBuilder.createJsonInscriptionScript(
        params.toInscriptionJson(),
      );

      // Build commit transaction
      final parsedUtxos = utxos.map((u) => _parseUtxo(u)).toList();

      final commitTx = PSBTBuilder.buildCommitTransaction(
        utxos: parsedUtxos,
        inscriptionScript: inscriptionScript,
        changeAddress: address,
        privateKeyWif: privateKeyWif,
        feeRate: feeRate,
      );

      // TODO: Broadcast commit transaction and build reveal
      // For now, return the commit transaction hex
      return Result.success(commitTx);
    } catch (e) {
      return Result.failure('Failed to deploy token: $e');
    }
  }

  /// Mint BRC-20 tokens
  ///
  /// Creates a mint inscription for an existing token.
  Future<Result<String>> mintToken({
    required BRC20MintParams params,
    required String privateKeyWif,
    required String address,
    required List<Map<String, dynamic>> utxos,
    required int feeRate,
    String? receiverAddress,
  }) async {
    try {
      // Verify token exists and has remaining supply
      final tokenResult = await getToken(params.tick);
      if (tokenResult.isFailure) {
        return Result.failure('Token ${params.tick} not found');
      }

      final token = tokenResult.value;
      if (token.isFullyMinted) {
        return Result.failure('Token ${params.tick} is fully minted');
      }

      if (params.amount > token.limitPerMint) {
        return Result.failure(
          'Amount exceeds mint limit (${token.limitPerMint})',
        );
      }

      // Create inscription script
      final inscriptionScript = PSBTBuilder.createJsonInscriptionScript(
        params.toInscriptionJson(),
      );

      // Build commit transaction
      final parsedUtxos = utxos.map((u) => _parseUtxo(u)).toList();

      final commitTx = PSBTBuilder.buildCommitTransaction(
        utxos: parsedUtxos,
        inscriptionScript: inscriptionScript,
        changeAddress: address,
        privateKeyWif: privateKeyWif,
        feeRate: feeRate,
      );

      return Result.success(commitTx);
    } catch (e) {
      return Result.failure('Failed to mint token: $e');
    }
  }

  /// Create a BRC-20 transfer inscription
  ///
  /// This is the first step of a BRC-20 transfer. After creating the transfer
  /// inscription, you need to send it to the recipient.
  Future<Result<String>> createTransferInscription({
    required BRC20TransferParams params,
    required String privateKeyWif,
    required String address,
    required List<Map<String, dynamic>> utxos,
    required int feeRate,
  }) async {
    try {
      // Verify balance
      final balanceResult = await getBalance(address, params.tick);
      if (balanceResult.isFailure) {
        return Result.failure('Failed to check balance');
      }

      final balance = balanceResult.value;
      if (balance.availableBalance < params.amount) {
        return Result.failure(
          'Insufficient balance. Available: ${balance.availableBalance}',
        );
      }

      // Create inscription script
      final inscriptionScript = PSBTBuilder.createJsonInscriptionScript(
        params.toInscriptionJson(),
      );

      // Build commit transaction
      final parsedUtxos = utxos.map((u) => _parseUtxo(u)).toList();

      final commitTx = PSBTBuilder.buildCommitTransaction(
        utxos: parsedUtxos,
        inscriptionScript: inscriptionScript,
        changeAddress: address,
        privateKeyWif: privateKeyWif,
        feeRate: feeRate,
      );

      return Result.success(commitTx);
    } catch (e) {
      return Result.failure('Failed to create transfer inscription: $e');
    }
  }

  /// Get BRC-20 token information
  Future<Result<BRC20Token>> getToken(String tick) async {
    try {
      final response = await _dio.get('/brc-20/tokens/$tick');

      if (response.statusCode == 200 && response.data != null) {
        final token = BRC20Token.fromHiroJson(
          response.data['token'] ?? response.data,
        );
        return Result.success(token);
      }

      return Result.failure('Token not found');
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return Result.failure('Token not found', code: 'NOT_FOUND');
      }
      return Result.failure('API error: ${e.message}');
    } catch (e) {
      return Result.failure('Failed to get token: $e');
    }
  }

  /// Get list of BRC-20 tokens
  Future<Result<List<BRC20Token>>> getTokens({
    int limit = 20,
    int offset = 0,
    String? search,
  }) async {
    try {
      final params = {
        'limit': limit,
        'offset': offset,
        if (search != null) 'ticker': search,
      };

      final response = await _dio.get(
        '/brc-20/tokens',
        queryParameters: params,
      );

      if (response.statusCode == 200 && response.data != null) {
        final results = response.data['results'] as List? ?? [];
        final tokens =
            results.map((json) => BRC20Token.fromHiroJson(json)).toList();
        return Result.success(tokens);
      }

      return Result.success([]);
    } catch (e) {
      return Result.failure('Failed to get tokens: $e');
    }
  }

  /// Get BRC-20 balance for an address
  Future<Result<BRC20Balance>> getBalance(String address, String tick) async {
    try {
      final response = await _dio.get(
        '/brc-20/balances/$address',
        queryParameters: {'ticker': tick},
      );

      if (response.statusCode == 200 && response.data != null) {
        final results = response.data['results'] as List? ?? [];
        if (results.isNotEmpty) {
          return Result.success(BRC20Balance.fromJson(results.first));
        }

        // Return zero balance if not found
        return Result.success(
          BRC20Balance(
            tick: tick,
            availableBalance: Decimal.zero,
            transferableBalance: Decimal.zero,
            overallBalance: Decimal.zero,
          ),
        );
      }

      return Result.failure('Failed to get balance');
    } catch (e) {
      return Result.failure('Failed to get balance: $e');
    }
  }

  /// Get all BRC-20 balances for an address
  Future<Result<List<BRC20Balance>>> getAllBalances(String address) async {
    try {
      final response = await _dio.get('/brc-20/balances/$address');

      if (response.statusCode == 200 && response.data != null) {
        final results = response.data['results'] as List? ?? [];
        final balances =
            results.map((json) => BRC20Balance.fromJson(json)).toList();
        return Result.success(balances);
      }

      return Result.success([]);
    } catch (e) {
      return Result.failure('Failed to get balances: $e');
    }
  }

  /// Get BRC-20 activity history
  Future<Result<List<BRC20Activity>>> getActivity({
    String? address,
    String? tick,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final params = {
        'limit': limit,
        'offset': offset,
        if (tick != null) 'ticker': tick,
      };

      final path =
          address != null ? '/brc-20/activity/$address' : '/brc-20/activity';

      final response = await _dio.get(path, queryParameters: params);

      if (response.statusCode == 200 && response.data != null) {
        final results = response.data['results'] as List? ?? [];
        final activities =
            results.map((json) => BRC20Activity.fromJson(json)).toList();
        return Result.success(activities);
      }

      return Result.success([]);
    } catch (e) {
      return Result.failure('Failed to get activity: $e');
    }
  }

  // Private helpers

  UTXO _parseUtxo(Map<String, dynamic> json) {
    return UTXO(
      txid: json['txid'] as String,
      vout: json['vout'] as int,
      value: json['value'] as int,
      address: json['address'] as String?,
    );
  }
}
