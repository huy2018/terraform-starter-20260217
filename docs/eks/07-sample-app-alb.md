# 07. Sample App Với ALB

Phần này giúp bạn kiểm tra end-to-end:

- cluster EKS chạy ổn
- `AWS Load Balancer Controller` hoạt động
- subnet tagging đúng
- `Ingress` có thể sinh `ALB`

Theo tài liệu AWS chính thức hiện tại, để tạo `ALB` bạn cần:

- có ít nhất `2` subnet ở `2` AZ khác nhau
- controller đã được cài
- nếu có nhiều subnet phù hợp trong cùng một AZ, controller sẽ chọn subnet có subnet ID đứng trước theo thứ tự từ điển nếu bạn không chỉ định subnet cụ thể

## 1. Kiến trúc test

```text
Client
  -> ALB
  -> Ingress
  -> Service
  -> Deployment
  -> Pods
```

## 2. Namespace

```bash
kubectl create namespace alb-demo
```

## 3. Deployment mẫu

Tạo file `alb-demo-deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: alb-demo
  namespace: alb-demo
spec:
  replicas: 2
  selector:
    matchLabels:
      app: alb-demo
  template:
    metadata:
      labels:
        app: alb-demo
    spec:
      containers:
      - name: nginx
        image: nginx:stable
        ports:
        - containerPort: 80
```

Apply:

```bash
kubectl apply -f alb-demo-deployment.yaml
kubectl get pods -n alb-demo -o wide
```

## 4. Service

Tạo file `alb-demo-service.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: alb-demo
  namespace: alb-demo
spec:
  selector:
    app: alb-demo
  ports:
  - port: 80
    targetPort: 80
  type: NodePort
```

Apply:

```bash
kubectl apply -f alb-demo-service.yaml
kubectl get svc -n alb-demo
```

Với `ALB` target type mặc định là `instance`, `Service` nên là `NodePort` hoặc `LoadBalancer`. Để routing trực tiếp tới pod, bạn có thể chuyển sang target type `ip`.

## 5. Ingress

Tạo file `alb-demo-ingress.yaml`:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: alb-demo
  namespace: alb-demo
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: instance
spec:
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: alb-demo
            port:
              number: 80
```

Apply:

```bash
kubectl apply -f alb-demo-ingress.yaml
kubectl get ingress -n alb-demo
kubectl describe ingress alb-demo -n alb-demo
```

## 6. Chờ ALB được tạo

Lệnh kiểm tra:

```bash
kubectl get ingress -n alb-demo -w
```

Khi thành công, trường `ADDRESS` sẽ có DNS name của `ALB`.

Bạn có thể test:

```bash
curl http://<ALB_DNS_NAME>
```

## 7. Biến thể target type `ip`

Nếu muốn route trực tiếp tới pod thay vì qua `NodePort`, đổi ingress annotation:

```yaml
alb.ingress.kubernetes.io/target-type: ip
```

Khi đó service có thể dùng `ClusterIP`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: alb-demo
  namespace: alb-demo
spec:
  selector:
    app: alb-demo
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
```

Mô hình `ip` thường tự nhiên hơn với Kubernetes hiện đại, đặc biệt khi bạn muốn traffic đi thẳng vào pod.

## 8. TLS và host-based routing

Khi đã test HTTP cơ bản xong, bạn có thể mở rộng:

- thêm `host`
- thêm certificate từ `ACM`
- thêm nhiều path hoặc nhiều host trong cùng ingress group

Ví dụ tư duy:

```text
api.example.com -> api-service
admin.example.com -> admin-service
```

## 9. Troubleshooting

### `Ingress` không có `ADDRESS`

Kiểm tra:

- controller có chạy không
- public subnet có tag `kubernetes.io/role/elb=1` không
- ingress annotation có đúng không

### `ALB` tạo ra nhưng vào không được

Kiểm tra:

- security group của ALB
- target group health check
- pod có thật sự `Ready` không
- service selector có match label của pod không

### `Target` trong target group bị unhealthy

Kiểm tra:

- service port đúng chưa
- pod có nghe ở `80` không
- health check path có phù hợp không

## 10. Teardown sample app

```bash
kubectl delete ingress alb-demo -n alb-demo
kubectl delete service alb-demo -n alb-demo
kubectl delete deployment alb-demo -n alb-demo
kubectl delete namespace alb-demo
```

Nên xóa `Ingress` trước để `ALB` bị dọn sớm.

## 11. Nguồn chính thức

- ALB with EKS: https://docs.aws.amazon.com/eks/latest/userguide/alb-ingress.html
- Load balancing best practices: https://docs.aws.amazon.com/eks/latest/best-practices/load-balancing.html
- Controller install with Helm: https://docs.aws.amazon.com/eks/latest/userguide/lbc-helm.html
