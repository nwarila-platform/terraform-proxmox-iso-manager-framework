# terraform_plan - generic Terraform plan-aware policy.
#
# This package consumes normalized `terraform show -json tfplan` output from
# tools/build_plan_input.py. It covers cloud-resource invariants that cannot be
# proven from static source alone.

package terraform_plan

import rego.v1

required_tags := ["owner", "environment", "managed_by"]

admin_ports := [22, 2379, 3306, 3389, 5432, 6379, 6443]

stateful_types := {
	"aws_db_instance",
	"aws_dynamodb_table",
	"aws_ebs_volume",
	"aws_efs_file_system",
	"aws_elasticache_cluster",
	"aws_elasticache_replication_group",
	"aws_rds_cluster",
	"aws_s3_bucket",
}

tag_exempt_types := {
	"aws_iam_policy",
	"aws_iam_policy_document",
	"aws_iam_role_policy",
	"aws_iam_role_policy_attachment",
	"aws_s3_bucket_server_side_encryption_configuration",
	"aws_security_group_rule",
}

taggable_aws_resource(resource) if {
	startswith(resource.type, "aws_")
	not tag_exempt_types[resource.type]
}

has_wildcard(value) if {
	value == "*"
}

has_wildcard(value) if {
	is_array(value)
	value[_] == "*"
}

statement_list(policy) := statements if {
	raw := object.get(policy, "Statement", [])
	is_array(raw)
	statements := raw
}

statement_list(policy) := [raw] if {
	raw := object.get(policy, "Statement", {})
	is_object(raw)
}

s3_bucket_name(resource) := name if {
	name := object.get(resource.values, "bucket", "")
	name != ""
}

s3_bucket_name(resource) := resource.name if {
	object.get(resource.values, "bucket", "") == ""
}

has_inline_sse(resource) if {
	config := object.get(resource.values, "server_side_encryption_configuration", null)
	config != null
}

reference_matches_address(ref, address) if {
	ref == address
}

reference_matches_address(ref, address) if {
	startswith(ref, sprintf("%s.", [address]))
}

reference_matches_address(ref, address) if {
	base := split(address, "[")[0]
	ref == base
}

reference_matches_address(ref, address) if {
	base := split(address, "[")[0]
	startswith(ref, sprintf("%s.", [base]))
}

config_references_bucket(config, resource) if {
	refs := object.get(object.get(config, "references", {}), "bucket", [])
	ref := refs[_]
	reference_matches_address(ref, resource.address)
}

has_sse_config(resource) if {
	config := input.resources[_]
	config.type == "aws_s3_bucket_server_side_encryption_configuration"
	config_references_bucket(config, resource)
}

has_sse_config(resource) if {
	bucket := s3_bucket_name(resource)
	config := input.resources[_]
	config.type == "aws_s3_bucket_server_side_encryption_configuration"
	object.get(config.values, "bucket", "") == bucket
}

cidr_open_to_world(rule) if {
	cidrs := object.get(rule, "cidr_blocks", [])
	cidrs[_] == "0.0.0.0/0"
}

cidr_open_to_world(rule) if {
	cidrs := object.get(rule, "ipv6_cidr_blocks", [])
	cidrs[_] == "::/0"
}

rule_exposes_port(rule, port) if {
	from := object.get(rule, "from_port", null)
	to := object.get(rule, "to_port", null)
	is_number(from)
	is_number(to)
	from <= port
	to >= port
}

prevent_destroy_enabled(resource) if {
	lifecycle := object.get(resource, "lifecycle", {})
	object.get(lifecycle, "prevent_destroy", false) == true
}

missing_required_tags(resource) := missing if {
	tags := object.get(resource.values, "tags", {})
	missing := {tag |
		tag := required_tags[_]
		object.get(tags, tag, "") == ""
	}
}

deny contains msg if {
	resource := input.resources[_]
	resource.type == "aws_s3_bucket"
	not has_inline_sse(resource)
	not has_sse_config(resource)
	msg := sprintf("%s must have server-side encryption configuration", [resource.address])
}

deny contains msg if {
	resource := input.resources[_]
	resource.type == "aws_iam_policy"
	raw := object.get(resource.values, "policy", "")
	is_string(raw)
	policy := json.unmarshal(raw)
	statement := statement_list(policy)[_]
	has_wildcard(object.get(statement, "Action", null))
	has_wildcard(object.get(statement, "Resource", null))
	msg := sprintf("%s must not allow Action \"*\" on Resource \"*\"", [resource.address])
}

deny contains msg if {
	resource := input.resources[_]
	resource.type == "aws_security_group"
	rule := object.get(resource.values, "ingress", [])[_]
	cidr_open_to_world(rule)
	port := admin_ports[_]
	rule_exposes_port(rule, port)
	msg := sprintf("%s must not expose admin port %d to the world", [resource.address, port])
}

deny contains msg if {
	resource := input.resources[_]
	resource.type == "aws_security_group_rule"
	object.get(resource.values, "type", "") == "ingress"
	cidr_open_to_world(resource.values)
	port := admin_ports[_]
	rule_exposes_port(resource.values, port)
	msg := sprintf("%s must not expose admin port %d to the world", [resource.address, port])
}

deny contains msg if {
	resource := input.resources[_]
	stateful_types[resource.type]
	not prevent_destroy_enabled(resource)
	msg := sprintf("%s must set lifecycle.prevent_destroy = true", [resource.address])
}

deny contains msg if {
	resource := input.resources[_]
	taggable_aws_resource(resource)
	missing := missing_required_tags(resource)
	count(missing) > 0
	msg := sprintf("%s missing required tags: %v", [resource.address, sort(missing)])
}
