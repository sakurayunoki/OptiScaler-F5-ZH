# 维护说明

本仓库只跟踪 **汉化资产**（`dict/ overlay/ scripts/ tools/ .github/`），上游源码每次由 CI 现取现用，不提交进版本库。

- 工作流：`.github/workflows/localize.yml`（sync 取上游+预检+补译 → windows 编译 → release 发包）。
- 触发：推送到 `dict/ scripts/ overlay/ .github/workflows/`，或 Actions 页面手动 Run workflow。
- 锚点失效：`apply_patch` 预检报结构锚点未命中时，人工修 `dict/structural.json`。
- 详细移植方法见 `README-ZH39.md`。
