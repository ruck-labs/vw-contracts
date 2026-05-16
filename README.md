# Vertical Wallet

## 概要

企業向けノンカストディアル・スマートウォレット。ERC-4337 Account Abstraction をベースに、Owner Key（PassKey）と Session Key による権限管理、および組織向けマルチウォレット構造を実装する。

- **対応チェーン**: Kaia
- **使用トークン**: JPYC

## 利用ユーザー

事業で JPYC 決済する事業者（法人・組織）。店頭・オンライン・イベント・法人間送金など、業種を問わず JPYC を事業活動の決済・受取・管理に使う主体を想定する。

## キー種別と権限

ロールレジストリは持たず、キー種別と Session Key のスコープで表現する。

| キー種別 | 認証方式 | 権限 |
|---|---|---|
| Owner Key | PassKey（WebAuthn） | スマートアカウントの完全制御（Session Key 発行・revoke を含む） |
| Session Key | Owner Key が発行 | スコープで定義された限定操作のみ |

## Session Key

- **送金上限**: 1回あたり・1日あたりの JPYC 上限額
- **有効期限**: 発行から N 日間
- **許可操作**: 送金・受取・残高照会など（管理操作は除外）

1. Owner Key（PassKey）が Session Key を発行
2. Session Key 持有者は日常操作を PassKey 署名なしで実行
3. 期限切れまたは Owner Key による revoke で失効
4. 紛失時は Owner Key で再発行可能

> Session Key の発行・失効・一覧管理の UI 仕様は画面一覧で定義します。

## マルチウォレット構造

1 組織は複数の `VerticalAccount`（CREATE2）を持てる。本社・店舗の区分と組織内ウォレット一覧は DB で管理する。

```
組織の Owner Key（PassKey）
├── 本社ウォレット（スマートアカウント）
├── 店舗 A ウォレット（スマートアカウント）
│   └── 店舗 A スタッフの Session Key
└── 店舗 B ウォレット（スマートアカウント）
    └── 店舗 B スタッフの Session Key
```

- 同一 PassKey 公開鍵を全ウォレットの Owner Key として登録する（組織で1つ）
- 各ウォレットは独立したアドレス・残高・履歴を持つ
- Session Key はウォレット単位で発行し、他店舗は操作できない
- Owner Key は全ウォレットの Session Key 管理および資金操作が可能

**注意**: PassKey ローテーション時は全ウォレットの Owner Key を一括更新する。紛失リスクに備え Social Recovery の設定を推奨する。

## コントラクト

| コントラクト | 責務 |
|---|---|
| `VerticalAccount` | PassKey 認証・`grantPassKey` / `revokePassKey`・UUPS（Session Key・スコープ検証は未実装） |
| `VerticalAccountFactory` | CREATE2 によるウォレット生成 |
| `PassKeyValidator` | P-256 署名検証 |
| `EntryPoint` | ERC-4337 EntryPoint v0.8（シングルトン・デプロイ不要） |

### デプロイ済みアドレス

| コントラクト | Network | Address |
|---|---|---|
| EntryPoint v0.8 | Kaia Mainnet / Kairos | `0x4337084D9E255Ff0702461CF8895CE9E3b5Ff108` |
| VerticalAccountFactory | Kaia Kairos | `0x3f770F634DC0C582b4F8e808Ea704Da9D82a491a` ([Kaiascan](https://kairos.kaiascan.io/address/0x3f770F634DC0C582b4F8e808Ea704Da9D82a491a#code)) |
| VerticalAccountFactory | Kaia Mainnet | 未デプロイ |

Factory コンストラクタ引数: `entryPoint` = `0x4337084D9E255Ff0702461CF8895CE9E3b5Ff108`

## Development

```shell
npx hardhat test

npx hardhat ignition deploy ignition/modules/VerticalAccountFactory.ts --network kairos

npx hardhat verify --network kairos \
  0x3f770F634DC0C582b4F8e808Ea704Da9D82a491a \
  0x4337084D9E255Ff0702461CF8895CE9E3b5Ff108
```
