#!/bin/bash
set -e

SAVE_DIR="/data/images"
mkdir -p "$SAVE_DIR"

IMAGES=(
    "goharbor/harbor-exporter:v2.11.0"
    "goharbor/redis-photon:v2.11.0"
    "goharbor/trivy-adapter-photon:v2.11.0"
    "goharbor/harbor-registryctl:v2.11.0"
    "goharbor/registry-photon:v2.11.0"
    "goharbor/nginx-photon:v2.11.0"
    "goharbor/harbor-log:v2.11.0"
    "goharbor/harbor-jobservice:v2.11.0"
    "goharbor/harbor-core:v2.11.0"
    "goharbor/harbor-portal:v2.11.0"
    "goharbor/harbor-db:v2.11.0"
    "goharbor/prepare:v2.11.0"
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
(cd "$SAVE_DIR" && tar -czvf ../harbor-v2.11.0.tar.gz .)

echo "Combined manifest.json:"
cat "$SAVE_DIR/manifest.json" | jq .
