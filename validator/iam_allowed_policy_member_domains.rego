#
# Copyright 2019 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

package templates.gcp.GCPIAMAllowedPolicyMemberDomainsConstraintV2

import data.validator.gcp.lib as lib

deny[{
	"msg": message,
	"details": metadata,
}] {
	constraint := input.constraint
	lib.get_constraint_params(constraint, params)
	asset := input.asset
	unique_members := {m | m = asset.iam_policy.bindings[_].members[_]}
	member_type_allowlist := lib.get_default(params, "member_type_allowlist", ["projectOwner", "projectEditor", "projectViewer"])

	members_to_check := [m | m = unique_members[_]; not starts_with_allowlisted_type(member_type_allowlist, m)]
	member := members_to_check[_]
	allow_sub_domains := lib.get_default(params, "allow_sub_domains", true)
	no_match(allow_sub_domains, params.domains, member)

	message := sprintf("IAM policy for %v contains member from unexpected domain: %v", [asset.name, member])

	metadata := {"resource": asset.name, "member": member}
}

no_match(allow_sub_domains, domains, member) {
	allow_sub_domains == true
	matched_domains := [m | m = member; re_match(sprintf("[:@.]%v$", [domains[_]]), member)]
	count(matched_domains) == 0
}

no_match(allow_sub_domains, domains, member) {
	allow_sub_domains == false
	matched_domains := [m | m = member; re_match(sprintf("[:@]%v$", [domains[_]]), member)]
	count(matched_domains) == 0
}

starts_with_allowlisted_type(allowlist, member) {
	member_type := allowlist[_]
	startswith(member, sprintf("%v:", [member_type]))
}
