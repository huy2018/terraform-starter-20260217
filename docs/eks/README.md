# EKS Learning Docs

Bộ tài liệu này tách riêng từ README tổng để bạn học theo đúng thứ tự triển khai `Amazon EKS` bằng `aws cli`.

Thứ tự đọc khuyến nghị:

1. [01-networking.md](/home/huymd/huymd-test/docs/01-networking.md)
2. [02-iam-and-access.md](/home/huymd/huymd-test/docs/02-iam-and-access.md)
3. [03-eks-cluster-aws-cli.md](/home/huymd/huymd-test/docs/03-eks-cluster-aws-cli.md)
4. [04-elb-and-ingress.md](/home/huymd/huymd-test/docs/04-elb-and-ingress.md)
5. [05-day2-and-teardown.md](/home/huymd/huymd-test/docs/05-day2-and-teardown.md)
6. [06-install-aws-load-balancer-controller.md](/home/huymd/huymd-test/docs/06-install-aws-load-balancer-controller.md)
7. [07-sample-app-alb.md](/home/huymd/huymd-test/docs/07-sample-app-alb.md)

Nếu bạn muốn đọc bản đầy đủ một file duy nhất, xem [README.md](/home/huymd/huymd-test/README.md).

## Cách dùng bộ docs này

- `01-networking`: dựng nền VPC cho EKS
- `02-iam-and-access`: hiểu role, policy, access entry, pod identity
- `03-eks-cluster-aws-cli`: tạo cluster và managed node group bằng `aws cli`
- `04-elb-and-ingress`: kết nối EKS với `ALB` và `NLB`
- `05-day2-and-teardown`: vận hành, kiểm tra, xử lý lỗi, chi phí và teardown
- `06-install-aws-load-balancer-controller`: cài `AWS Load Balancer Controller` bằng Helm
- `07-sample-app-alb`: deploy app mẫu và expose qua `ALB`

## Mục tiêu học

Sau khi đi hết bộ docs, bạn nên làm được:

- tự dựng một cụm EKS nhỏ bằng `aws cli`
- phân biệt rõ phần AWS resources và phần Kubernetes resources
- hiểu vì sao subnet tag, IAM role và NAT Gateway ảnh hưởng trực tiếp đến EKS
- expose app bằng `ALB` hoặc `NLB`
- biết khi nào nên chuyển từ CLI sang Terraform
- cài được `AWS Load Balancer Controller` theo cách đủ dùng cho môi trường lab
- deploy được một app mẫu với `Ingress` sinh `ALB`
