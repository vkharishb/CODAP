# CODAP main CodePipeline wiring

Create one CodePipeline with a CodeCommit source action and the CodeBuild actions below. Configure the CodeCommit source action namespace as `SourceVariables` and output artifact as `SourceArtifact`.

| Stage | CodeBuild project | Buildspec override | Input artifacts | Primary source | Output artifact | Privileged mode |
|---|---|---|---|---|---|---|
| 00 Role Test | `codap-00-role-test` | `codebuild/00-role-test.yml` | `SourceArtifact` | default | none | No |
| 01 CI | `codap-01-ci` | `codebuild/01-ci.yml` | `SourceArtifact` | default | none | **Yes** |
| 02 Terraform Plan | `codap-02-terraform-plan` | `codebuild/02-terraform-plan.yml` | `SourceArtifact` | default | `TerraformPlanArtifact` | No |
| Approval | CodePipeline manual approval | n/a | n/a | n/a | n/a | n/a |
| 03 Terraform Apply | `codap-03-terraform-apply` | `codebuild/03-terraform-apply.yml` | `SourceArtifact`, `TerraformPlanArtifact` | `SourceArtifact` | `TerraformApplyArtifact` | No |
| 04 Build/Security/Push | `codap-04-build-security-push` | `codebuild/04-build-security-push.yml` | `SourceArtifact` | default | `ImageArtifact` | **Yes** |
| 05 Deploy | `codap-05-deploy-application` | `codebuild/05-deploy-application.yml` | `SourceArtifact`, `ImageArtifact` | `SourceArtifact` | `DeploymentArtifact` | No |
| 06 Grafana Proof | `codap-06-grafana-live` | `codebuild/06-grafana-live.yml` | `SourceArtifact` | default | `GrafanaProofArtifact` | No |

## Important artifact names

Artifact names are case-sensitive because CodeBuild exposes secondary input directories as environment variables:

- `TerraformPlanArtifact` becomes `$CODEBUILD_SRC_DIR_TerraformPlanArtifact`.
- `ImageArtifact` becomes `$CODEBUILD_SRC_DIR_ImageArtifact`.

The apply and deploy buildspec files use those exact names.

## CodeBuild project configuration

Use these common settings:

- Source provider: `CodePipeline`.
- Environment: latest AWS-managed Ubuntu standard image.
- Compute: EC2 on-demand.
- CloudWatch Logs: enabled.
- Buildspec: either configure the path on each project or use `BuildspecOverride` in the CodePipeline action.
- Artifacts: `CodePipeline` for projects that produce an output artifact; `No artifacts` for projects without output.
- Service role: use a dedicated role for each security boundary where practical.

Enable privileged mode only for `codap-01-ci` and `codap-04-build-security-push`, because those projects call Docker.

## Branch and trigger

Configure the CodeCommit source for repository `CODAP` and branch `main`. CodePipeline replaces the GitHub `workflow_run` and GitHub workflow-dispatch chaining; each successful stage automatically advances to the next stage.

The GitHub `paths:` filter has no direct equivalent in a basic CodeCommit source action. This pipeline will normally trigger for every commit to `main`. Add a custom EventBridge/Lambda filter only if path-level triggering is essential.
