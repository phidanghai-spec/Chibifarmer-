# HayDay Offline Tourism (Chibi Farmer)

## Triển khai web

Yêu cầu: đã cài Vercel CLI và chạy `vercel login` một lần trên máy.

- **Chạy thử xuất web không triển khai:**
  ```powershell
  powershell -ExecutionPolicy Bypass -File tools\deploy_web.ps1 -NoDeploy
  ```
- **Triển khai bản Preview lên Vercel:**
  ```powershell
  powershell -ExecutionPolicy Bypass -File tools\deploy_web.ps1
  ```
- **Triển khai bản Production lên Vercel:**
  ```powershell
  powershell -ExecutionPolicy Bypass -File tools\deploy_web.ps1 -Prod
  ```
