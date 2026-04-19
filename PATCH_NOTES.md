# Patch Notes

File này dùng để ghi lại trạng thái thay đổi liên quan đến phần tài liệu EKS mà Codex đã chuẩn bị, để bạn dễ tự push lên GitHub private từ repo `terraform-starter`.

Ngày cập nhật: `2026-04-19`

## 1. Phạm vi repo hiện tại

Repo đang xét là:

- [terraform-starter](/home/huymd/huymd-test/terraform-starter)

Repo này là một git repository riêng và hiện đang có local changes từ trước.

## 2. Trạng thái git hiện tại của repo

Snapshot `git status --short` tại thời điểm mình kiểm tra:

```text
 M .gitignore
 D .terraform.lock.hcl
 M README.md
 D main.tf
 D outputs.tf
 D variables.tf
 D versions.tf
?? PATCH_NOTES.md
?? docs/
?? live/
?? modules/
```

Ý nghĩa:

- trong repo này đã có thay đổi local sẵn
- các thay đổi đó không phải do patch tài liệu EKS mới tạo ở root workspace
- nếu bạn push từ repo này, hãy tự quyết định giữ nguyên hay tách commit theo ý bạn

## 3. Tài liệu EKS hiện đã nằm trong repo này

Mình đã copy toàn bộ bộ docs EKS vào:

- [terraform-starter/docs/eks](/home/huymd/huymd-test/terraform-starter/docs/eks)

Danh sách file hiện có trong repo:

- [docs/eks/README.md](/home/huymd/huymd-test/terraform-starter/docs/eks/README.md)
- [docs/eks/01-networking.md](/home/huymd/huymd-test/terraform-starter/docs/eks/01-networking.md)
- [docs/eks/02-iam-and-access.md](/home/huymd/huymd-test/terraform-starter/docs/eks/02-iam-and-access.md)
- [docs/eks/03-eks-cluster-aws-cli.md](/home/huymd/huymd-test/terraform-starter/docs/eks/03-eks-cluster-aws-cli.md)
- [docs/eks/04-elb-and-ingress.md](/home/huymd/huymd-test/terraform-starter/docs/eks/04-elb-and-ingress.md)
- [docs/eks/05-day2-and-teardown.md](/home/huymd/huymd-test/terraform-starter/docs/eks/05-day2-and-teardown.md)
- [docs/eks/06-install-aws-load-balancer-controller.md](/home/huymd/huymd-test/terraform-starter/docs/eks/06-install-aws-load-balancer-controller.md)
- [docs/eks/07-sample-app-alb.md](/home/huymd/huymd-test/terraform-starter/docs/eks/07-sample-app-alb.md)

## 4. Nội dung chính của bộ tài liệu EKS

Các file trên bao gồm:

- tài liệu tổng quan học và triển khai `EKS` bằng `aws cli`
- hướng dẫn networking cho `VPC`, `subnet`, `IGW`, `NAT Gateway`, subnet tagging
- hướng dẫn `IAM`, `access entry`, `EKS Pod Identity`
- quy trình tạo `EKS cluster` và `managed node group`
- khái niệm và cách dùng `ALB` với `Ingress`
- khái niệm và cách dùng `NLB` với `Service type=LoadBalancer`
- hướng dẫn cài `AWS Load Balancer Controller` bằng `Helm`
- sample app với `Ingress` để sinh `ALB`
- checklist day-2 operations, troubleshooting và teardown

## 5. Điều quan trọng nếu bạn muốn push từ repo này

Hiện tại repo `terraform-starter` đã chứa cả:

- file patch notes
- bộ docs EKS trong `docs/eks/`

Điều đó có nghĩa là nếu bạn commit và push repo này, toàn bộ docs EKS sẽ đi cùng.

## 6. Cách hiểu đúng về patch hiện tại

Trong repo `terraform-starter`, thay đổi do Codex thực hiện trực tiếp ở turn này là:

- thêm [PATCH_NOTES.md](/home/huymd/huymd-test/terraform-starter/PATCH_NOTES.md)
- thêm thư mục [docs/eks](/home/huymd/huymd-test/terraform-starter/docs/eks)
- copy toàn bộ `8` file docs EKS vào trong thư mục đó

Lưu ý:

- workspace root vẫn còn bản gốc của docs tại `/home/huymd/huymd-test/docs`
- bản dùng để push cùng repo hiện tại là bản trong `terraform-starter/docs/eks/`

## 7. Gợi ý commit message

Nếu bạn muốn commit cả patch notes và bộ docs EKS:

```text
Add EKS learning docs and patch notes
```

Nếu bạn muốn nhấn mạnh phần load balancer controller:

```text
Add EKS AWS CLI docs, ALB controller guide, and sample app
```

## 8. Nguồn thông tin của tài liệu EKS

Các docs EKS mà Codex đã soạn được dựa trên tài liệu AWS chính thức đã kiểm tra ngày `2026-04-19`, gồm các nguồn chính:

- https://docs.aws.amazon.com/eks/latest/userguide/what-is-eks.html
- https://docs.aws.amazon.com/eks/latest/userguide/create-cluster.html
- https://docs.aws.amazon.com/cli/latest/reference/eks/create-cluster.html
- https://docs.aws.amazon.com/cli/latest/reference/eks/create-nodegroup.html
- https://docs.aws.amazon.com/cli/latest/reference/eks/update-kubeconfig.html
- https://docs.aws.amazon.com/eks/latest/userguide/lbc-helm.html
- https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller.html
- https://docs.aws.amazon.com/eks/latest/userguide/alb-ingress.html
- https://docs.aws.amazon.com/eks/latest/userguide/network-load-balancing.html
- https://docs.aws.amazon.com/eks/latest/userguide/pod-identities.html

## 9. Kết luận

Nếu mục tiêu của bạn là tự push trong GitHub MCP:

- repo `terraform-starter` hiện đã có cả `PATCH_NOTES.md` và `docs/eks/`
- bạn có thể commit và push repo này để mang toàn bộ bộ tài liệu EKS lên GitHub private
