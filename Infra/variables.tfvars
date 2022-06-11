region          = "us-west-2"
environment     = "test"
name            = "test-cluster"
cluster_version = "1.21"
create_eks      = true
instance_types  = ["t3a.xlarge"]
users = [
  { groups = ["system:masters"], userarn = "arn:aws:iam::702231660698:user/ziad.hassan@magalix.com", username = "ziad.hassan@magalix.com" }
]