# Safe Multichannel - 快速参考

## 一句话概括

Safe 合约增加了多通道 nonce 支持，允许在不同通道上并行执行交易。

## 核心变更

### 1. 函数签名变更

```solidity
// 旧版本
execTransaction(to, value, data, operation, ...)

// 新版本 (v1.5.0+multichannel.1)
execTransaction(channel, to, value, data, operation, ...)
//              ^^^^^^^ 新增第一个参数
```

### 2. EIP-712 TypeHash 变更

```javascript
// 旧
"SafeTx(address to,uint256 value,bytes data,...)";

// 新
"SafeTx(uint256 channel,address to,uint256 value,bytes data,...)";
//      ^^^^^^^^^^^^^^^ 新增
```

### 3. Nonce 管理变更

```python
# 旧：单一 nonce
safe.nonce() -> 5

# 新：多通道 nonce
safe.channelNonces(0) -> 5
safe.channelNonces(1) -> 3
safe.channelNonces(2) -> 0
```

## Sepolia 部署地址

```
Safe:              0xf1da1C6Dbdb74F16f9b2054795e29df01b5eb3a2
SafeL2:            0xdDd4D7f67bA22b58a9340330A5a220A122967fec
SafeProxyFactory:  0x72D89c510AFBeC255b81482C8DCC720FC8743175
```

所有合约已验证：https://sepolia.etherscan.io/

## Server 端改造要点

### 必做项

1. **数据库添加 channel 字段**

    ```sql
    ALTER TABLE multisig_transaction ADD COLUMN channel BIGINT NOT NULL DEFAULT 0;
    CREATE INDEX idx_safe_channel_nonce ON multisig_transaction(safe, channel, nonce);
    ```

2. **API 增加 channel 参数**

    ```python
    # POST /api/v1/safes/{address}/multisig-transactions/
    {
        "channel": 0,  # 新增
        "to": "...",
        "value": "...",
        # ... 其他字段
    }
    ```

3. **更新 Hash 计算**

    ```python
    def calculate_hash(safe_address, tx_data):
        version = get_safe_version(safe_address)
        if version.startswith("1.5.0+multichannel"):
            return calculate_multichannel_hash(tx_data)  # 包含 channel
        else:
            return calculate_legacy_hash(tx_data)  # 不包含 channel
    ```

4. **Nonce API 更新**
    ```python
    # GET /api/v1/safes/{address}/nonces/
    {
        "nonces": {
            "0": 5,
            "1": 3,
            "2": 0
        }
    }
    ```

## 版本检测

```python
def supports_multichannel(safe_address: str) -> bool:
    version = safe_contract.functions.VERSION().call()
    return version.startswith("1.5.0+multichannel")
```

## 重要提醒

⚠️ **向后不兼容**：multichannel 版本的 EIP-712 hash 与标准版本不同
⚠️ **必须版本检测**：根据 Safe 版本使用不同的 hash 计算方法
⚠️ **数据库约束**：`(safe, channel, nonce)` 必须唯一

## 详细文档

完整技术细节请查看：`MULTICHANNEL_HANDOVER.md`

## 测试合约

在 Sepolia 上使用以下地址测试：

- Safe (multichannel): `0xf1da1C6Dbdb74F16f9b2054795e29df01b5eb3a2`
- 查看已验证源码：https://sepolia.etherscan.io/address/0xf1da1C6Dbdb74F16f9b2054795e29df01b5eb3a2#code
