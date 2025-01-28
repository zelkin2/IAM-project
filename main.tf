provider "aws" {
  region = "eu-west-2"
}

# variable allows to create several users at the same time
variable "username" {
  type    = list(string)
  default = ["developer-1", "developer-2", "operations-1", "operations-2", "analyst-1", "analyst-2", "finance-1"]
}
resource "aws_iam_user" "userlist" {
  count = length(var.username)               # this meta argument with Lenght function is going to return the count of the elements mention on the username list. 
  name  = element(var.username, count.index) # elements retries a single element for a list, the list in this case is var.username and the index counts, as the index is the variable count it will return the values specified in the count not a single one
}


# password policy
resource "aws_iam_account_password_policy" "password_policy" {
  minimum_password_length = 12
  require_numbers = true
  require_symbols = true
  require_uppercase_characters = true
  require_lowercase_characters = true
  allow_users_to_change_password = true
  max_password_age = 120
  password_reuse_prevention = 3
}

# request users to reset passwords

resource "aws_iam_user_login_profile" "userlist"{
  count = length(var.username) 
  user = aws_iam_user.userlist[count.index].name # guarantees the users are created first before applying the policy by referencing the script that creates the users wi the variable
  password_reset_required = true          
}


# create IAM groups

resource "aws_iam_group" "developer"{
  name = "Developers"
}
resource "aws_iam_group" "operations" {
  name = "operations"
}

resource "aws_iam_group" "finance" {
  name = "finance"
}

resource "aws_iam_group" "analyst" {
  name = "analysts"
}

# add users to the correct groups
resource "aws_iam_group_membership" "developer_membership" {
  name  = "developer-group-membership"
  group = aws_iam_group.developer.name # developer refers to the terraform identifier, if identifier is changed developer must be amended to the new name 
  users = [
    "developer-1",
    "developer-2",
  ]
}


resource "aws_iam_group_membership" "operations_memebership"{
  name = "operations-group-memebership"
  group = aws_iam_group.operations.name
  users = [
    "Operations-1",
    "operations-2",
  ]
}

resource "aws_iam_group_membership" "analyst_membership" {
  name  = "analyst-group-membership"
  group = aws_iam_group.analyst.name
  users = [
    "analyst-1",
    "analyst-2",
  ]
}

resource "aws_iam_group_membership" "finance_membership" {
  name  = "finance-group-membership"
  group = aws_iam_group.finance.name
  users = [
    "finance-1",
  ]
}

# assign policies to IAM groups

resource "aws_iam_group_policy_attachment" "developer"{
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEC2FullAccess",
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",
    "arn:aws:iam::aws:policy/CloudWatchEventsFullAccess",
  ])
  group = aws_iam_group.developer.name
  policy_arn = each.value
}

resource "aws_iam_group_policy_attachment" "operations"{
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEC2FullAccess",
    "arn:aws:iam::aws:policy/AmazonRDSFullAccess",
    "arn:aws:iam::aws:policy/CloudWatchEventsFullAccess",
    "arn:aws:iam::aws:policy/AmazonSSMFullAccess",
  ])
   group = aws_iam_group.operations.name
   policy_arn = each.value
}

resource "aws_iam_group_policy_attachment" "finance"{
  for_each = toset([
    "arn:aws:iam::aws:policy/job-function/Billing",
    "arn:aws:iam::aws:policy/ReadOnlyAccess",
  ])
 group = aws_iam_group.finance.name
 policy_arn = each.value
}


resource "aws_iam_group_policy_attachment" "analyst"{
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonRDSReadOnlyAccess",
    "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess",
  ])
  group = aws_iam_group.analyst.name
  policy_arn = each.value
}
 
 # create json document to deny access if MFA is not enabled

 data "aws_iam_policy_document" "require_mfa"{
  statement {
    effect = "Deny"
    actions = ["*"]
    resources = ["*"]
    condition {
      test = "Bool"
      variable = "aws:MultiFactorAuthPresent"
      values = ["false"]
    }
  }
 }

 # Create a policy from that document
resource "aws_iam_policy" "mfa_policy" {
  name   = "RequireMFAPolicy"
  policy = data.aws_iam_policy_document.require_mfa.json
}

# Attach the policy to the users
resource "aws_iam_user_policy_attachment" "developer_mfa" {
  for_each   = toset(var.username)
  user       = each.key
  policy_arn = aws_iam_policy.mfa_policy.arn
}
