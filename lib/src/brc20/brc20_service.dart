import 'package:dio/dio.dart';
import 'package:decimal/decimal.dart';
import 'package:web3_universal_bitcoin/web3_universal_bitcoin.dart' as web3;
import 'package:web3_universal_bitcoin/web3_universal_bitcoin.dart'
    as bb; // Keep bb for bitcoin_base types if needed

import '../utils/result.dart';
import '../core/models/utxo.dart';
import '../core/transaction_broadcaster.dart';
import 'brc20_models.dart';

/// BRC-20 token service for interacting with the BRC-20 protocol
class BRC20Service {
  final Dio _dio;
  final String? _apiKey;
  final TransactionBroadcaster _broadcaster;

  /// Base URL for the Ordinals API
  String baseUrl;

  /// Network (mainnet or testnet)
  final bool isTestnet;

  BRC20Service({
    String? apiKey,
    String? baseUrl,
    this.isTestnet = false,
    Dio? dio,
    TransactionBroadcaster? broadcaster,
  })  : _apiKey = apiKey,
        baseUrl = baseUrl ??
            (isTestnet
                ? 'https://api.hiro.so/ordinals/v1'
                : 'https://api.hiro.so/ordinals/v1'),
        _dio = dio ?? Dio(),
        _broadcaster = broadcaster ??
            MempoolTransactionBroadcaster(
              baseUrl: isTestnet
                  ? 'https://mempool.space/testnet/api'
                  : 'https://mempool.space/api',
            ) {
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
  Future<Result<String>> deployToken({
    required BRC20DeployParams params,
    required String privateKeyWif,
    required String address,
    required List<UTXO> utxos,
    required int feeRate,
    String? receiverAddress,
  }) async {
    try {
      final existingToken = await getToken(params.tick);
      if (existingToken.isSuccess) {
        return Result.failure('Token ${params.tick} already exists');
      }

      return _broadcastAndReveal(
        inscriptionJson: params.toInscriptionJson(),
        privateKeyWif: privateKeyWif,
        address: address,
        utxos: utxos,
        feeRate: feeRate,
        receiverAddress: receiverAddress ?? address,
      );
    } catch (e) {
      return Result.failure('Failed to deploy token: $e');
    }
  }

  /// Mint BRC-20 tokens
  Future<Result<String>> mintToken({
    required BRC20MintParams params,
    required String privateKeyWif,
    required String address,
    required List<UTXO> utxos,
    required int feeRate,
    String? receiverAddress,
  }) async {
    try {
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

      return _broadcastAndReveal(
        inscriptionJson: params.toInscriptionJson(),
        privateKeyWif: privateKeyWif,
        address: address,
        utxos: utxos,
        feeRate: feeRate,
        receiverAddress: receiverAddress ?? address,
      );
    } catch (e) {
      return Result.failure('Failed to mint token: $e');
    }
  }

  /// Create a BRC-20 transfer inscription
  Future<Result<String>> createTransferInscription({
    required BRC20TransferParams params,
    required String privateKeyWif,
    required String address,
    required List<UTXO> utxos,
    required int feeRate,
  }) async {
    try {
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

      return _broadcastAndReveal(
        inscriptionJson: params.toInscriptionJson(),
        privateKeyWif: privateKeyWif,
        address: address,
        utxos: utxos,
        feeRate: feeRate,
        receiverAddress: address,
      );
    } catch (e) {
      return Result.failure('Failed to create transfer inscription: $e');
    }
  }

  /// Helper to handle the Commit-Reveal flow
  Future<Result<String>> _broadcastAndReveal({
    required Map<String, dynamic> inscriptionJson,
    required String privateKeyWif,
    required String address,
    required List<UTXO> utxos,
    required int feeRate,
    required String receiverAddress,
  }) async {
    try {
      final network =
          isTestnet ? bb.BitcoinNetwork.testnet : bb.BitcoinNetwork.mainnet;

      // 1. Create inscription script
      final inscriptionScript =
          web3.OrdinalPsbtBuilder.createJsonInscriptionScript(
        inscriptionJson,
      );

      // Estimate reveal transaction fee to determine commit amount
      // Estimate size: ~ 100 + scriptSize + 43 + scriptSize/4
      // We can use web3.PsbtBuilder._estimateRevealSize but it's private.
      // But we can approximate or expose it?
      // Better to compute it here or add a public estimator to PsbtBuilder.
      // For now, let's implement the estimation here, mirroring PsbtBuilder.

      final scriptSize = inscriptionScript.length;
      final revealSize = 100 + scriptSize + 43 + (scriptSize / 4).ceil();
      final revealFee = revealSize * feeRate;
      final dustAmount = 546;

      // Amount needed in commit output = reveal fee + dust (for reveal output)
      final commitAmount = revealFee + dustAmount;

      // 2. Parse UTXOs
      // UTXO already extends web3.OrdinalUtxo, so we can pass it directly
      // But we need to ensure the list is cast correctly if needed, or OrdinalPsbtBuilder accepts generic List<OrdinalUtxo>

      // 3. Build commit transaction
      final commitTxHex = web3.OrdinalPsbtBuilder.buildCommitTransaction(
        utxos: utxos,
        inscriptionScript: inscriptionScript,
        changeAddress: address,
        privateKeyWif: privateKeyWif,
        feeRate: feeRate,
        network: network,
        amount: commitAmount,
      );

      // 4. Broadcast commit transaction
      final commitTxId = await _broadcaster.broadcast(commitTxHex);

      // 5. Build reveal transaction
      final revealTxHex = web3.OrdinalPsbtBuilder.buildRevealTransaction(
        commitTxId: commitTxId,
        commitVout: 0,
        inscriptionScript: inscriptionScript,
        receiverAddress: receiverAddress,
        privateKeyWif: privateKeyWif,
        feeRate: feeRate,
        network: network,
        inputAmount: commitAmount,
      );

      // 6. Broadcast reveal transaction
      final revealTxId = await _broadcaster.broadcast(revealTxHex);

      return Result.success(revealTxId);
    } catch (e) {
      return Result.failure('Broadcast failed: $e');
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
}
