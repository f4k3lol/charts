```shell
helm dependency update
helm install --dry-run  --disable-openapi-validation -f test.yaml test .
```
