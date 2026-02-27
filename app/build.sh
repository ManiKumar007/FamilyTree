#!/bin/bash
set -e

# Install Flutter if not available
if ! command -v flutter &> /dev/null; then
  echo "Installing Flutter..."
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 ~/flutter
  export PATH="$PATH:$HOME/flutter/bin"
  flutter precache --web
fi

export PATH="$PATH:$HOME/flutter/bin"

# Enable web platform if not already configured
if [ ! -d "web" ]; then
  echo "Enabling web platform..."
  flutter create . --platforms web
fi

# Create .env file from Vercel environment variables (trim whitespace/newlines)
API_BASE_URL_CLEAN=$(echo "$API_BASE_URL" | tr -d '\n\r ')
cat > .env << EOF
SUPABASE_URL=$(echo "$SUPABASE_URL" | tr -d '\n\r ')
SUPABASE_ANON_KEY=$(echo "$SUPABASE_ANON_KEY" | tr -d '\n\r ')
API_BASE_URL=$API_BASE_URL_CLEAN
GOOGLE_CLIENT_ID=$(echo "$GOOGLE_CLIENT_ID" | tr -d '\n\r ')
APP_URL=$(echo "$APP_URL" | tr -d '\n\r ')
EOF

echo "=== Build Config ==="
echo "API_BASE_URL: $API_BASE_URL_CLEAN"
echo "APP_URL: $(echo "$APP_URL" | tr -d '\n\r ')"
echo "===================="

# Build Flutter web (canvaskit is default for release builds)
flutter pub get
flutter build web --release
