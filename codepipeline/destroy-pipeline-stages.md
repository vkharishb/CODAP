# CODAP destroy pipeline wiring

Use a separate, manually started CodePipeline for destructive operations.

## Pipeline-level variables

Define these variables:

| Variable | Default | Purpose |
|---|---|---|
| `DESTROY_ACTION` | `CANCEL` | Must be overridden to `DESTROY`. |
| `TARGET_ENVIRONMENT` | `dev` | `dev`, `qa`, `stage`, or `prod`. |
| `REQUESTED_BY` | `unknown` | Informational requestor name. |
| `PROD_USERNAME` | empty | Required by the plan buildspec when environment is `prod`. |

Pass the variables into the destroy-plan CodeBuild action as plaintext action environment variables using `#{variables.VARIABLE_NAME}`.

## Stages

| Stage | CodeBuild project | Buildspec override | Inputs | Primary source | Output |
|---|---|---|---|---|---|
| Source | CodeCommit | n/a | n/a | n/a | `SourceArtifact` |
| Destroy Plan | `codap-99-destroy-plan` | `codebuild/99-terraform-destroy-plan.yml` | `SourceArtifact` | default | `DestroyPlanArtifact` |
| Mandatory Approval | CodePipeline manual approval | n/a | n/a | n/a | n/a |
| Destroy Apply | `codap-99-destroy-apply` | `codebuild/99-terraform-destroy-apply.yml` | `SourceArtifact`, `DestroyPlanArtifact` | `SourceArtifact` | `DestroyOutputArtifact` |

`DestroyPlanArtifact` becomes `$CODEBUILD_SRC_DIR_DestroyPlanArtifact` in the apply project.

## Production control

GitHub's `github.triggering_actor` has no exact buildspec equivalent when CodeBuild is launched by CodePipeline. Treat `REQUESTED_BY` and `PROD_USERNAME` as informational only. Use IAM permissions on `codepipeline:PutApprovalResult`, CloudTrail, and a mandatory manual approval action as the authoritative production control.
