# StakeIt

A Web3 accountability platform that turns personal goals into financial commitments on Hedera. Users stake HBAR on their goals, submit daily proofs, and community voting determines success. Failed goals automatically donate a portion of stakes to charity, transforming personal setbacks into social good.

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Setup Instructions](#setup-instructions)
- [Deployment Guide](#deployment-guide)
- [Testing](#testing)
- [Contributing](#contributing)
- [License](#license)

## Overview

StakeIt solves the widespread problem of goal abandonment by creating a financial commitment mechanism. Users stake real HBAR tokens on personal goals (7-30 days), submit daily proof of progress, and community members vote on completion validity. Successful goals return full stakes plus rewards, while failed goals distribute 25% of stakes to charity, platform, and liquidity reserves.

### Key Components

- **Smart Contract**: `StakeIt.sol` - Core staking, voting, and penalty logic on Hedera Smart Contract Service (HSCS)
- **IPFS Integration**: Decentralized proof storage for images and documents
- **Hedera Consensus Service (HCS)**: Immutable timestamping for proof submissions
- **Frontend**: React/Next.js application with wallet integration (HashPack/MetaMask)

### Business Value

- **Real Accountability**: Financial stakes create genuine consequences for quitting
- **Community Engagement**: Peer-to-peer verification system builds social connections
- **Social Impact**: Failed goals automatically fund charitable causes
- **Transparent & Trustless**: All operations handled by on-chain smart contracts

## Architecture

### System Layers

```
┌─────────────────┐
│   Frontend UI   │ React/Next.js + Wallet Integration
├─────────────────┤
│ Business Logic  │ Smart Contract (HSCS)
├─────────────────┤
│ Data Storage    │ IPFS + HCS + On-chain
├─────────────────┤
│ Blockchain      │ Hedera Network
└─────────────────┘
```

### Data Flow

1. **Goal Creation**: User stakes HBAR → Smart contract creates goal struct
2. **Daily Proofs**: User uploads to IPFS → HCS timestamp → Contract stores metadata
3. **Community Voting**: Verifiers stake 1 HBAR → Vote on proof validity → On-chain aggregation
4. **Finalization**: Contract auto-finalizes → Distributes funds based on majority vote

### Security Features

- **ReentrancyGuard**: Protects all withdrawal functions
- **AccessControl**: Role-based permissions for admin functions
- **Pausable**: Emergency pause capability
- **Input Validation**: Comprehensive parameter checking

## Features

### MVP Features

- ✅ Wallet Connection (HashPack/MetaMask)
- ✅ Goal Creation (7-30 days, 1-100 HBAR stake)
- ✅ Daily Proof Submission (IPFS + HCS timestamping)
- ✅ Community Voting System (1 HBAR stake per vote)
- ✅ Automated Goal Finalization
- ✅ Transparent Fund Distribution
- ✅ Withdrawal System

### Economic Model

- **Staking Range**: 1-100 HBAR per goal
- **Voter Stake**: 1 HBAR per vote
- **Penalty Distribution**: 25% of failed stakes
  - 8% → Charity Wallet
  - 8% → Platform Wallet
  - 9% → Liquidity Reserve
- **Success Reward**: Full stake return + completion points
- **Voting Reward**: 1 point per valid vote

### Future Roadmap

- AI-powered proof verification
- DAO governance for contract parameters
- NFT completion certificates
- Tradable points token (HTS)

## Prerequisites

- **Hedera Account**: Testnet account with HBAR for deployment
- **IPFS Account**: Pinata or similar service for decentralized storage
- **Node.js**: v16+ for smart contract development
- **Git**: Version control
- **Wallets**: HashPack or MetaMask for testing

## Setup Instructions

### 1. Clone Repository

```bash
git clone https://github.com/your-org/stakeit.git
cd stakeit
```

### 2. Smart Contract Setup

```bash
cd Back-End/Contracts
npm install
```

### 3. Environment Configuration

Copy the environment template:

```bash
cp ../.env.example ../.env
```

Configure the following variables:

```env
# Hedera Configuration
HEDERA_ACCOUNT_ID=your_hedera_account_id
HEDERA_PRIVATE_KEY=your_private_key

# IPFS Configuration (Pinata)
PINATA_API_KEY=your_pinata_api_key
PINATA_SECRET_KEY=your_pinata_secret_key

# Treasury Addresses (update after deployment)
CHARITY_WALLET=0x0000000000000000000000000000000000000000
PLATFORM_WALLET=0x0000000000000000000000000000000000000000
LIQUIDITY_RESERVE=0x0000000000000000000000000000000000000000
```

### 4. Compile Contracts

```bash
npm run compile
```

### 5. Run Tests

```bash
npm run test
```

## Deployment Guide

### Testnet Deployment

1. **Deploy Smart Contract**:
   ```bash
   npm run deploy
   ```

2. **Create HCS Topic**:
   ```javascript
   // Use Hedera SDK to create topic for proof timestamping
   const topicId = await createHcsTopic();
   ```

3. **Update Environment**:
   ```env
   CONTRACT_ADDRESS=deployed_contract_address
   HCS_TOPIC_ID=created_topic_id
   ```

### Production Deployment

1. **Security Audit**: Complete third-party security review
2. **Mainnet Deployment**: Deploy to Hedera mainnet
3. **Treasury Setup**: Configure production wallet addresses
4. **Monitoring**: Set up contract monitoring and alerts

### Deployment Checklist

- [ ] Environment variables configured
- [ ] Smart contract deployed to target network
- [ ] HCS topic created for timestamping
- [ ] IPFS pinning service configured
- [ ] Treasury addresses updated
- [ ] Contract verified on block explorer
- [ ] Initial test transactions completed

## Testing

### Smart Contract Tests

```bash
cd Back-End/Contracts
npm test
```

### Test Coverage

- Goal creation and validation
- Proof submission and verification
- Voting mechanics and stake locking
- Goal finalization and fund distribution
- Withdrawal and reentrancy protection
- Access control and emergency functions

### Integration Testing

- Wallet connection flows
- IPFS upload and retrieval
- HCS timestamp verification
- Cross-contract interactions

## Contributing

We welcome contributions from the community! Please follow these guidelines:

### Development Workflow

1. **Fork** the repository
2. **Create** a feature branch: `git checkout -b feature/your-feature`
3. **Make** your changes following our coding standards
4. **Test** thoroughly: `npm test`
5. **Commit** with clear messages: `git commit -m "Add: feature description"`
6. **Push** to your fork: `git push origin feature/your-feature`
7. **Create** a Pull Request

### Code Standards

- **Solidity**: Follow OpenZeppelin patterns and NatSpec documentation
- **JavaScript**: Use ESLint configuration and async/await patterns
- **Testing**: Minimum 80% test coverage for new features
- **Documentation**: Update README and code comments for changes

### Issue Reporting

- Use GitHub Issues for bug reports and feature requests
- Include detailed reproduction steps for bugs
- Specify your environment (OS, Node version, etc.)

### Security

- Report security vulnerabilities via email to security@stakeit.com
- Do not disclose vulnerabilities publicly until patched
- Include proof-of-concept and potential impact assessment

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contact

- **Website**: [stakeit.com](https://stakeit.com)
- **Documentation**: [docs.stakeit.com](https://docs.stakeit.com)
- **Discord**: [Join our community](https://discord.gg/stakeit)
- **Twitter**: [@StakeItWeb3](https://twitter.com/StakeItWeb3)

## Acknowledgments

- **Hedera**: For providing the robust, low-cost infrastructure
- **OpenZeppelin**: For battle-tested smart contract components
- **IPFS**: For decentralized file storage capabilities
- **Our Community**: For participating in governance and testing

---

**StakeIt** - Turning goals into commitments, failures into good deeds.