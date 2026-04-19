# 03. Dựng EKS Bằng AWS CLI

Phần này là đường triển khai chính: từ networking và IAM đã có, bạn tạo cluster và node group bằng `aws cli`.

## 1. Prerequisites

Tối thiểu cần có:

- `aws` CLI v2
- `kubectl`
- `helm`
- `jq`
- AWS profile đã cấu hình

Ví dụ:

```bash
export AWS_PROFILE=eks-lab
export AWS_REGION=ap-southeast-1
export CLUSTER_NAME=eks-lab
export PROJECT=eks-lab
export K8S_VERSION=1.35
```

## 2. Security group strategy cho vòng đầu

Với lần dựng đầu tiên, nên để `EKS` tự tạo cluster security group mặc định.

Lý do:

- giảm rủi ro lỗi network rule khó debug
- tập trung vào luồng resource chính
- sau khi dựng thành công, mới quay lại hardening

## 3. Tạo cluster

```bash
aws eks create-cluster \
  --name "$CLUSTER_NAME" \
  --region "$AWS_REGION" \
  --role-arn "$EKS_CLUSTER_ROLE_ARN" \
  --kubernetes-version "$K8S_VERSION" \
  --resources-vpc-config subnetIds="$PRIVATE_SUBNET_1","$PRIVATE_SUBNET_2",endpointPublicAccess=true,endpointPrivateAccess=true
```

Theo dõi:

```bash
aws eks describe-cluster \
  --name "$CLUSTER_NAME" \
  --region "$AWS_REGION" \
  --query 'cluster.status' \
  --output text

aws eks wait cluster-active \
  --name "$CLUSTER_NAME" \
  --region "$AWS_REGION"
```

## 4. Tạo managed node group

```bash
aws eks create-nodegroup \
  --cluster-name "$CLUSTER_NAME" \
  --nodegroup-name "${CLUSTER_NAME}-ng-1" \
  --node-role "$EKS_NODE_ROLE_ARN" \
  --subnets "$PRIVATE_SUBNET_1" "$PRIVATE_SUBNET_2" \
  --scaling-config minSize=2,maxSize=4,desiredSize=2 \
  --instance-types t3.large \
  --capacity-type ON_DEMAND \
  --disk-size 30 \
  --region "$AWS_REGION"
```

Đợi `ACTIVE`:

```bash
aws eks wait nodegroup-active \
  --cluster-name "$CLUSTER_NAME" \
  --nodegroup-name "${CLUSTER_NAME}-ng-1" \
  --region "$AWS_REGION"
```

## 5. Cấu hình kubeconfig

```bash
aws eks update-kubeconfig \
  --name "$CLUSTER_NAME" \
  --region "$AWS_REGION"
```

Kiểm tra:

```bash
kubectl get nodes
kubectl get pods -A
```

## 6. Add-ons

Nên quản lý rõ các thành phần sau:

- `vpc-cni`
- `coredns`
- `kube-proxy`
- `eks-pod-identity-agent`

Ví dụ:

```bash
aws eks list-addons \
  --cluster-name "$CLUSTER_NAME" \
  --region "$AWS_REGION"

aws eks create-addon \
  --cluster-name "$CLUSTER_NAME" \
  --addon-name eks-pod-identity-agent \
  --region "$AWS_REGION"
```

## 7. App test nhanh

```bash
kubectl create deployment demo-nginx --image=nginx:stable
kubectl scale deployment demo-nginx --replicas=2
kubectl expose deployment demo-nginx --port=80 --target-port=80
kubectl get pods,svc
```

## 8. Checklist hoàn tất

- cluster `ACTIVE`
- node group `ACTIVE`
- node ở trạng thái `Ready`
- `coredns` chạy bình thường
- workload mẫu chạy được

## 9. Lỗi hay gặp

### Cluster không lên `ACTIVE`

Kiểm tra:

- cluster role
- subnet IDs
- region
- service quotas

### Node không `Ready`

Kiểm tra:

- node role
- NAT Gateway
- route table
- private subnet outbound

### `update-kubeconfig` chạy xong nhưng không truy cập được

Kiểm tra:

- IAM principal hiện tại
- `access entry`
- endpoint public/private access
