import 'package:decimal/decimal.dart';
import '../core/models/inscription.dart';
import '../utils/result.dart';

/// Abstract marketplace adapter interface
///
/// Implement this interface to add support for different Ordinals marketplaces
/// (e.g., Magic Eden, OKX, UniSat, etc.)
///
/// ## Example
///
/// ```dart
/// class MagicEdenAdapter implements MarketplaceAdapter {
///   @override
///   String get name => 'Magic Eden';
///
///   // Implement other methods...
/// }
/// ```
abstract class MarketplaceAdapter {
  /// Marketplace name
  String get name;

  /// Marketplace identifier
  String get id;

  /// Base URL for the marketplace
  String get baseUrl;

  /// Get listing information for an inscription
  Future<Result<ListingInfo>> getListing(String inscriptionId);

  /// Get all active listings
  Future<Result<List<ListingInfo>>> getListings({
    int limit = 20,
    int offset = 0,
    String? collection,
    SortOrder? sortBy,
  });

  /// List an inscription for sale
  Future<Result<String>> createListing({
    required String inscriptionId,
    required Decimal price,
    required String sellerAddress,
    required String privateKeyWif,
  });

  /// Cancel a listing
  Future<Result<bool>> cancelListing({
    required String listingId,
    required String sellerAddress,
    required String privateKeyWif,
  });

  /// Buy a listed inscription
  Future<Result<String>> buyListing({
    required String listingId,
    required String buyerAddress,
    required String privateKeyWif,
  });

  /// Get collection information
  Future<Result<CollectionInfo>> getCollection(String collectionId);

  /// Get market statistics
  Future<Result<MarketStats>> getMarketStats({String? collection});
}

/// Listing information
class ListingInfo {
  /// Unique listing ID
  final String listingId;

  /// Inscription ID
  final String inscriptionId;

  /// Inscription details
  final Inscription? inscription;

  /// Seller address
  final String sellerAddress;

  /// Listing price in BTC
  final Decimal price;

  /// Listing price in satoshis
  int get priceInSats =>
      (price * Decimal.fromInt(100000000)).toBigInt().toInt();

  /// Marketplace ID
  final String marketplace;

  /// Listing status
  final ListingStatus status;

  /// Created timestamp
  final DateTime? createdAt;

  /// Expiration timestamp
  final DateTime? expiresAt;

  ListingInfo({
    required this.listingId,
    required this.inscriptionId,
    this.inscription,
    required this.sellerAddress,
    required this.price,
    required this.marketplace,
    this.status = ListingStatus.active,
    this.createdAt,
    this.expiresAt,
  });

  /// Create from JSON
  factory ListingInfo.fromJson(Map<String, dynamic> json) {
    return ListingInfo(
      listingId: json['listing_id'] as String? ?? json['id'] as String,
      inscriptionId:
          json['inscription_id'] as String? ?? json['inscriptionId'] as String,
      sellerAddress:
          json['seller_address'] as String? ?? json['seller'] as String,
      price: Decimal.parse(json['price']?.toString() ?? '0'),
      marketplace: json['marketplace'] as String? ?? 'unknown',
      status: _parseStatus(json['status'] as String?),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
    );
  }

  static ListingStatus _parseStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
        return ListingStatus.active;
      case 'sold':
        return ListingStatus.sold;
      case 'cancelled':
        return ListingStatus.cancelled;
      case 'expired':
        return ListingStatus.expired;
      default:
        return ListingStatus.active;
    }
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
        'listingId': listingId,
        'inscriptionId': inscriptionId,
        'sellerAddress': sellerAddress,
        'price': price.toString(),
        'marketplace': marketplace,
        'status': status.name,
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
        if (expiresAt != null) 'expiresAt': expiresAt!.toIso8601String(),
      };
}

/// Listing status
enum ListingStatus { active, sold, cancelled, expired }

/// Sort order for listings
enum SortOrder { priceAsc, priceDesc, recentlyListed, recentlySold }

/// Collection information
class CollectionInfo {
  /// Collection ID
  final String id;

  /// Collection name
  final String name;

  /// Collection description
  final String? description;

  /// Collection image URL
  final String? imageUrl;

  /// Floor price in BTC
  final Decimal? floorPrice;

  /// Total volume in BTC
  final Decimal? totalVolume;

  /// Number of items
  final int? totalItems;

  /// Number of holders
  final int? holderCount;

  /// Number of listed items
  final int? listedCount;

  CollectionInfo({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    this.floorPrice,
    this.totalVolume,
    this.totalItems,
    this.holderCount,
    this.listedCount,
  });

  /// Create from JSON
  factory CollectionInfo.fromJson(Map<String, dynamic> json) {
    return CollectionInfo(
      id: json['id'] as String? ?? json['slug'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String? ?? json['image'] as String?,
      floorPrice: json['floor_price'] != null
          ? Decimal.parse(json['floor_price'].toString())
          : null,
      totalVolume: json['total_volume'] != null
          ? Decimal.parse(json['total_volume'].toString())
          : null,
      totalItems: json['total_items'] as int? ?? json['supply'] as int?,
      holderCount: json['holder_count'] as int? ?? json['holders'] as int?,
      listedCount: json['listed_count'] as int?,
    );
  }
}

/// Market statistics
class MarketStats {
  /// Total volume (24h) in BTC
  final Decimal volume24h;

  /// Total volume (7d) in BTC
  final Decimal volume7d;

  /// Total volume (all time) in BTC
  final Decimal volumeTotal;

  /// Number of sales (24h)
  final int sales24h;

  /// Number of sales (7d)
  final int sales7d;

  /// Number of active listings
  final int activeListings;

  /// Average sale price
  final Decimal? avgPrice;

  /// Floor price
  final Decimal? floorPrice;

  MarketStats({
    required this.volume24h,
    required this.volume7d,
    required this.volumeTotal,
    required this.sales24h,
    required this.sales7d,
    required this.activeListings,
    this.avgPrice,
    this.floorPrice,
  });

  /// Create from JSON
  factory MarketStats.fromJson(Map<String, dynamic> json) {
    return MarketStats(
      volume24h: Decimal.parse(json['volume_24h']?.toString() ?? '0'),
      volume7d: Decimal.parse(json['volume_7d']?.toString() ?? '0'),
      volumeTotal: Decimal.parse(json['volume_total']?.toString() ?? '0'),
      sales24h: json['sales_24h'] as int? ?? 0,
      sales7d: json['sales_7d'] as int? ?? 0,
      activeListings: json['active_listings'] as int? ?? 0,
      avgPrice: json['avg_price'] != null
          ? Decimal.parse(json['avg_price'].toString())
          : null,
      floorPrice: json['floor_price'] != null
          ? Decimal.parse(json['floor_price'].toString())
          : null,
    );
  }
}
