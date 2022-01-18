## 关于 config.json
- 使用 aliyun 的 [packagist 镜像](https://developer.aliyun.com/composer)。
- 并未将 [sjk-repo](http://repo.devutil.sanjieke.cn/) 加入 repositories，因为此配置普遍由项目的 composer.json 进行配置。

## 关于 composer.json
- 我们可以将通用工具类 package 加入其中。
- 执行 `composer global update` 可以安装这些 packages。

### 关于 IDE
- 建议将此目录加入 IDE 的忽略地址，减少不必要的 IDE 索引动作。
