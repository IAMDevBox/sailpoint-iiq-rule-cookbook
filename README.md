# SailPoint IdentityIQ Rule Cookbook

Working BeanShell rule templates for the IdentityIQ rule types most tutorials skip: **Provisioning rules** (reshaping what gets sent to a connector) and **Certification rules** (controlling what a reviewer sees and who reviews it). Extracted from the [SailPoint IdentityIQ BeanShell Rule Cookbook](https://iamdevbox.com/posts/sailpoint-identityiq-beanshell-rule-cookbook-provisioning-certification/) and [Automating SailPoint IdentityIQ Certification Campaigns](https://iamdevbox.com/posts/sailpoint-identityiq-automating-certification-campaigns/) guides on [IAMDevBox](https://iamdevbox.com).

For the four rule types every IdentityIQ developer writes first — BuildMap, Correlation, IdentityAttribute, and rule libraries — see the companion [sailpoint-iiq-devtools](https://github.com/IAMDevBox/sailpoint-iiq-devtools) repo and its source guide, [BeanShell Rules, Workflows, and Tasks](https://iamdevbox.com/posts/sailpoint-identityiq-beanshell-rules-workflows-tasks-developer-guide/).

## What's Included

| File | Rule type | Purpose |
|---|---|---|
| `rules/before-provisioning-disable-to-status-flag.xml` | `BeforeProvisioning` | Converts Disable/Enable operations into a Modify with a status attribute, for target systems with no native disable |
| `rules/after-provisioning-notify-manager.xml` | `AfterProvisioning` | Emails a manager when a provisioning request against an application commits successfully |
| `rules/certification-exclusion-disabled-and-role-justified.xml` | `CertificationExclusion` | Filters role-justified entitlements out of an access review so reviewers aren't re-approving the same access twice |
| `rules/certification-pre-delegation-financial-app.xml` | `CertificationPreDelegation` | Routes entitlements on a designated high-risk application to a dedicated reviewer instead of the identity's default certifier — the rule that makes automated/unattended campaigns safe for sensitive applications |
| `scripts/diff-exclusion-impact.sh` | — | Quantifies what a `CertificationExclusion` or `CertificationPreDelegation` rule actually changed, by diffing item counts between two staged certifications of the same definition. For pre-delegation specifically, this only confirms the item set is unchanged (delegation doesn't add/remove items) — you still need to spot-check a few `CertificationEntity` owners in the UI to confirm the reassignment itself took effect, since the script counts items, not certifier identity. |

## Quick Start

```bash
git clone https://github.com/IAMDevBox/sailpoint-iiq-rule-cookbook.git
cd sailpoint-iiq-rule-cookbook

# Import a rule via the iiq console (run from IdentityIQ_HOME/WEB-INF/bin)
./iiq console
> import /path/to/sailpoint-iiq-rule-cookbook/rules/before-provisioning-disable-to-status-flag.xml

# After attaching a CertificationExclusion rule, quantify its impact before
# running a live campaign — generate the same certification definition twice
# as "Staged" (once without the rule, once with it), then:
DB_USER=identityiq DB_PASS=changeit \
  ./scripts/diff-exclusion-impact.sh "Q3 Access Review (no rule)" "Q3 Access Review (with rule)"
```

## Attaching Provisioning Rules

`BeforeProvisioning` and `AfterProvisioning` rules are configured **per application**, on the Rules tab of the Edit Application page — not globally. Attach `before-provisioning-disable-to-status-flag.xml` only to applications whose connector actually rejects a native `Disable` operation; attaching it everywhere is harmless but adds a no-op rule invocation to every provisioning call.

`after-provisioning-notify-manager.xml` expects an `EmailTemplate` named `Privileged Grant Notification` to already exist. Without it, the rule logs a warning and exits — it does not throw, so a missing template fails silently unless you're watching the log.

## Why Exclusion Rules Need a Staging Step

A `CertificationExclusion` rule that over-excludes fails silently: reviewers never see the missing items, and nothing in the UI indicates anything was filtered. `diff-exclusion-impact.sh` exists because the only reliable way to catch this before a live campaign is to compare item counts between a staged run with the rule and one without it — the script also flags the two most common bug signatures: 100% excluded (a null check that always short-circuits) and a negative diff (arguments passed in the wrong order).

## Related Reading

- [SailPoint IdentityIQ BeanShell Rule Cookbook: Provisioning and Certification Rules](https://iamdevbox.com/posts/sailpoint-identityiq-beanshell-rule-cookbook-provisioning-certification/) (source article)
- [SailPoint IdentityIQ BeanShell Rules, Workflows, and Tasks: A Developer's Guide](https://iamdevbox.com/posts/sailpoint-identityiq-beanshell-rules-workflows-tasks-developer-guide/)
- [SailPoint IdentityIQ Aggregation Troubleshooting: Complete Error Guide](https://iamdevbox.com/posts/sailpoint-identityiq-aggregation-troubleshooting-complete-error-guide/)
- [IAM Tools Comparison: Complete Guide to Identity Platforms](https://iamdevbox.com/posts/iam-tools-comparison-complete-guide-to-identity-platforms/)

## License

MIT — use freely in your own IdentityIQ deployment tooling.
