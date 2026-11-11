# VNHN 3D Parts Library

Thư viện mô hình 3D linh kiện tiêu chuẩn — GitHub Pages + Supabase.

## Cấu trúc repo (B1)
```
.nojekyll
README.md
setup-test.html                 Trang kiểm tra kết nối (xóa khi phát hành)
supabase/01_setup.sql           Bảng, RLS, RPC, bucket, storage policy
js/config.js                    URL + anon key + hằng số
js/supabase-client.js           Client + helper
.github/workflows/keepalive.yml Ping chống pause
```

## Setup B1

### 1. Supabase
1. https://supabase.com → New project (region: **Southeast Asia (Singapore)**).
2. **SQL Editor** → dán toàn bộ `supabase/01_setup.sql` → Run.
3. **Authentication → Sign In / Providers → Email**: tắt *Allow new users to sign up* (chỉ admin tự tạo).
4. **Authentication → Users → Add user** → nhập email/mật khẩu admin (tick *Auto Confirm*).
5. SQL Editor chạy:
   ```sql
   insert into public.admins (user_id)
   select id from auth.users where email = 'EMAIL_ADMIN@domain.com'
   on conflict do nothing;
   ```
6. **Project Settings → API**: copy *Project URL* và *anon public key* → dán vào `js/config.js`.

### 2. GitHub
1. Tạo repo (VD `vnhn-3d-library`) dưới `hailv0994`, push toàn bộ file.
2. **Settings → Pages** → Source: *Deploy from a branch* → `main` / `root`.
3. **Settings → Secrets and variables → Actions** → thêm `SUPABASE_URL`, `SUPABASE_ANON_KEY`.
4. **Actions → Supabase keep-alive → Run workflow** để chạy thử 1 lần.

### 3. Test
Mở `https://hailv0994.github.io/vnhn-3d-library/setup-test.html`:
- Mục 1–6 phải **OK** hết.
- Đăng nhập admin → `is_admin: true`.

## Lưu ý
- Chỉ dùng **anon key** ở frontend. Không commit `service_role key`.
- Cấu trúc file trong bucket cố định: `{id}/original.ext`, `{id}/preview.glb`, `{id}/thumb.webp` — không đổi sau khi phát hành.
- GitHub tự tắt workflow cron nếu repo không có commit 60 ngày → vào Actions bật lại.
