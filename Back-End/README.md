# StakeIt Backend

A fully decentralized implementation for the StakeIt Web3 accountability platform on Hedera.

## Architecture Overview

The StakeIt backend is built on a decentralized architecture using only:

- **Smart Contract**: `StakeIt.sol` - Core staking and voting logic on Hedera
- **IPFS Integration**: Decentralized proof storage
- **HCS Integration**: Timestamping service for proof submissions

## Components

### 1. Smart Contract (`contracts/StakeIt.sol`)

The main Solidity contract deployed on Hedera Smart Contract Service (HSCS):

- **Goal Creation**: Users stake HBAR on personal goals
- **Voting System**: Community votes on goal completion daily
- **Proof Submission**: IPFS hashes for completion evidence
- **Finalization**: Decentralized goal completion with penalty distribution
- **Security**: ReentrancyGuard, AccessControl, Pausable functionality

### 2. IPFS Integration

Handles decentralized file storage:

- **File Upload**: Proof documents and images to IPFS
- **Pinata Integration**: Reliable pinning service
- **Fallback Support**: Local IPFS node support
- **Metadata Storage**: JSON data for additional context

### 3. HCS Integration

Hedera Consensus Service integration:

- **Topic Creation**: Dedicated channels for timestamping
- **Message Submission**: Immutable proof timestamps
- **Verification**: Timestamp validation for submitted proofs
- **Query Support**: Historical timestamp retrieval

## Setup Instructions

### Prerequisites

- Hedera testnet account
- Pinata account (for IPFS pinning)
- Git

### Installation

1. **Clone and navigate to backend directory:**
   ```bash
   cd Back-End/
   ```

2. **Deploy smart contract:**
   ```bash
   cd contracts/
   npm install
   npx hardhat run scripts/deploy.js --network testnet
   # Update CONTRACT_ADDRESS in .env
   ```

3. **Create HCS topic:**
   ```bash
   # Use Hedera SDK to create topic
   # Update HCS_TOPIC_ID in .env
   ```

### Configuration

Key environment variables:

```env
# Hedera
HEDERA_ACCOUNT_ID=0.0.xxxx
HEDERA_PRIVATE_KEY=your_private_key
CONTRACT_ADDRESS=0.0.xxxx

# IPFS
PINATA_API_KEY=your_pinata_key
PINATA_SECRET_KEY=your_pinata_secret

# HCS
HCS_TOPIC_ID=0.0.xxxx
```

## Running the Services

The decentralized architecture eliminates the need for centralized services. All operations are handled directly through the smart contract, IPFS, and HCS.

## Development

### Project Structure

```
Back-End/
├── contracts/           # Solidity smart contracts
│   ├── StakeIt.sol
│   ├── deploy.js
│   ├── hardhat.config.js
│   └── package.json
├── .env.example        # Environment template
└── README.md          # This file
```

### Testing

```bash
cd contracts/
npx hardhat test
```

## Security Considerations

- **Access Control**: Role-based permissions on contract
- **Reentrancy Protection**: Guards on all withdrawal functions
- **Input Validation**: Comprehensive parameter checking

## Deployment

### Production Checklist

- [ ] Environment variables configured
- [ ] Smart contract deployed to mainnet
- [ ] HCS topic created
- [ ] IPFS pinning service configured

## Contributing

1. Follow existing code style and patterns
2. Add appropriate logging
3. Update documentation
4. Test thoroughly before committing
5. Use meaningful commit messages

## License

MIT License - see LICENSE file for details