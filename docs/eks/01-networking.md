# 01. Networking Cho EKS

Phần này là nền tảng quan trọng nhất. Nếu networking sai, `EKS` thường lỗi ở các chỗ sau:

- cluster tạo xong nhưng node không join
- pod không pull được image
- service không ra internet
- `ALB` hoặc `NLB` không được tạo đúng subnet

## 1. Mục tiêu

Bạn cần dựng được:

- `1` `VPC`
- `2` public subnets ở `2` AZ
- `2` private subnets ở `2` AZ
- `1` `Internet Gateway`
- `1` `NAT Gateway`
- route tables public/private
- subnet tags cho `ELB`

## 2. Thiết kế khuyến nghị

```text
VPC 10.0.0.0/16
|
+-- Public subnet AZ1  10.0.0.0/24
+-- Public subnet AZ2  10.0.1.0/24
|    -> ALB / internet-facing NLB
|
+-- Private subnet AZ1 10.0.10.0/24
+-- Private subnet AZ2 10.0.11.0/24
     -> EKS worker nodes
     -> Pods
```

Thiết kế này hợp lý cho vòng đầu vì:

- node không phơi ra internet trực tiếp
- load balancer public nằm đúng chỗ
- outbound từ node đi qua NAT Gateway

## 3. Các khái niệm phải nắm

### VPC

Mạng logic tổng của hệ thống.

### Subnet

Phân vùng của VPC trong từng `Availability Zone`.

### Route Table

Xác định traffic đi đâu.

### Internet Gateway

Giúp public subnet truy cập internet.

### NAT Gateway

Giúp private subnet đi ra internet mà vẫn không public IP trực tiếp cho node.

### Security Group

Firewall stateful áp vào ENI, EC2, load balancer và một số resource khác.

## 4. Quy ước subnet cho EKS

Trong mô hình chuẩn:

- `public subnet`: dành cho internet-facing load balancer
- `private subnet`: dành cho worker node

Tag cần nhớ:

- `kubernetes.io/role/elb=1` cho public subnet
- `kubernetes.io/role/internal-elb=1` cho private subnet

Nếu dùng nhiều cluster chung VPC, cân nhắc thêm tag theo cluster để subnet discovery rõ hơn.

## 5. Luồng traffic thực tế

### Truy cập từ internet vào app

```text
Client
  -> ALB/NLB trong public subnets
  -> target group
  -> pod hoặc node trong private subnets
```

### Node hoặc pod đi ra internet

```text
Private subnet
  -> route 0.0.0.0/0
  -> NAT Gateway ở public subnet
  -> Internet Gateway
  -> Internet
```

Nếu không có NAT hoặc route sai:

- node không pull image từ `ECR`
- bootstrap node có thể lỗi
- add-ons có thể không chạy ổn

## 6. Lệnh AWS CLI mẫu

### Chọn AZ

```bash
aws ec2 describe-availability-zones \
  --region "$AWS_REGION" \
  --filters Name=state,Values=available \
  --query 'AvailabilityZones[0:2].[ZoneName,ZoneId]' \
  --output table
```

### Tạo VPC

```bash
export VPC_ID=$(aws ec2 create-vpc \
  --cidr-block 10.0.0.0/16 \
  --region "$AWS_REGION" \
  --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=${PROJECT}-vpc},{Key=Project,Value=${PROJECT}}]" \
  --query 'Vpc.VpcId' \
  --output text)

aws ec2 modify-vpc-attribute --vpc-id "$VPC_ID" --enable-dns-support
aws ec2 modify-vpc-attribute --vpc-id "$VPC_ID" --enable-dns-hostnames
```

### Tạo subnet

```bash
export PUBLIC_SUBNET_1=$(aws ec2 create-subnet \
  --vpc-id "$VPC_ID" \
  --cidr-block 10.0.0.0/24 \
  --availability-zone "$AZ1" \
  --query 'Subnet.SubnetId' \
  --output text)

export PUBLIC_SUBNET_2=$(aws ec2 create-subnet \
  --vpc-id "$VPC_ID" \
  --cidr-block 10.0.1.0/24 \
  --availability-zone "$AZ2" \
  --query 'Subnet.SubnetId' \
  --output text)

export PRIVATE_SUBNET_1=$(aws ec2 create-subnet \
  --vpc-id "$VPC_ID" \
  --cidr-block 10.0.10.0/24 \
  --availability-zone "$AZ1" \
  --query 'Subnet.SubnetId' \
  --output text)

export PRIVATE_SUBNET_2=$(aws ec2 create-subnet \
  --vpc-id "$VPC_ID" \
  --cidr-block 10.0.11.0/24 \
  --availability-zone "$AZ2" \
  --query 'Subnet.SubnetId' \
  --output text)
```

### Tạo IGW, NAT và route table

```bash
export IGW_ID=$(aws ec2 create-internet-gateway \
  --query 'InternetGateway.InternetGatewayId' \
  --output text)

aws ec2 attach-internet-gateway \
  --internet-gateway-id "$IGW_ID" \
  --vpc-id "$VPC_ID"

export EIP_ALLOC_ID=$(aws ec2 allocate-address --domain vpc --query 'AllocationId' --output text)

export NAT_GW_ID=$(aws ec2 create-nat-gateway \
  --subnet-id "$PUBLIC_SUBNET_1" \
  --allocation-id "$EIP_ALLOC_ID" \
  --query 'NatGateway.NatGatewayId' \
  --output text)

aws ec2 wait nat-gateway-available --nat-gateway-ids "$NAT_GW_ID"
```

## 7. Checklist trước khi sang EKS

- VPC có DNS support và DNS hostnames
- public subnet có route ra `IGW`
- private subnet có route ra `NAT Gateway`
- public subnet tag `elb`
- private subnet tag `internal-elb`
- subnet ở ít nhất `2` AZ

## 8. Các lỗi hay gặp

### Node không ra internet

Thường do:

- private subnet thiếu route `0.0.0.0/0`
- NAT Gateway chưa `available`
- dùng sai route table

### ALB không xuất hiện

Thường do:

- public subnet chưa gắn tag `kubernetes.io/role/elb=1`
- controller không tìm thấy subnet phù hợp

### Đặt node vào public subnet cho dễ

Làm lab thì được, nhưng không phải hướng nên học lâu dài.
