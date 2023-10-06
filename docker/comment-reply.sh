#/bin/bash

set -e

# Looking into the docker directory and perform the build if exists
directory='docker'

## start of test
# API_TOKEN=''
# COMMENT='snouty test: fake-service, service1'
# WEBHOOK_URL='https://quantstamp.antithesis.com/api/v1/launch_experiment/secret_test'
# GITHUB_REPO_OWNER='chang-xiao-antithesis'
# GITHUB_REPO_NAME='bigboy'
# ISSUE_ID='1917822836'
# PR_URL='https://api.github.com/repos/chang-xiao-antithesis/bigboy/pulls/3'
## end of test

# we need to submit the comment to the PR id, not the issue id :(
# only way to get the PR id is from the URL
pr_id=$(echo "$PR_URL" | sed 's/.*\///')

search="snouty test"

images_attempted=()

# look for our magic keyword
if [[ $COMMENT =~ ${search} ]]; then
  # split the message and start scanning for the services
  services=$(echo "$COMMENT" | awk -F': ' '{print $2}')
  # comma separate into an array
  IFS=',' read -ra services_arr <<< "$services"
  for service in "${services_arr[@]}"; do
    # trim whitespaces
    service_tr=$(echo "$service" | tr -d '[:space:]')
    # verify that path exists
    image_build_path="${directory}/${service_tr}"
    if [ -d $image_build_path ]; then
      images_attempted+=("${service_tr}:PR-${pr_id}")
    fi
  done
fi

if [ ${#images_attempted[@]} -gt 0 ]; then

  attempted=${images_attempted[*]}

  webhook_url=$(echo "$WEBHOOK_URL" | sed 's/\//\\\//g')

  images_message="Snouty attempted to build the following container image(s): ${attempted} and fired off a test at $webhook_url"

  # echo $images_message

  curl -L \
    -X POST \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer ${API_TOKEN}" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    https://api.github.com/repos/$GITHUB_REPO_OWNER/$GITHUB_REPO_NAME/issues/$pr_id/comments \
    -d '{"body":"'"$images_message"'"}'
fi
