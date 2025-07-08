#!/bin/bash

set -e

apk add --no-cache curl
curl -L -o /tmp/giphy.gif $GIPHY_LINK
curl -L https://dl.min.io/client/mc/release/linux-$HOST_ARCH/mc -o /usr/bin/mc
chmod +x /usr/bin/mc
mc alias set minio $MINIO_ENDPOINT $MINIO_ACCESS_KEY $MINIO_SECRET_KEY
echo "Creating index.html..."
cat > /tmp/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
  <style>
    body {
      margin: 0;
      padding: 0;
      display: flex;
      justify-content: center;
      align-items: center;
      height: 100vh;
      background-color:rgb(42, 42, 42);
    }
    img {
      max-width: 100%;
      max-height: 100vh;
    }
  </style>
</head>
<body>
  <img src="/giphy.gif">
</body>
</html>
EOF
mc mb --ignore-existing minio/files
mc cp /tmp/index.html minio/files/
mc cp /tmp/giphy.gif minio/files/
echo "Files uploaded successfully!"