# Vertical Wallet

## 概要

企業向けノンカストディアル・スマートウォレット。ERC-4337 Account Abstraction をベースに、ロール・パーミッション管理と親子ウォレット構造を実装する。

- **対応チェーン**: Kaia
- **使用トークン**: JPYC
- **カストディ**: ノンカストディアル（運営は鍵を一切管理しない）

---

## ウォレット構造

オンチェーンでは全ウォレットが同一の `VerticalAccount` コントラクトとして独立して存在する。親子関係・グループ構成はオフチェーン（DB）で管理する。

```
親ウォレット          ← DB で「親」として管理
│
│   ↓ 資金配分（親 → 子）
│   ↑ 資金集約（子 → 親）
│
├── 子ウォレット A    ← DB で「子・グループ A」として管理
├── 子ウォレット B    ← DB で「子・グループ B」として管理
└── 子ウォレット C    ← DB で「子・グループ C」として管理
```

- Admin はアプリ層を通じて配下のウォレット全体を管理できる
- Operator は担当ウォレットのみ操作できる（DB で割り当てを管理）
- 子ウォレット同士の直接送金は行わない

---

## ロールと権限

| ロール | 概要 |
|---|---|
| Admin | ウォレット全体の管理者 |
| Operator | 日常的な送金・業務操作を行う担当者（複数人可・同一権限） |

| 業務 | Operator | Admin | 備考 |
|---|:---:|:---:|---|
| 売上送金 | ○ | ○ | ホワイトリスト制限あり |
| 資金移動 | | ○ | ホワイトリスト制限あり |
| 給与・報酬の振込（バッチ） | | ○ | ホワイトリスト制限あり |
| メンバーの追加・削除 | | ○ | |
| ホワイトリスト管理 | | ○ | |
| Session Key の発行・失効 | | ○ | |

---

## 業務一覧

ベースは EOA 相当のフル実行（任意のコントラクト呼び出し・送金が可能）。その上にロール・パーミッションのレイヤーが乗る。

### 資産操作

| 業務 | Operator | Admin | Session Key | 備考 |
|---|:---:|:---:|:---:|---|
| 送金 | ○ | ○ | ○ | ホワイトリスト制限あり |
| 任意のコントラクト呼び出し | | ○ | | |
| 給与・報酬の振込（バッチ） | | | ○ | 有効期限・上限・ホワイトリスト制限あり |

### ウォレット管理

| 業務 | Operator | Admin | Session Key |
|---|:---:|:---:|:---:|
| 子ウォレット作成 | | ○ | |

### メンバー・権限管理

| 業務 | Operator | Admin | Session Key |
|---|:---:|:---:|:---:|
| メンバーの追加・削除 | | ○ | |
| ホワイトリストの追加・削除 | | ○ | |
| Session Key の発行・失効 | | ○ | |

---

## Session Key

人間の操作なしに定期的なトランザクションを実行するバッチ処理機能。Admin が発行した Session Key を使用する。

### 発行フロー

```
① 企業が Session Key の鍵ペアを生成
        （秘密鍵は企業サーバーで保管、Vertical Wallet には渡さない）
        ↓
② 企業が公開アドレスを Admin に連携
        ↓
③ Admin が PassKey で署名して issueSessionKey() を呼び出し
        （有効期限・送金上限・送金先ホワイトリストを設定）
        ↓
④ コントラクトが Session Key の制約をオンチェーンに記録
        ↓
⑤ 企業サーバーが秘密鍵で UserOp に署名して自動実行
```

| 作業 | 担当 |
|---|---|
| 鍵ペアの生成・秘密鍵の保管 | 企業 |
| Session Key の登録・制約設定 | Admin（PassKey で署名） |
| 制約の検証 | コントラクト（オンチェーン） |

---

## ビジネスモデル

顧客からの売り上げに対して **1.0%** の手数料を徴収する。

| 決済手段 | 手数料率 | 100万円の手数料 |
|---|---|---|
| クレジットカード | 3.0〜5.0% | 30,000〜50,000円 |
| PayPay | 1.98% | 19,800円 |
| **Vertical Wallet** | **1.0%** | **10,000円** |

ブロックチェーン上の直接送金によりカードブランド・イシュアー・アクワイアラー・代理店などの中間業者コストを排除できるため、低コストを実現する。

### 支払いフロー

```
顧客 → 子ウォレット: JPYC を直接送金（ERC-20 transfer）
```

