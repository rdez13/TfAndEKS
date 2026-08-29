# EKS cluster and its managed node group.
#
# Nodes run in the private subnets and reach the internet through the NAT gateway.
# The API endpoint is public so kubectl works from a laptop without a bastion or VPN —
# fine for a learning cluster, not what you would do in production.

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = var.cluster_name
  kubernetes_version = var.kubernetes_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  endpoint_public_access = true

  # KMS enforces a waiting period before a key is actually deleted, and the module
  # defaults to 30 days. Since this cluster is destroyed and rebuilt often, each cycle
  # would leave another key billing ~$1/month for a month. 7 is the minimum allowed.
  kms_key_deletion_window_in_days = 7

  # Grants the identity running Terraform (tf-admin) cluster-admin via an EKS access
  # entry. Without this you get a cluster you cannot kubectl into — access entries have
  # replaced the old aws-auth ConfigMap, and forgetting this is the classic way to lock
  # yourself out.
  enable_cluster_creator_admin_permissions = true

  # aws-ebs-csi-driver is deliberately omitted: nothing in this project uses persistent
  # volumes, and it would need its own IRSA role and the pod identity agent.
  addons = {
    vpc-cni = {
      before_compute = true # must exist before nodes join, or pods get no IPs
    }
    coredns    = {}
    kube-proxy = {}
  }

  eks_managed_node_groups = {
    default = {
      instance_types = [var.node_instance_type]

      min_size     = var.node_min_size
      max_size     = var.node_max_size
      desired_size = var.node_desired_size
    }
  }

  tags = {
    Component = "eks"
  }
}
