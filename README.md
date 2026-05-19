# EduStake DAO

`EduStake DAO` e um MVP de protocolo Web3 voltado para um contexto educacional ou de comunidade digital. O projeto foi desenvolvido para demonstrar, de forma pratica, a integracao entre token ERC-20, NFT, staking, governanca simples, oraculo e scripts Web3.

## Ideia do projeto
O sistema foi pensado para reunir tres funcoes principais em um unico fluxo:
- recompensar participacao com tokens
- registrar certificados digitais com NFT
- permitir votacao em decisoes simples da comunidade

Com isso, o projeto mostra como diferentes contratos inteligentes podem trabalhar juntos dentro de uma mesma aplicacao.

## Componentes do sistema
- `EduToken`: token ERC-20 usado para recompensa, staking e voto
- `CertificadoNFT`: NFT ERC-721 usado para certificado digital
- `EduStaking`: contrato de staking com recompensa
- `EduGovernance`: contrato de governanca simplificada
- `MockV3Aggregator`: mock de oraculo para rede local

## Estrutura do projeto
```text
contracts/
  EduToken.sol
  CertificadoNFT.sol
  EduStaking.sol
  EduGovernance.sol
  interfaces/AggregatorV3Interface.sol
  mocks/MockV3Aggregator.sol

scripts/
  deploy.js
  demo.js

test/
  EduStakeDAO.test.js
```

## Deploy em Sepolia
O deploy do MVP foi realizado com sucesso na testnet `Sepolia`.

Enderecos publicados:
- `EduToken`: `0xAdC4B20Efbb8682bF66B874b2370d1acda44daC1`
- `CertificadoNFT`: `0x5531C4ffF1Cd0E6C27518BCfA32c645e2845ecf5`
- `EduStaking`: `0x7c7810464005F04Fd3Cc8179C56f0097EaC66981`
- `EduGovernance`: `0xFE9510182b2D6bf0E86E773a74815927bE19893C`

Links do explorer:
- [EduToken](https://sepolia.etherscan.io/address/0xAdC4B20Efbb8682bF66B874b2370d1acda44daC1)
- [CertificadoNFT](https://sepolia.etherscan.io/address/0x5531C4ffF1Cd0E6C27518BCfA32c645e2845ecf5)
- [EduStaking](https://sepolia.etherscan.io/address/0x7c7810464005F04Fd3Cc8179C56f0097EaC66981)
- [EduGovernance](https://sepolia.etherscan.io/address/0xFE9510182b2D6bf0E86E773a74815927bE19893C)

## Demonstracao executada
A demonstracao Web3 em `Sepolia` executou com sucesso:
- mint de NFT
- stake de tokens
- criacao de proposta
- voto na DAO

Observacao:
- `claimReward` e `finalizeProposal` nao foram executados no mesmo fluxo da testnet porque em rede publica nao e possivel adiantar o tempo localmente como acontece no Hardhat

## Video de demonstracao
LINK

## Testes
O projeto foi compilado e validado localmente com `Hardhat`.

Resultado:
- `3 testes executados`
- `3 testes aprovados`

Casos cobertos:
- stake e claim de recompensa
- mint do NFT
- criacao, voto e finalizacao de proposta

## Seguranca aplicada
- `Ownable` para controle administrativo
- `ReentrancyGuard` no staking
- `require()` para validacoes
- `SafeERC20` para transferencias seguras
- `Solidity ^0.8.x`

## Auditoria
Ferramentas consideradas:
- `Hardhat`: executado com sucesso
- `Slither`: executado com sucesso
- `Mythril`: executado com sucesso em container Docker

Os arquivos com a saida das analises foram salvos em:
- `slither_output.txt`
- `mythril_output.txt`

## Requisitos
- Node.js LTS com `npm`
- carteira com `Sepolia ETH`
- chave RPC para `Sepolia`

## Instalacao
```bash
npm install
```

## Configuracao
Copie `.env.example` para `.env` e preencha:

```env
SEPOLIA_RPC_URL=...
PRIVATE_KEY=...
PRICE_FEED_ADDRESS=...
```

Observacoes:
- em rede local, o deploy usa `MockV3Aggregator`
- em testnet, o projeto utiliza um feed real `ETH/USD`

## Tutorial de execucao
Se o PowerShell bloquear o comando `npm`, use `npm.cmd` no lugar. Exemplo:

```bash
npm.cmd run test
```

### 1. Instalar as dependencias
```bash
npm install
```

### 2. Compilar o projeto
```bash
npm run compile
```

### 3. Executar os testes
```bash
npm run test
```

### 4. Rodar o projeto em rede local
No primeiro terminal:

```bash
npm run node
```

No segundo terminal:

```bash
npm run deploy:local
npm run demo:local
```

Fluxo esperado na rede local:
- deploy dos contratos
- mint de NFT
- stake de tokens
- criacao de proposta
- voto na DAO

### 5. Rodar o projeto em Sepolia
Antes desta etapa, o arquivo `.env` deve estar preenchido com sua RPC e sua carteira.

```bash
npm run deploy:sepolia
npm run demo:sepolia
```

Fluxo esperado em Sepolia:
- deploy dos contratos na testnet
- execucao da demonstracao Web3
- geracao dos enderecos em `deployments/sepolia.json`

## Comandos principais
```bash
npm run compile
npm run test
npm run node
npm run deploy:local
npm run deploy:sepolia
npm run demo:local
npm run demo:sepolia
```

Para a rede local persistente:
```bash
npm run node
npm run deploy:local
npm run demo:local
```
