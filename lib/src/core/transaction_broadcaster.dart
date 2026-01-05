import 'package:dio/dio.dart';

/// Abstract interface for broadcasting Bitcoin transactions
abstract class TransactionBroadcaster {
  /// Broadcast a raw transaction hex to the network
  /// Returns the transaction ID (hash) if successful
  Future<String> broadcast(String rawTxHex);
}

/// Default implementation using Mempool.space API (compatible with Esplora)
class MempoolTransactionBroadcaster implements TransactionBroadcaster {
  final Dio _dio;
  final String _baseUrl;

  MempoolTransactionBroadcaster({
    Dio? dio,
    String baseUrl = 'https://mempool.space/api',
  })  : _dio = dio ?? Dio(),
        _baseUrl = baseUrl;

  @override
  Future<String> broadcast(String rawTxHex) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/tx',
        data: rawTxHex,
        options: Options(
          contentType: 'text/plain',
        ),
      );
      return response.data.toString();
    } catch (e) {
      throw Exception('Failed to broadcast transaction: $e');
    }
  }
}
