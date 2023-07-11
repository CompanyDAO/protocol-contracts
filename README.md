# Sample Hardhat Project
[![MythXBadge](https://badgen.net/https/api.mythx.io/v1/projects/a4139f0f-28b2-49c3-b31e-5bb2c542b53a/badge/data?cache=300&icon=https://raw.githubusercontent.com/ConsenSys/mythx-github-badge/main/logo_white.svg)](https://docs.mythx.io/dashboard/github-badges)
```shell
yarn hardhat deploy --network goerli
```

Keeping track of UUPS proxy addresses

1. Make sure contract_proxy_address_map.json is always commited in rep
2. Always push after ANY changes in contract_proxy_address_map.json
3. This file keeps track of deployed proxy addresses for each smartcontract
4. If you want to deploy new proxies (instead of updating them), set file's contents to an empty JSON object: {}
