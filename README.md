# Sample Hardhat Project

```shell
yarn hardhat deploy --network goerli
```

Keeping track of UUPS proxy addresses

1. Make sure contract_proxy_address_map.json is always commited in rep
2. Always push after ANY changes in contract_proxy_address_map.json
3. This file keeps track of deployed proxy addresses for each smartcontract
4. If you want to deploy new proxies (instead of updating them), set file's contents to an empty JSON object: {}
