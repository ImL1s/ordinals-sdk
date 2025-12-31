# Ordinals SDK

[![pub package](https://img.shields.io/pub/v/ordinals_sdk.svg)](https://pub.dev/packages/ordinals_sdk)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A comprehensive Dart SDK for Bitcoin Ordinals, BRC-20 tokens, and inscription management.

## Features

- 🔨 **PSBT Builder**: Build Commit/Reveal transactions for inscriptions
- 💰 **BRC-20 Support**: Deploy, mint, and transfer BRC-20 tokens
- 🖼️ **Inscription Management**: Create text, image, and JSON inscriptions
- 🏪 **Marketplace Integration**: Abstract adapter for multiple marketplaces
- 🔐 **Pure Dart**: No Flutter dependency, works everywhere

## Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  ordinals_sdk: ^1.0.0
```

## Quick Start

### BRC-20 Tokens

```dart
import 'package:ordinals_sdk/ordinals_sdk.dart';

// Initialize the service
final brc20 = BRC20Service(apiKey: 'your-hiro-api-key');

// Get token information
final tokenResult = await brc20.getToken('ordi');
tokenResult.when(
  success: (token) {
    print('Token: ${token.tick}');
    print('Supply: ${token.mintedSupply}/${token.maxSupply}');
    print('Minted: ${token.mintedPercentage.toStringAsFixed(2)}%');
  },
  failure: (error) => print('Error: $error'),
);

// Get balance
final balance = await brc20.getBalance('bc1q...', 'ordi');
print('Available: ${balance.value.availableBalance}');

// Mint tokens
final mintResult = await brc20.mintToken(
  params: BRC20MintParams(tick: 'ordi', amount: Decimal.parse('1000')),
  privateKeyWif: 'L...',
  address: 'bc1q...',
  utxos: availableUtxos,
  feeRate: 10,
);
```

### Creating Inscriptions

```dart
import 'package:ordinals_sdk/ordinals_sdk.dart';

// Create a text inscription script
final textScript = PSBTBuilder.createTextInscriptionScript(
  'Hello, Ordinals!',
);

// Create an image inscription script
final imageScript = PSBTBuilder.createImageInscriptionScript(
  imageBytes,
  'image/png',
);

// Build the commit transaction
final commitTx = PSBTBuilder.buildCommitTransaction(
  utxos: utxos,
  inscriptionScript: textScript,
  changeAddress: 'bc1q...',
  privateKeyWif: 'L...',
  feeRate: 10,
);

// Build the reveal transaction
final revealTx = PSBTBuilder.buildRevealTransaction(
  commitTxId: commitTxId,
  commitVout: 0,
  inscriptionScript: textScript,
  receiverAddress: 'bc1q...',
  privateKeyWif: 'L...',
  feeRate: 10,
);
```

### Marketplace Integration

```dart
import 'package:ordinals_sdk/ordinals_sdk.dart';

// Implement a custom marketplace adapter
class MyMarketplace implements MarketplaceAdapter {
  @override
  String get name => 'My Marketplace';

  @override
  String get id => 'my-marketplace';

  @override
  String get baseUrl => 'https://api.my-marketplace.com';

  // Implement other methods...
}

// Use the adapter
final marketplace = MyMarketplace();
final listing = await marketplace.getListing('inscription-id');
```

## API Reference

### BRC20Service

| Method | Description |
|--------|-------------|
| `getToken(tick)` | Get token information |
| `getTokens(limit, offset)` | List all tokens |
| `getBalance(address, tick)` | Get balance for address |
| `getAllBalances(address)` | Get all balances |
| `deployToken(params)` | Deploy new token |
| `mintToken(params)` | Mint existing token |
| `createTransferInscription(params)` | Create transfer inscription |

### PSBTBuilder

| Method | Description |
|--------|-------------|
| `buildCommitTransaction(...)` | Build commit tx for inscription |
| `buildRevealTransaction(...)` | Build reveal tx for inscription |
| `createTextInscriptionScript(text)` | Create text inscription |
| `createImageInscriptionScript(data, mime)` | Create image inscription |
| `createJsonInscriptionScript(json)` | Create JSON inscription |

## Supported APIs

- [Hiro Ordinals API](https://docs.hiro.so/ordinals-api)
- [UniSat API](https://docs.unisat.io/dev/unisat-developer-service/ordinals)

## License

MIT License - see [LICENSE](LICENSE) for details.

## Contributing

Contributions are welcome! Please read our [Contributing Guide](CONTRIBUTING.md) for details.
