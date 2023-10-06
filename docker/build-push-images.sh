#/bin/bash

set -e

## start of test
# API_TOKEN=''
# COMMENT='snouty test: config-test, service1'
# REGISTRY='us-central1-docker.pkg.dev'
# REPOSITORY='molten-verve-216720/quantstamp-repository'
# # WEBHOOK_URL='https://quantstamp.antithesis.com/api/v1/launch_experiment/secret_test'
# GITHUB_REPO_OWNER='chang-xiao-antithesis'
# GITHUB_REPO_NAME='bigboy'
# PR_URL='https://api.github.com/repos/chang-xiao-antithesis/bigboy/pulls/4'
## end of test

# Looking into the docker directory and perform the build if exists
directory='docker'

revision=$(git rev-parse HEAD)

# we need to submit the comment to the PR id, not the issue id :(
# only way to get the PR id is from the URL
pr_id=$(echo "$PR_URL" | sed 's/.*\///')

search="snouty test"

# look for our magic keyword
if [[ $COMMENT =~ ${search} ]]; then

  imgs_attempted_to_build=()

  # split the message and start scanning for the services
  services=$(echo "$COMMENT" | awk -F': ' '{print $2}')
  # comma separate into an array
  IFS=',' read -ra services_arr <<< "$services"
  for service in "${services_arr[@]}"; do
    # trim whitespaces
    service_tr=$(echo "$service" | tr -d '[:space:]')

    # Only do the build/push if the sub-directory exists
    image_build_path="${directory}/${service_tr}"
    if [ -d $image_build_path ]; then
      image_url="${REGISTRY}/${REPOSITORY}/${service_tr}"

      # We have to redirect the output to stdout since docker does 
      # not use that by default
      # capture the whole output into an array
      #todo: we assume there is a Dockerfile that exist
      # build_output=($(docker buildx build --platform linux/amd64 --push \
      # -t ${image_url}:${revision} \
      # -t ${image_url}:"PR-${pr_id}" \
      # $image_build_path))

      docker buildx build --platform linux/amd64 --push \
      -t ${image_url}:${revision} \
      -t ${image_url}:"PR-${pr_id}" \
      $image_build_path

      # sha=''
      # for line in "${build_output[@]}"; do
      #   if [[ $line =~ "sha256" ]]; then
      #     sha=$line
      #   fi
      # done

      echo adding ${service_tr}:${revision} to the list of attempted to build
      imgs_attempted_to_build+=(${service_tr}:${revision})

      # Still spit out the build outputs for debugging
      # printf '%s\n' "${build_output[@]}"
    fi
  done
fi

# Posting to the PR about the build
if [ ${#imgs_attempted_to_build[@]} -gt 0 ]; then

  printf -v attempted '%s,' "${imgs_attempted_to_build[@]}"
  images_message="Snouty attempted to build the following container image(s): ${attempted%,}"
  echo $images_message

  curl -L \
    -X POST \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer ${API_TOKEN}" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    https://api.github.com/repos/$GITHUB_REPO_OWNER/$GITHUB_REPO_NAME/issues/$pr_id/comments \
    -d '{"body":"'"$images_message"'"}'
fi