### 手数料の適用範囲

手数料は顧客からの売り上げにのみ適用する。内部送金・給与支払いには課金しない。

| 送金の種類 | 手数料 |
|---|---|
| 売り上げ（顧客 → 子ウォレット） | **1% 徴収** |
| 売上送金（子 → 親） | なし |
| 資金配分（親 → 子） | なし |
| 給与・報酬の振込 | なし |

手数料は `transfer()` による売上送金（子→親）のタイミングで徴収する。

---

## データ管理方針

**ブロックチェーン**：コントラクトが検証に使うプリミティブな情報

| 情報 | 例 |
|---|---|
| ウォレットアドレス・トランザクション | 原本 |
| トークン残高 | JPYC コントラクトが保持 |
| ロール割り当て | credentialId → Role |
| Session Key の制約 | 有効期限・送金上限・ホワイトリスト |
| 実行ログ | イベントとして記録 |

**DB**：ブロックチェーン情報への付加情報 + ブロックチェーンに存在しない情報

| 情報 | 例 |
|---|---|
| 付加情報 | トランザクションの目的・メモ、ウォレットの企業名・部署名 |
| 人・組織情報 | 社員情報、credentialId ↔ 社員のマッピング |
| **ウォレット構造** | **親子関係・グループ構成（どのウォレットが同一企業に属するか）** |
| 業務フロー | 画面アクセス制御、通知・承認フローの状態 |

---

## 非機能要件

- 複数人承認（Multi-sig）は不要
- 残高照会などの読み取りはオフチェーン側で制御
- 認証手段は PassKey（人間操作）と Session Key（自動処理）の 2 種類
- **ノンカストディアル**: 運営は鍵を一切保持しない。PassKey はユーザーのデバイスで管理し、Session Key は企業が自社サーバーで管理する

---

## コントラクト

### ファイル構成

```
contracts/
├── accounts/
│   ├── VerticalAccount.sol         # ウォレット本体（親・子共通）
│   └── VerticalAccountFactory.sol  # CREATE2 でウォレットを生成
├── interfaces/
│   ├── IVerticalAccount.sol
│   └── IVerticalAccountFactory.sol
└── validators/
    └── PassKeyValidator.sol        # P-256 署名検証（RIP-7212）
```

| コントラクト | 責務 | デプロイ |
|---|---|---|
| `VerticalAccount` | ロール管理・送金・ホワイトリスト・Session Key | 必要 |
| `VerticalAccountFactory` | CREATE2 によるウォレット生成 | 必要 |
| `PassKeyValidator` | P-256 署名の検証ロジック | 必要 |
| `EntryPoint` | ERC-4337 EntryPoint v0.8（シングルトン） | デプロイ不要（下表のアドレスを参照） |

ガス代は Kaia GA が肩代わりするため、ユーザーは KAIA を保持しなくても操作できる。

### デプロイ済みアドレス

#### ERC-4337 EntryPoint v0.8（シングルトン）

| Network | Address |
|---|---|
| Kaia Mainnet | `0x4337084D9E255Ff0702461CF8895CE9E3b5Ff108` |
| Kaia Kairos | `0x4337084D9E255Ff0702461CF8895CE9E3b5Ff108` |

#### VerticalAccountFactory

| Network | Address | Explorer | 検証 |
|---|---|---|---|
| Kaia Kairos | `0x3f770F634DC0C582b4F8e808Ea704Da9D82a491a` | [Kaiascan](https://kairos.kaiascan.io/address/0x3f770F634DC0C582b4F8e808Ea704Da9D82a491a#code) | ✅ |
| Kaia Mainnet | — | — | 未デプロイ |

コンストラクタ引数: `entryPoint` = `0x4337084D9E255Ff0702461CF8895CE9E3b5Ff108`

`VerticalAccount` は Factory 経由で CREATE2 デプロイされるため、単体アドレスはウォレットごとに異なる。

---

## Development

```shell
# Test
npx hardhat test

# Deploy (Kaia Kairos)
npx hardhat ignition deploy ignition/modules/VerticalAccountFactory.ts --network kairos

# Verify (Kaia Kairos) — constructor: IEntryPoint entryPoint
npx hardhat verify --network kairos \
  0x3f770F634DC0C582b4F8e808Ea704Da9D82a491a \
  0x4337084D9E255Ff0702461CF8895CE9E3b5Ff108
```
