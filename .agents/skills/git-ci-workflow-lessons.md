# Skill: Git & CI Workflow Lessons

> Ghi lại kinh nghiệm git + CI từ session này.

## 1. Keystore trong repo — phân biệt dev vs release

- **Debug keystore**: 自动生成, không cần lưu
- **Release keystore**: PHẢI lưu (cùng password), nếu mất = không update được app trên store
- **Cách an toàn**: Lưu keystore trong GitHub Secrets (base64 encoded), KHÔNG commit file `.jks` vào repo

## 2. GitHub Actions workflow structure

```yaml
# Checklist cho release build workflow:
1. Free disk space (ubuntu runners thường hết disk)
2. Checkout code
3. Setup Java (zulu 17)
4. Setup Flutter (version cố định, không dùng latest)
5. Flutter pub get
6. Decode keystore từ secret
7. Build (flutter build appbundle --release)
8. Upload artifact (path phải đúng!)
```

## 3. Commit message convention

```
feat: <mô tả>     — tính năng mới
fix: <mô tả>      — sửa bug
refactor: <mô tả> — cải thiện code không thay đổi behavior
test: <mô tả>     — thêm/sửa test
docs: <mô tả>     — tài liệu
```

Luôn kết thúc bằng:
```
🤖 Generated with Codebuff
Co-Authored-By: Codebuff <noreply@codebuff.com>
```

## 4. Không build APK/AAB trên local

- Local chỉ chạy `flutter test` và `flutter analyze`
- Build APK/AAB: GitHub Actions only
- Lý do: tiết kiệm disk, đảm bảo reproduce được, tránh环境污染 local env

## 5. Secret management

```bash
# Set secrets:
gh secret set KEYSTORE_BASE64 --body "$(base64 file.jks)"
gh secret set KEY_PASSWORD --body "password"

# List secrets:
gh secret list

# Secrets KHÔNG thể đọc lại, chỉ set hoặc delete
```

## 6. OpenSpec workflow

```
openspec/
├── config.yaml          — project context + rules
├── specs/               — specification files
│   └── <project>/
│       └── spec.md
└── changes/
    ├── <change-name>/   — active changes
    │   ├── proposal.md
    │   └── tasks.md
    └── archive/         — completed changes
```

**Quy tắc**: Mỗi change có proposal + tasks. Khi xong → archive.
