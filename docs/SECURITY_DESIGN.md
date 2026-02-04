# Data Platform Security & Governance Design

## Executive Summary

This document outlines the security architecture of the data platform, focusing on workgroup-to-database isolation, access controls, and compliance requirements for production deployments.

## Current Architecture

### Access Model
- **Workgroups**: Environment-specific (dev, staging, prod)
- **Databases**: Environment-specific Glue catalogs
- **Current Limitation**: Users can query any database from any workgroup

### What Works Today
✅ Data encrypted at rest (S3, query results)  
✅ Environment-specific query result retention policies  
✅ Cost controls via query scan limits  
✅ VPC network isolation  
✅ IAM-based authentication  

### Gap Identified
❌ No enforcement preventing cross-environment queries  
❌ Compliance risk: Prod queries could use dev retention policies  
❌ Cost tracking ambiguity across environments  

## Production Security Requirements

### 1. Workgroup-to-Database Isolation

**Requirement**: Each workgroup should only access its corresponding database.
```
dev workgroup      → dev database only
staging workgroup  → staging database only
prod workgroup     → prod database only
```

**Why This Matters**:
- **Compliance**: Prod data must follow prod retention/audit policies
- **Cost Attribution**: Accurate per-environment cost tracking
- **Least Privilege**: Users shouldn't access prod unless explicitly granted
- **Audit Trail**: Clear separation of development vs production analytics

### 2. Recommended Implementation

#### Option A: IAM Policy Conditions (Recommended)

Use IAM conditions to restrict Glue database access based on resource tags.

**Step 1**: Tag all Glue databases
```hcl
resource "aws_glue_catalog_database" "main" {
  name = "data-platform-${var.environment}-database"
  
  tags = {
    Environment = var.environment
    DataClassification = var.environment == "prod" ? "confidential" : "internal"
  }
}
```

**Step 2**: Create IAM policies with conditions
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "glue:GetDatabase",
        "glue:GetTable",
        "glue:GetTables"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "aws:ResourceTag/Environment": "dev"
        }
      }
    }
  ]
}
```

**Step 3**: Assign policies to user roles
- `data-engineer-dev-role` → Can only access dev database
- `data-engineer-staging-role` → Can only access staging database  
- `data-engineer-prod-role` → Can only access prod database (with MFA)

#### Option B: Lake Formation Permissions

Use AWS Lake Formation for fine-grained access control.

**Advantages**:
- Column-level permissions
- Centralized audit trail
- Data masking capabilities
- Cross-account sharing

**Trade-offs**:
- More complex setup
- Additional service to manage
- Learning curve for team

#### Option C: Service Control Policies (SCPs)

For multi-account setups, use SCPs to enforce boundaries.

**Best For**:
- Organizations with dedicated AWS accounts per environment
- Strong isolation requirements
- Regulatory compliance (HIPAA, SOC2)

### 3. Additional Security Enhancements

#### A. Enable MFA for Production Access
```hcl
# Require MFA for prod workgroup access
resource "aws_iam_policy" "prod_mfa_required" {
  policy = jsonencode({
    Statement = [{
      Effect = "Deny"
      Action = "athena:StartQueryExecution"
      Resource = "arn:aws:athena:*:*:workgroup/data-platform-prod-workgroup"
      Condition = {
        BoolIfExists = {
          "aws:MultiFactorAuthPresent" = "false"
        }
      }
    }]
  })
}
```

#### B. Enable CloudTrail for Athena
- Log all query executions
- Monitor cross-environment access attempts
- Alert on suspicious patterns

#### C. Query Result Encryption
Already implemented: SSE-S3 encryption on all query results.

**Enhancement**: Use KMS with separate keys per environment for prod.

#### D. VPC Endpoints
Consider Athena VPC endpoints to prevent internet egress.

## Implementation Roadmap

### Phase 1: Immediate (No Code Changes)
1. ✅ Document current architecture
2. ✅ Identify gaps and risks
3. Document IAM policy requirements
4. Create runbook for proper workgroup selection

### Phase 2: Short-term (1-2 sprints)
1. Implement resource tagging on all Glue resources
2. Create environment-specific IAM roles
3. Update user role assignments
4. Enable CloudTrail logging for Athena

### Phase 3: Medium-term (1-2 months)
1. Implement IAM conditions for database access
2. Add MFA requirement for prod workgroup
3. Set up monitoring and alerting
4. Conduct security audit

### Phase 4: Long-term (Optional)
1. Evaluate Lake Formation adoption
2. Consider multi-account architecture
3. Implement data classification framework

## Cost-Benefit Analysis

| Solution | Setup Cost | Maintenance | Security Level | Complexity |
|----------|-----------|-------------|----------------|------------|
| IAM Conditions | Low | Low | Medium | Low |
| Lake Formation | Medium | Medium | High | Medium |
| Multi-Account | High | High | Very High | High |

**Recommendation**: Start with IAM conditions for immediate gains, evaluate Lake Formation as platform matures.

## Compliance Considerations

### SOC 2 Requirements
- ✅ Access controls (IAM)
- ✅ Encryption at rest and in transit
- ⚠️ Need: Workgroup isolation via IAM
- ⚠️ Need: MFA for production access
- ⚠️ Need: Comprehensive audit logging

### GDPR Requirements
- ✅ Data encryption
- ✅ Retention policies
- ⚠️ Need: Data access audit trail
- ⚠️ Need: Right to deletion workflow

### HIPAA Requirements (if applicable)
- ✅ Encryption
- ⚠️ Need: PHI access logging
- ⚠️ Need: Break-glass access procedures
- ⚠️ Need: Regular access reviews

## Talking Points

**"During platform testing, I discovered that users could query the production database from the dev workgroup. While data remained encrypted and access-controlled, this created compliance risks around retention policies and audit trails."**

**"I documented this as a design gap and created a phased implementation plan using IAM policy conditions with resource tags. The solution balances security requirements with operational complexity, following the principle of least privilege."**

**"For a production deployment, I'd recommend Phase 1 and Phase 2 immediately, with Phase 3 implemented before handling sensitive data. The multi-account architecture in Phase 4 makes sense for organizations with strict regulatory requirements."**

## References

- [AWS Athena Security Best Practices](https://docs.aws.amazon.com/athena/latest/ug/security-best-practices.html)
- [IAM Conditions Documentation](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_elements_condition.html)
- [AWS Lake Formation](https://aws.amazon.com/lake-formation/)
- [Terraform AWS Provider - Glue](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/glue_catalog_database)

---

**Document Version**: 1.0  
**Last Updated**: February 4, 2026  
**Author**: Gabriel Llanes  
**Status**: Design Proposal