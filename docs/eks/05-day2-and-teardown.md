# 05. Day-2 Operations Và Teardown

Dựng được cluster mới chỉ là ngày đầu. Phần này là thứ giúp bạn vận hành được cluster sau khi đã có EKS.

## 1. Checklist sau khi dựng xong

- `aws eks describe-cluster` trả về `ACTIVE`
- `aws eks describe-nodegroup` trả về `ACTIVE`
- `kubectl get nodes` thấy đủ node `Ready`
- `kubectl get pods -A` không có pod hệ thống lỗi kéo dài
- app mẫu chạy được
- `ALB` hoặc `NLB` được tạo đúng

## 2. Observability

Bạn nên học tiếp:

- `CloudWatch`
- `Container Insights`
- log ứng dụng
- log control plane

Nếu không có observability, bạn gần như mù khi node hoặc ingress lỗi.

## 3. Upgrade

Phải nắm rõ:

- upgrade control plane
- upgrade node group
- upgrade add-ons
- compatibility giữa version Kubernetes và add-ons

Nguyên tắc:

- không upgrade tất cả cùng lúc
- kiểm tra từng lớp theo thứ tự

## 4. Cost awareness

Các thứ dễ tốn tiền:

- `NAT Gateway`
- `EC2` node
- `EBS`
- `ALB` hoặc `NLB`
- `CloudWatch Logs`

Nếu chỉ học lab:

- dùng `1` NAT Gateway
- không overprovision node
- teardown ngay khi xong

## 5. Troubleshooting ưu tiên

### Node không join

Nhìn theo thứ tự:

1. IAM node role
2. NAT Gateway
3. route table
4. subnet placement
5. bootstrap và logs của node

### Không truy cập cluster bằng kubectl

Nhìn theo thứ tự:

1. kubeconfig
2. IAM principal hiện tại
3. access entry
4. endpoint public/private access

### Load balancer không tạo

Nhìn theo thứ tự:

1. controller
2. subnet tag
3. annotations
4. IAM permissions

## 6. Teardown an toàn

Nên xóa theo thứ tự từ trên xuống dưới:

1. xóa app
2. xóa `Ingress` và `Service type=LoadBalancer`
3. xóa controller nếu cần
4. xóa node group
5. xóa cluster
6. xóa NAT Gateway
7. release EIP
8. xóa route tables phụ
9. detach và xóa `IGW`
10. xóa subnets
11. xóa VPC
12. xóa IAM roles dùng cho lab

Ví dụ:

```bash
aws eks delete-nodegroup \
  --cluster-name "$CLUSTER_NAME" \
  --nodegroup-name "${CLUSTER_NAME}-ng-1" \
  --region "$AWS_REGION"

aws eks wait nodegroup-deleted \
  --cluster-name "$CLUSTER_NAME" \
  --nodegroup-name "${CLUSTER_NAME}-ng-1" \
  --region "$AWS_REGION"

aws eks delete-cluster \
  --name "$CLUSTER_NAME" \
  --region "$AWS_REGION"

aws eks wait cluster-deleted \
  --name "$CLUSTER_NAME" \
  --region "$AWS_REGION"
```

## 7. Khi nào chuyển sang Terraform

Chuyển khi bạn đã:

- dựng tay được ít nhất một lần
- hiểu dependency giữa networking, IAM và EKS
- muốn tái sử dụng cho `dev/staging/prod`

Nguyên tắc tốt:

- học cơ chế bằng `aws cli`
- đóng gói lại bằng `Terraform`

Đó là lúc IaC thực sự có giá trị, thay vì chỉ là copy module của người khác.
