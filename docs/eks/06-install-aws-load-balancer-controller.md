# 06. Cài AWS Load Balancer Controller

Phần này là cầu nối giữa hạ tầng `EKS` bạn đã dựng bằng `aws cli` và tài nguyên `ALB` hoặc `NLB` được sinh từ Kubernetes.

Theo tài liệu AWS chính thức mình kiểm tra ngày `2026-04-19`, nếu bạn mới với EKS thì AWS khuyến nghị cài `AWS Load Balancer Controller` bằng `Helm`. Tài liệu AWS hiện tại cũng đang tham chiếu release controller `v2.14.1` và chart `1.14.0`, nhưng bạn nên kiểm tra lại bản mới nhất trước khi cài.

## 1. Controller này làm gì

Nó theo dõi các tài nguyên Kubernetes như:

- `Ingress`
- `Service type=LoadBalancer`

và tạo ra tài nguyên AWS tương ứng:

- `Application Load Balancer`
- `Network Load Balancer`
- target groups
- listeners

Nếu không có controller này, phần lớn luồng `Ingress -> ALB` của bạn sẽ không hoạt động đúng chuẩn trên EKS.

## 2. Prerequisites

Bạn nên hoàn tất trước:

- cluster `EKS` đã `ACTIVE`
- node group đã `ACTIVE`
- `kubectl get nodes` ra đủ node `Ready`
- public/private subnet đã tag đúng
- add-on `eks-pod-identity-agent` đã có nếu bạn chọn Pod Identity

Kiểm tra nhanh:

```bash
kubectl get nodes
kubectl get pods -A
aws eks list-addons --cluster-name "$CLUSTER_NAME" --region "$AWS_REGION"
```

## 3. Chọn cơ chế IAM cho controller

Có hai hướng phổ biến:

- `IRSA`
- `EKS Pod Identity`

Nếu mục tiêu là lab rõ ràng, dễ học bằng `aws cli`, mình khuyên dùng `EKS Pod Identity` vì:

- ít phụ thuộc vào OIDC provider hơn
- dễ mô hình hóa bằng EKS API
- cùng tư duy với phần access và pod permissions hiện đại của EKS

Nếu bạn đang theo tài liệu AWS gốc từng bước, bạn sẽ thấy trang Helm install chính thức vẫn mô tả luồng qua `eksctl` và service account role. Trong README này mình diễn giải lại theo hướng `aws cli + Helm`.

## 4. Tạo IAM policy cho controller

AWS đang duy trì file policy chuẩn cho controller trên GitHub của dự án.

Tải file policy:

```bash
curl -O https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.14.1/docs/install/iam_policy.json
```

Tạo IAM policy:

```bash
aws iam create-policy \
  --policy-name AWSLoadBalancerControllerIAMPolicy \
  --policy-document file://iam_policy.json
```

Lấy account ID và policy ARN:

```bash
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export LBC_POLICY_ARN="arn:aws:iam::${AWS_ACCOUNT_ID}:policy/AWSLoadBalancerControllerIAMPolicy"
```

Nếu policy đã tồn tại trong account, không tạo lại. Chỉ cần lấy ARN và dùng tiếp.

## 5. Tạo IAM role cho controller bằng Pod Identity

Tạo trust policy cho `pods.eks.amazonaws.com`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "pods.eks.amazonaws.com"
      },
      "Action": [
        "sts:AssumeRole",
        "sts:TagSession"
      ]
    }
  ]
}
```

Lưu vào file `lbc-pod-identity-trust.json`, sau đó:

```bash
aws iam create-role \
  --role-name AmazonEKSLoadBalancerControllerRole \
  --assume-role-policy-document file://lbc-pod-identity-trust.json

aws iam attach-role-policy \
  --role-name AmazonEKSLoadBalancerControllerRole \
  --policy-arn "$LBC_POLICY_ARN"

export LBC_ROLE_ARN=$(aws iam get-role \
  --role-name AmazonEKSLoadBalancerControllerRole \
  --query 'Role.Arn' \
  --output text)
```

## 6. Cài service account và gắn Pod Identity association

Tạo service account trước:

```bash
kubectl create serviceaccount aws-load-balancer-controller -n kube-system
```

Tạo Pod Identity association:

```bash
aws eks create-pod-identity-association \
  --cluster-name "$CLUSTER_NAME" \
  --namespace kube-system \
  --service-account aws-load-balancer-controller \
  --role-arn "$LBC_ROLE_ARN" \
  --region "$AWS_REGION"
```

Lưu ý:

- Pod Identity association có thể mất vài giây mới có hiệu lực
- cluster cần có add-on `eks-pod-identity-agent`

## 7. Cài controller bằng Helm

Thêm chart repo:

```bash
helm repo add eks https://aws.github.io/eks-charts
helm repo update eks
```

Cài controller:

```bash
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName="$CLUSTER_NAME" \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller
```

Trong một số môi trường bị hạn chế `IMDS`, hoặc khi cần rõ ràng hơn, bạn có thể set thêm:

```bash
helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName="$CLUSTER_NAME" \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set region="$AWS_REGION" \
  --set vpcId="$VPC_ID"
```

Nếu bạn muốn pin version chart theo tài liệu AWS tại thời điểm kiểm tra, có thể thêm:

```bash
--version 1.14.0
```

Nhưng chỉ nên pin khi bạn muốn môi trường reproducible. Nếu không, hãy kiểm tra chart version mới nhất trước.

## 8. Verify

Kiểm tra deployment:

```bash
kubectl get deployment -n kube-system aws-load-balancer-controller
kubectl rollout status deployment/aws-load-balancer-controller -n kube-system
```

Xem pod:

```bash
kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
```

Xem logs:

```bash
kubectl logs -n kube-system deployment/aws-load-balancer-controller
```

## 9. Kiểm tra controller đã có quyền AWS chưa

Khi bạn tạo `Ingress` hoặc `Service type=LoadBalancer`, controller phải tự gọi API AWS để tạo:

- load balancer
- target group
- listeners
- security group rules

Nếu thiếu quyền, logs thường có pattern như:

- `AccessDenied`
- `UnauthorizedOperation`
- lỗi reconcile lặp lại

## 10. Nâng cấp controller

Khi nâng cấp chart:

```bash
helm upgrade aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName="$CLUSTER_NAME" \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller
```

Theo tài liệu AWS hiện tại, `helm upgrade` không tự cài CRDs như `helm install`. Nếu chart mới yêu cầu CRD mới, bạn cần apply CRD thủ công.

## 11. Troubleshooting

### Controller pod không lên

Kiểm tra:

- service account có tồn tại không
- Pod Identity association đã tạo chưa
- add-on `eks-pod-identity-agent` có chạy không

### Controller chạy nhưng không tạo ALB/NLB

Kiểm tra:

- IAM policy đã attach đúng chưa
- subnet tag đúng chưa
- `Ingress` hoặc `Service` có annotation sai không

### `AccessDenied` trong logs

Hầu hết là:

- policy controller thiếu action
- dùng sai role
- Pod Identity association chưa có hiệu lực

## 12. Nguồn chính thức

- AWS Helm install guide: https://docs.aws.amazon.com/eks/latest/userguide/lbc-helm.html
- AWS overview page for controller: https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller.html
- EKS Pod Identity: https://docs.aws.amazon.com/eks/latest/userguide/pod-identities.html
- `create-pod-identity-association`: https://docs.aws.amazon.com/goto/aws-cli/eks-2017-11-01/CreatePodIdentityAssociation
