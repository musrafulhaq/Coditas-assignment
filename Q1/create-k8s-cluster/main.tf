provider "aws" {
  region = "us-east-1"
}


# Create IAM role has access to EKS
resource "aws_iam_role" "eks-iam-role" {
 name = "devopsthehardway-eks-iam-role"

 path = "/"

 assume_role_policy = <<EOF
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
EOF

}

# The two policies allow you to properly access EC2 instances (where the worker nodes run) and EKS.

resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
 policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
 role    = aws_iam_role.eks-iam-role.name
}
resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly-EKS" {
 policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
 role    = aws_iam_role.eks-iam-role.name
}


#  Once the policies are attached, create the EKS cluster.

resource "aws_eks_cluster" "devopsthehardway-eks" {
 name = "devopsthehardway-cluster"
 role_arn = aws_iam_role.eks-iam-role.arn

 vpc_config {
  subnet_ids = [aws_subnet.foo.id, aws_subnet.bar.id]
 }

 depends_on = [
  aws_iam_role.eks-iam-role,
 ]
}


# Set up an IAM role for the worker nodes.

resource "aws_iam_role" "workernodes" {
  name = "eks-node-group-example"

  assume_role_policy = jsonencode({
   Statement = [{
    Action = "sts:AssumeRole"
    Effect = "Allow"
    Principal = {
     Service = "ec2.amazonaws.com"
    }
   }]
   Version = "2012-10-17"
  })
}

 resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role    = aws_iam_role.workernodes.name
}

 resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role    = aws_iam_role.workernodes.name
}

 resource "aws_iam_role_policy_attachment" "EC2InstanceProfileForImageBuilderECRContainerBuilds" {
  policy_arn = "arn:aws:iam::aws:policy/EC2InstanceProfileForImageBuilderECRContainerBuilds"
  role    = aws_iam_role.workernodes.name
}

 resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role    = aws_iam_role.workernodes.name
}



 #The last bit of code is to create the worker nodes. For testing purposes, use just one worker node in the scaling_config configuration.

  resource "aws_eks_node_group" "worker-node-group" {
  cluster_name  = aws_eks_cluster.devopsthehardway-eks.name
  node_group_name = "devopsthehardway-workernodes"
  node_role_arn  = aws_iam_role.workernodes.arn
  subnet_ids   = [aws_subnet.foo.id, aws_subnet.bar.id]
  instance_types = ["t3.medium"]

  scaling_config {
   desired_size = 1
   max_size   = 1
   min_size   = 1
  }

  depends_on = [
   aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
   aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
   #aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
  ]
}


resource "aws_vpc" "my-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "Demo VPC"
  }
}


resource "aws_subnet" "foo" {
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1a"
  vpc_id            = aws_vpc.my-vpc.id

  tags = {
    Name = "tf-dbsubnet-test-1"
  }
}

resource "aws_subnet" "bar" {
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1b"
  vpc_id            = aws_vpc.my-vpc.id

  tags = {
    Name = "tf-dbsubnet-test-2"
  }
}
