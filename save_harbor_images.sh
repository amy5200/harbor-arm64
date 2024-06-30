#!/bin/bash
set -e

GIT_BRANCH="v2.11.0"
SAVE_DIR="images"
mkdir "$SAVE_DIR"

IMAGES=(
    "goharbor/harbor-exporter:$GIT_BRANCH-aarch64"
    "goharbor/redis-photon:$GIT_BRANCH-aarch64"
    "goharbor/trivy-adapter-photon:$GIT_BRANCH-aarch64"
    "goharbor/harbor-registryctl:$GIT_BRANCH-aarch64"
    "goharbor/registry-photon:$GIT_BRANCH-aarch64"
    "goharbor/nginx-photon:$GIT_BRANCH-aarch64"
    "goharbor/harbor-log:$GIT_BRANCH-aarch64"
    "goharbor/harbor-jobservice:$GIT_BRANCH-aarch64"
    "goharbor/harbor-core:$GIT_BRANCH-aarch64"
    "goharbor/harbor-portal:$GIT_BRANCH-aarch64"
    "goharbor/harbor-db:$GIT_BRANCH-aarch64"
    "goharbor/prepare:$GIT_BRANCH-aarch64"
)

echo '[]' > "$SAVE_DIR/manifest.json"

for IMAGE in "${IMAGES[@]}"; do
    echo "Saving $IMAGE..."
    
    TEMP_DIR=$(mktemp -d ./temp_XXXXXX)
    echo "Created temporary directory: $TEMP_DIR"
    
    docker save "$IMAGE" | tar -xC "$TEMP_DIR"
    
    if [ -f "$TEMP_DIR/manifest.json" ]; then
        # Combine manifest files if manifest.json exists
        jq -s '.[0] + .[1]' "$SAVE_DIR/manifest.json" "$TEMP_DIR/manifest.json" > "$SAVE_DIR/manifest.json.tmp"
        mv "$SAVE_DIR/manifest.json.tmp" "$SAVE_DIR/manifest.json"
    else
        echo "Warning: manifest.json not found in $TEMP_DIR"
    fi
    
    # Synchronize all contents except manifest.json
    rsync -a --exclude='manifest.json' "$TEMP_DIR/" "$SAVE_DIR/"
    
    rm -rf "$TEMP_DIR"
    echo "Temporary directory $TEMP_DIR deleted"
done

echo "All images have been saved to $SAVE_DIR"
echo "Creating tarball without including the 'images' directory..."
TEMP_DIR=$(mktemp -d ./temp_XXXXXX)
echo "Created temporary directory: $TEMP_DIR"
cp -f ./src/github.com/goharbor/harbor/LICENSE "$TEMP_DIR/LICENSE"
cp -f ./src/github.com/goharbor/harbor/make/common.sh "$TEMP_DIR/common.sh"
cp -f ./src/github.com/goharbor/harbor/make/harbor.yml.tmpl "$TEMP_DIR/harbor.yml.tmpl"
cp -f ./src/github.com/goharbor/harbor/make/install.sh "$TEMP_DIR/install.sh"
cp -f ./src/github.com/goharbor/harbor/make/prepare "$TEMP_DIR/prepare"
sed -i "s#goharbor/prepare:dev#goharbor/prepare:${GIT_BRANCH}-aarch64#g" "$TEMP_DIR/prepare"
chmod +x "$TEMP_DIR/prepare" "$TEMP_DIR/install.sh"
(cd "$SAVE_DIR" && tar -czvf ../$TEMP_DIR/harbor-$GIT_BRANCH.tar.gz .)
(cd "$TEMP_DIR" && tar -czvf ../harbor-$GIT_BRANCH-aarch64.tar.gz .)
rm -rf "$TEMP_DIR"
rm -rf "$SAVE_DIR"