import 'package:test/test.dart';
import 'package:decimal/decimal.dart';
import 'package:ordinals_sdk/ordinals_sdk.dart';

void main() {
  group('ListingInfo', () {
    test('should create from JSON', () {
      final json = {
        'listing_id': 'lst123',
        'inscription_id': 'insc456i0',
        'seller_address': 'bc1p...',
        'price': '0.001',
        'marketplace': 'magic_eden',
        'status': 'active',
      };

      final listing = ListingInfo.fromJson(json);
      expect(listing.listingId, equals('lst123'));
      expect(listing.inscriptionId, equals('insc456i0'));
      expect(listing.sellerAddress, equals('bc1p...'));
      expect(listing.price, equals(Decimal.parse('0.001')));
      expect(listing.marketplace, equals('magic_eden'));
      expect(listing.status, equals(ListingStatus.active));
    });

    test('should calculate price in sats', () {
      final listing = ListingInfo(
        listingId: 'lst1',
        inscriptionId: 'insc1',
        sellerAddress: 'bc1...',
        price: Decimal.parse('0.001'), // 0.001 BTC
        marketplace: 'test',
      );

      expect(listing.priceInSats, equals(100000)); // 0.001 * 100_000_000
    });

    test('should parse different statuses', () {
      final soldJson = {
        'id': 'lst1',
        'inscription_id': 'insc1',
        'seller': 'bc1...',
        'price': '0.01',
        'status': 'sold',
      };
      expect(ListingInfo.fromJson(soldJson).status, equals(ListingStatus.sold));

      final cancelledJson = {
        'id': 'lst2',
        'inscription_id': 'insc2',
        'seller': 'bc1...',
        'price': '0.02',
        'status': 'cancelled',
      };
      expect(ListingInfo.fromJson(cancelledJson).status,
          equals(ListingStatus.cancelled));
    });
  });

  group('CollectionInfo', () {
    test('should create from JSON', () {
      final json = {
        'id': 'bitcoin-puppets',
        'name': 'Bitcoin Puppets',
        'description': 'A collection of 10k puppets',
        'image_url': 'https://example.com/image.png',
        'floor_price': '0.5',
        'total_volume': '1000',
        'total_items': 10000,
        'holder_count': 5000,
      };

      final collection = CollectionInfo.fromJson(json);
      expect(collection.id, equals('bitcoin-puppets'));
      expect(collection.name, equals('Bitcoin Puppets'));
      expect(collection.floorPrice, equals(Decimal.parse('0.5')));
      expect(collection.totalItems, equals(10000));
      expect(collection.holderCount, equals(5000));
    });
  });

  group('MarketStats', () {
    test('should create from JSON', () {
      final json = {
        'volume_24h': '100.5',
        'volume_7d': '500.25',
        'volume_total': '10000',
        'sales_24h': 150,
        'sales_7d': 750,
        'active_listings': 5000,
        'floor_price': '0.1',
      };

      final stats = MarketStats.fromJson(json);
      expect(stats.volume24h, equals(Decimal.parse('100.5')));
      expect(stats.volume7d, equals(Decimal.parse('500.25')));
      expect(stats.sales24h, equals(150));
      expect(stats.activeListings, equals(5000));
      expect(stats.floorPrice, equals(Decimal.parse('0.1')));
    });
  });
}
