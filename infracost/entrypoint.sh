#!/bin/sh
set -e
PR_NUMBER=$(echo $GITHUB_REF | awk -F '/' '{print $3}')
filename='text.txt'
if [ -z "$GITHUB_TOKEN" ]; then
  echo "No token provided"
  exit 1
fi
if [ -z "$DEPLOYMENT_ENV" ]; then
  echo "No workspace provided"
  exit 1
fi
git config --global --add safe.directory /github/workspace
git diff --name-only origin/main >$filename
DIRECTORIES=$(awk -F '/' '{print $1}' text.txt | sort | uniq | grep -v .github | grep -v action-infracost | grep -v infracost.json | grep -v _deprecated |grep -v README.md)
if [ -z "$DIRECTORIES" ]; then
  echo "Skipping the infra cost analysis as there are no changes to terraform associated files."
  exit 0
fi
for x in $DIRECTORIES; do
  cd "/github/workspace/$x"
  terraform init
  terraform workspace new $DEPLOYMENT_ENV || echo true
  terraform workspace select $DEPLOYMENT_ENV
  set +e
  RESULT=$(terraform plan -no-color -input=false 2>&1)
  if [ $? -eq 0 ]; then
    RESULT=${RESULT::65300}
    PR_COMMENT="#### Terraform \`plan\` Succeeded for Workspace: \`$DEPLOYMENT_ENV\` for \`$x\`
 \`\`\`diff
 $RESULT
 \`\`\`"
    gh pr comment $PR_NUMBER -b "$PR_COMMENT"
  else
    RESULT=${RESULT::65300}
    PR_COMMENT="#### Terraform \`plan\` Failed for Workspace: \`$DEPLOYMENT_ENV\` for \`$x\`
  \`\`\`diff
  $RESULT
  \`\`\`"
    gh pr comment $PR_NUMBER -b "$PR_COMMENT"
  fi
  set -e
 infracost breakdown --path . --terraform-workspace $DEPLOYMENT_ENV --format json >infracost.json
#  infracost comment github --path=infracost.json \
#     --repo=$GITHUB_REPOSITORY \
#     --pull-request=$PR_NUMBER `# or --commit=$GITHUB_SHA` \
#     --github-token=${{ secrets.GITHUB_TOKEN }} \
#     --behavior=new
 infracost comment github --path infracost.json  --repo $GITHUB_REPOSITORY --pull-request $PR_NUMBER --github-token $GITHUB_TOKEN --behavior new
done
