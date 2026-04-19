# Flutter MVC App

Project Flutter mau duoc tach theo mo hinh MVC de de mo rong.

## Cau truc chinh

- `lib/models`: Chua cac model du lieu.
- `lib/controllers`: Chua business logic va quan ly state.
- `lib/views`: Chua UI va cac man hinh.
- `lib/core`: Chua route, theme, constants dung chung.

## Cach chay

1. Cai Flutter SDK.
2. Trong thu muc project, chay:
   ```bash
   flutter pub get
   flutter run
   ```

## MVC trong project nay

- `CounterModel`: Luu gia tri dem.
- `HomeController`: Xu ly logic tang giam reset va thong bao cho UI.
- `HomePage`: Hien thi giao dien va goi action tu controller.
