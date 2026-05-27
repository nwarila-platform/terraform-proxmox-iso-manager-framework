package terraform_plan_test

import data.terraform_plan
import rego.v1

safe_input := {
	"resources": [
		{
			"address": "aws_s3_bucket.logs",
			"type": "aws_s3_bucket",
			"name": "logs",
			"lifecycle": {"prevent_destroy": true},
			"values": {
				"bucket": "logs",
				"tags": {"owner": "platform", "environment": "prod", "managed_by": "terraform"},
			},
		},
		{
			"address": "aws_s3_bucket_server_side_encryption_configuration.logs",
			"type": "aws_s3_bucket_server_side_encryption_configuration",
			"values": {"bucket": "logs"},
		},
		{
			"address": "aws_security_group.web",
			"type": "aws_security_group",
			"values": {
				"ingress": [{"from_port": 443, "to_port": 443, "cidr_blocks": ["0.0.0.0/0"]}],
				"tags": {"owner": "platform", "environment": "prod", "managed_by": "terraform"},
			},
		},
	],
}

test_safe_plan_allowed if {
	count(terraform_plan.deny) == 0 with input as safe_input
}

test_s3_bucket_without_sse_denied if {
	denials := terraform_plan.deny with input as {
		"resources": [{
			"address": "aws_s3_bucket.bad",
			"type": "aws_s3_bucket",
			"name": "bad",
			"lifecycle": {"prevent_destroy": true},
			"values": {
				"bucket": "bad",
				"tags": {"owner": "platform", "environment": "prod", "managed_by": "terraform"},
			},
		}],
	}
	count(denials) >= 1
}

test_s3_bucket_sse_reference_graph_allowed if {
	denials := terraform_plan.deny with input as {
		"resources": [
			{
				"address": "aws_s3_bucket.logs",
				"type": "aws_s3_bucket",
				"name": "logs",
				"lifecycle": {"prevent_destroy": true},
				"values": {
					"bucket_prefix": "logs-",
					"tags": {"owner": "platform", "environment": "prod", "managed_by": "terraform"},
				},
			},
			{
				"address": "aws_s3_bucket_server_side_encryption_configuration.logs",
				"type": "aws_s3_bucket_server_side_encryption_configuration",
				"references": {"bucket": ["aws_s3_bucket.logs.id"]},
				"values": {"bucket": "known-after-apply"},
			},
		],
	}
	count(denials) == 0
}

test_iam_policy_wildcard_admin_denied if {
	denials := terraform_plan.deny with input as {
		"resources": [{
			"address": "aws_iam_policy.admin",
			"type": "aws_iam_policy",
			"values": {"policy": `{"Statement":[{"Effect":"Allow","Action":"*","Resource":"*"}]}`},
		}],
	}
	count(denials) >= 1
}

test_world_open_ssh_denied if {
	denials := terraform_plan.deny with input as {
		"resources": [{
			"address": "aws_security_group.admin",
			"type": "aws_security_group",
			"values": {
				"ingress": [{"from_port": 22, "to_port": 22, "cidr_blocks": ["0.0.0.0/0"]}],
				"tags": {"owner": "platform", "environment": "prod", "managed_by": "terraform"},
			},
		}],
	}
	count(denials) >= 1
}

test_stateful_without_prevent_destroy_denied if {
	denials := terraform_plan.deny with input as {
		"resources": [{
			"address": "aws_db_instance.prod",
			"type": "aws_db_instance",
			"values": {"tags": {"owner": "platform", "environment": "prod", "managed_by": "terraform"}},
		}],
	}
	count(denials) >= 1
}

test_missing_required_tags_denied if {
	denials := terraform_plan.deny with input as {
		"resources": [{
			"address": "aws_instance.web",
			"type": "aws_instance",
			"values": {"tags": {"owner": "platform"}},
		}],
	}
	count(denials) >= 1
}
