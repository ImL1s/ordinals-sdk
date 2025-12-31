# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-01-01

### Added
- Initial release of the Ordinals SDK.
- **Core Features**:
  - PSBT (Partially Signed Bitcoin Transaction) builder for Commit/Reveal inscriptions
  - Taproot address generation and script handling
  - UTXO management utilities
- **BRC-20 Support**:
  - Deploy new BRC-20 tokens
  - Mint existing tokens
  - Create transfer inscriptions
  - Query token balances and activity
- **Inscription Management**:
  - Create text and image inscriptions
  - Query inscriptions by address
  - Search and filter inscriptions
- **Marketplace Integration**:
  - Abstract marketplace adapter interface
  - Buy/sell/list inscriptions
  - Market data retrieval
