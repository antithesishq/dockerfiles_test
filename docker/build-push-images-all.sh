#/bin/bash

set -e

# Going through all of the directories and use it as the container names
#
directory='docker'

revision=$(git rev-parse HEAD)

while IFS= read -r -d '' subdirectory; do
  # Append the sub-directory to the array
  directories+=("$subdirectory")
done < <(find "$directory" -type d -print0)

subdirs=("${directories[@]:1}")

for subdir in "${subdirs[@]}"; do
    image_name="$(basename "$subdir")"
    # Important, REGISTRY AND REPOSITORY should be passed in 
    # as envars 
    image_url="${REGISTRY}/${REPOSITORY}/${image_name}"
    context="docker/${image_name}"

    docker buildx build --platform linux/amd64 --push \
    -t ${image_url}:${revision} \
    -t ${image_url}:latest \
    $context

    # # podman build -t ${image_url}:${revision} $subdir 
done
