echo "Starting..."

MAIN_BINARY_NAME='$main_binary'
S3_BUCKET="'$s3_bucket'"
S3_KEY="'$s3_key''$main_binary'.zip"
DEPLOY_ROOT="/var/www"
DEPLOY_DIR="$DEPLOY_ROOT/$MAIN_BINARY_NAME"
CERT_DIR="/etc/ssl/private/$MAIN_BINARY_NAME"
ZIP_FILE="/tmp/$MAIN_BINARY_NAME.zip"

# Stop and remove previous deployment service
sudo systemctl stop "$MAIN_BINARY_NAME.service" || true
sudo systemctl disable "$MAIN_BINARY_NAME.service" || true
sudo rm -f "/etc/systemd/system/$MAIN_BINARY_NAME.service"

# Remove the previous deployment directory
sudo rm -rf "${DEPLOY_DIR}"
mkdir -p "${DEPLOY_DIR}"

# Remove the previous deployment certificate directory
sudo rm -rf "$CERT_DIR"
mkdir -p "$CERT_DIR"

if [ -f "$ZIP_FILE" ]; then
    echo "Zip file found at $ZIP_FILE"
else
    echo "Zip file not found at $ZIP_FILE"
    exit 1
fi

# Unzip the archive
unzip -q "$ZIP_FILE" -d "$DEPLOY_DIR"
rm "$ZIP_FILE"

# Grabbing the certificate if uploaded separately to S3 or from inside of the publish folder
mv "$DEPLOY_DIR/certificate/"* "$CERT_DIR/"
sudo chmod 644 "$CERT_DIR"/*.crt
sudo chmod 600 "$CERT_DIR"/*.key
sudo chmod 755 "$CERT_DIR"

# Find certificate filenames
CERT_CRT_FILE=$(find "$CERT_DIR" -name "*.crt" -printf "%f\n")
CERT_KEY_FILE=$(find "$CERT_DIR" -name "*.key" -printf "%f\n")

# Verify certificates exist
if [ -z "$CERT_CRT_FILE" ] || [ -z "$CERT_KEY_FILE" ]; then
    echo "Certificate files not found in $CERT_DIR"
    exit 1
fi

# Creating the systemd .service file
cat <<EOF | sudo tee "/etc/systemd/system/$MAIN_BINARY_NAME.service"
[Unit]
Description=$MAIN_BINARY_NAME .NET App
After=network.target

[Service]
WorkingDirectory=$DEPLOY_DIR
ExecStart=$DEPLOY_DIR/$MAIN_BINARY_NAME
StandardOutput=append:$DEPLOY_DIR/system.out.log
StandardError=append:$DEPLOY_DIR/system.err.log
Restart=always
User=$(whoami)
NoNewPrivileges=true
ProtectSystem=full
ProtectHome=true
PrivateTmp=true
PrivateDevices=true
ProtectKernelTunables=true
ProtectKernelModules=true

[Install]
WantedBy=multi-user.target
EOF

# Start all the services
sudo systemctl daemon-reload
sudo systemctl enable "$MAIN_BINARY_NAME.service"
sudo systemctl start "$MAIN_BINARY_NAME.service"
