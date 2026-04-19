# 02. IAM Và Access Cho EKS

Phần này quyết định cluster có tạo được không, node có join được không, và người dùng có vào được cluster không.

## 1. Ba lớp quyền cần phân biệt

### Cluster role

IAM role để `EKS control plane` dùng khi AWS quản lý cluster.

### Node role

IAM role để `EC2 worker node`:

- join cluster
- pull image từ `ECR`
- dùng `VPC CNI`

### Pod role

IAM role dành cho ứng dụng chạy trong pod, nên đi theo `EKS Pod Identity`.

Nếu bạn trộn 3 lớp này vào một role thì ban đầu có thể chạy được, nhưng đó là thiết kế sai.

## 2. Cluster role

Trust policy:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

Policy cơ bản:

- `AmazonEKSClusterPolicy`

## 3. Node role

Trust policy:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

Policy cơ bản nên có:

- `AmazonEKSWorkerNodePolicy`
- `AmazonEC2ContainerRegistryPullOnly`
- `AmazonEKS_CNI_Policy`

## 4. Access vào cluster

EKS hiện đại ưu tiên `access entry` thay vì phụ thuộc hoàn toàn vào `aws-auth ConfigMap`.

Điều này giúp:

- quản lý quyền nhất quán hơn phía AWS
- giảm phụ thuộc vào thao tác thủ công trong cluster
- audit dễ hơn

Ví dụ:

```bash
aws eks create-access-entry \
  --cluster-name "$CLUSTER_NAME" \
  --principal-arn "$ADMIN_PRINCIPAL_ARN" \
  --region "$AWS_REGION"

aws eks associate-access-policy \
  --cluster-name "$CLUSTER_NAME" \
  --principal-arn "$ADMIN_PRINCIPAL_ARN" \
  --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy \
  --access-scope type=cluster \
  --region "$AWS_REGION"
```

## 5. Pod Identity

Khi app trong pod cần gọi:

- `S3`
- `SQS`
- `DynamoDB`
- `Secrets Manager`

thì không nên nhét access key vào `Secret`.

Nên dùng:

- `EKS Pod Identity`

Lợi ích:

- không hardcode credential
- tách biệt quyền của pod với quyền của node
- audit và rotate dễ hơn

## 6. Cách nghĩ đúng

- cluster role: cho control plane
- node role: cho EC2 node
- pod role: cho ứng dụng
- human/admin role: cho người vận hành vào cluster

Mỗi loại là một responsibility riêng.

## 7. Checklist IAM

- cluster role trust đúng `eks.amazonaws.com`
- node role trust đúng `ec2.amazonaws.com`
- node role có đủ 3 policy cơ bản
- admin principal có `access entry`
- pod dùng Pod Identity thay vì access key tĩnh

## 8. Lỗi hay gặp

### Cluster tạo lỗi ngay từ đầu

Thường do:

- role ARN sai
- trust policy sai
- principal tạo cluster không có đủ quyền IAM/EKS

### Node group `CREATE_FAILED`

Thường do:

- node role thiếu policy
- private subnet không có outbound
- bootstrap không tải được thành phần cần thiết

### `kubectl` bị `Unauthorized`

Thường do:

- principal hiện tại chưa có `access entry`
- kubeconfig đang trỏ đúng cluster nhưng IAM principal không được map quyền
