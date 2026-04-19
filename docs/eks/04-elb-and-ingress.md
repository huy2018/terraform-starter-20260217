# 04. ELB, Ingress Và Service LoadBalancer

Phần này giúp bạn nối workload trong EKS ra ngoài bằng load balancer của AWS.

## 1. Hai mẫu chính

### Ingress -> ALB

Phù hợp khi:

- app là HTTP/HTTPS
- cần host-based routing
- cần path-based routing
- nhiều service dùng chung một load balancer

### Service type=LoadBalancer -> NLB

Phù hợp khi:

- service là TCP/UDP
- không cần L7 routing
- muốn mô hình gần với network service hơn

## 2. Thành phần bắt buộc

Để Kubernetes resources tạo được `ALB` hoặc `NLB`, bạn thường cần:

- `AWS Load Balancer Controller`

Điểm quan trọng:

- `aws cli` dựng được hạ tầng AWS
- nhưng controller là thành phần chạy trong cluster, nên cần `Helm` hoặc manifest

## 3. Phụ thuộc cần đúng trước khi cài controller

- subnet tag đúng
- cluster đang hoạt động
- node group chạy ổn
- IAM cho controller hoặc Pod Identity đã chuẩn bị

## 4. Cách nghĩ về subnet placement

### Internet-facing ALB/NLB

Thường nằm ở public subnet.

### Internal load balancer

Thường nằm ở private subnet.

Nếu subnet tag sai, controller có thể:

- không tìm thấy subnet
- tạo load balancer sai chỗ
- báo lỗi reconcile

## 5. Khi nào chọn ALB

Chọn `ALB` nếu bạn có:

- nhiều API hoặc web app
- routing theo domain hoặc path
- nhu cầu terminate TLS ở layer 7

Ví dụ:

```text
api.example.com -> api-service
admin.example.com -> admin-service
/v1 -> versioned-api
```

## 6. Khi nào chọn NLB

Chọn `NLB` nếu bạn có:

- TCP service
- dịch vụ không thuần HTTP
- yêu cầu throughput L4

## 7. Test workload

Sau khi controller chạy, bạn có thể thử:

- tạo `Ingress` để sinh `ALB`
- hoặc đổi service sang `type: LoadBalancer` để sinh `NLB`

Kiểm tra:

```bash
kubectl get ingress
kubectl get svc
kubectl describe ingress
kubectl describe svc
```

## 8. Lỗi hay gặp

### Ingress có nhưng không sinh ALB

Kiểm tra:

- controller đã chạy chưa
- subnet tag đúng chưa
- class hoặc annotation có đúng không
- controller có quyền AWS chưa

### Service LoadBalancer không sinh NLB

Kiểm tra:

- service type đúng chưa
- controller log
- subnet discovery

## 9. Kết luận

Nếu workload của bạn là web/API thì hầu hết thời gian bạn sẽ dùng:

- `Ingress`
- `AWS Load Balancer Controller`
- `ALB`

Nếu workload là TCP service, mới nghiêng mạnh hơn về:

- `Service type=LoadBalancer`
- `NLB`
