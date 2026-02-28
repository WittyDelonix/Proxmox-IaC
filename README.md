## 1. Yêu Cầu Trước Khi Cài Đặt

### Trên máy cục bộ / GitHub runner

| Công cụ | Phiên bản tối thiểu |
|---|---|
| Git | Bất kỳ |
| Terraform | ≥ 1.5.0 |
| Python 3 + pip | ≥ 3.8 |
| Ansible | ≥ 2.12 |
| SSH client | Bất kỳ |

### Trên Proxmox host

- Proxmox VE 7.x hoặc 8.x đã được cài đặt và có thể truy cập qua mạng
- Ít nhất một storage pool khả dụng (ví dụ: `local-lvm`)
- Proxmox host có kết nối internet (để tải Ubuntu cloud image)

---

## 2. Chuẩn Bị Proxmox Host

Tất cả các lệnh trong phần này được chạy **trực tiếp trên Proxmox host** (qua SSH hoặc shell console).

### 2a. Tạo VM Template Ubuntu Cloud-Init

```bash

wget https://raw.githubusercontent.com/WittyDelonix/Proxmox-IaC/refs/heads/main/scripts/create-proxmox-template.sh

chmod +x create-proxmox-template.sh
bash create-proxmox-template.sh
```

Script sẽ thực hiện:
- Tải Ubuntu 22.04 cloud image
- Tạo VM template với ID `9000` tên là `ubuntu-cloud-template`
- Cấu hình cloud-init, QEMU agent và thứ tự boot đúng (`scsi0`)
- Mở rộng dung lượng đĩa lên 20 GB
- Chuyển đổi VM thành template

> **Kiểm tra template trước khi tiếp tục:**
> ```bash
> qm clone 9000 999 --name test-vm && qm start 999
> # Kiểm tra boot thành công, sau đó dọn dẹp:
> qm stop 999 && qm destroy 999
> ```

### 2b. Tạo Proxmox API Token cho Terraform

```bash
wget https://raw.githubusercontent.com/WittyDelonix/Proxmox-IaC/refs/heads/main/scripts/create-api-token.sh

chmod +x create-api-token.sh
bash create-api-token.sh
```

Script sẽ tạo:
- Người dùng `terraform@pam` với `TerraformRole` có đủ quyền quản lý VM, storage và pool
- API token tên `terraform@pam!terraform`

**Lưu lại token secret được in ra màn hình — nó sẽ không được hiển thị lại.**

--

## 3. Cấu Hình GitHub Secrets

### Tạo cặp SSH key (nếu chưa có)

```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa
cat ~/.ssh/id_rsa.pub
```

### Thêm các secret sau vào repository tại **Settings → Secrets and variables → Actions**:

| Tên Secret | Giá trị |
|---|---|
| `PROXMOX_API_URL` | `https://<PROXMOX_HOST>:8006/api2/json` |
| `PROXMOX_API_TOKEN_ID` | `terraform@pam!terraform` |
| `PROXMOX_API_TOKEN_SECRET` | Token secret từ bước 2b |
| `SSH_PUBLIC_KEY` | Nội dung file `~/.ssh/id_rsa.pub` |
| `SSH_PRIVATE_KEY` | Nội dung file `~/.ssh/id_rsa` |

---

## 4. Thiết Lập GitHub Self-Hosted Runner

Pipeline yêu cầu **self-hosted runner** chạy trên máy chủ runner

```bash
wget https://raw.githubusercontent.com/WittyDelonix/Proxmox-IaC/refs/heads/main/scripts/setup-github-runner.sh

chmod +x create-api-token.sh
bash scripts/setup-github-runner.sh
```

## 5. Clone Repository

```bash
git clone https://github.com/WittyDelonix/Proxmox-IaC.git
cd Proxmox-IaC
```

---

## 6. Cấu Hình Biến Terraform

### Tạo file `terraform.tfvars`

Chỉnh sửa `terraform/terraform.tfvars` với các giá trị của bạn:

```hcl
# Kết nối Proxmox
proxmox_api_url          = "https://<PROXMOX_HOST>:8006/api2/json"
proxmox_api_token_id     = "terraform@pam!terraform"
proxmox_api_token_secret = "<TOKEN_SECRET_TU_BUOC_2b>"
proxmox_tls_insecure     = true   # đặt false nếu có chứng chỉ TLS hợp lệ
proxmox_node             = "pve"  # tên node Proxmox

# Template
vm_template_name = "ubuntu-cloud-template"

# Thông số VM (điều chỉnh theo phần cứng)
vm_count     = 1        # số lượng application VM
vm_cores     = 2
vm_memory    = 1024     # MB
vm_disk_size = "10G"
vm_storage   = "local-lvm"

# Mạng
vm_network_bridge = "vmbr0"
vm_network_model  = "virtio"
vm_ip_base        = "192.168.58"  # ba octet đầu của subnet
vm_ip_start       = 100           # app-vm-1 nhận .100, app-vm-2 nhận .101, v.v.

# SSH
ssh_public_key = "ssh-rsa AAAA..."

# VM Monitoring
monitoring_vm_cores  = 2
monitoring_vm_memory = 2048

# Mật khẩu cloud-init (để truy cập console, SSH key được ưu tiên hơn)
cipassword = "mat-khau-manh"

environment = "production"
```

---

## 7. Truy cập giao diện web

| Dịch vụ | URL | Thông tin đăng nhập mặc định |
|---|---|---|
| Prometheus | `http://<MONITORING_VM_IP>:9090` | Không cần |
| Alertmanager | `http://<MONITORING_VM_IP>:9093` | Không cần |
| Grafana | `http://<MONITORING_VM_IP>:3000` | `admin` / `admin` |
| Self-healing health | `http://<SELF_HEALING_VM_IP>:5000/health` | Không cần |

Truy cập `http://<MONITORING_VM_IP>:9090/targets` — tất cả các target phải hiển thị trạng thái **UP**.
