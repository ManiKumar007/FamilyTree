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
SUPABASE_URL_CLEAN=$(echo "$SUPABASE_URL" | tr -d '\n\r ')
SUPABASE_ANON_KEY_CLEAN=$(echo "$SUPABASE_ANON_KEY" | tr -d '\n\r ')
GOOGLE_CLIENT_ID_CLEAN=$(echo "${GOOGLE_CLIENT_ID:-$GOOGLE_WEB_CLIENT_ID}" | tr -d '\n\r ')
GOOGLE_WEB_CLIENT_ID_CLEAN=$(echo "${GOOGLE_WEB_CLIENT_ID:-$GOOGLE_CLIENT_ID}" | tr -d '\n\r ')
APP_URL_CLEAN=$(echo "$APP_URL" | tr -d '\n\r ')
cat > .env << EOF
SUPABASE_URL=$SUPABASE_URL_CLEAN
SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY_CLEAN
API_BASE_URL=$API_BASE_URL_CLEAN
GOOGLE_CLIENT_ID=$GOOGLE_CLIENT_ID_CLEAN
GOOGLE_WEB_CLIENT_ID=$GOOGLE_WEB_CLIENT_ID_CLEAN
APP_URL=$APP_URL_CLEAN
EOF

echo "=== Build Config ==="
echo "API_BASE_URL: $API_BASE_URL_CLEAN"
echo "APP_URL: $APP_URL_CLEAN"
echo "===================="

# Build Flutter web (canvaskit is default for release builds)
# Pass env vars both as dart-define (compile-time) and .env (runtime fallback)
flutter pub get
flutter build web --release \
  --dart-define=API_BASE_URL="$API_BASE_URL_CLEAN" \
  --dart-define=SUPABASE_URL="$SUPABASE_URL_CLEAN" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY_CLEAN" \
  --dart-define=APP_URL="$APP_URL_CLEAN" \
  --dart-define=GOOGLE_CLIENT_ID="$GOOGLE_CLIENT_ID_CLEAN" \
  --dart-define=GOOGLE_WEB_CLIENT_ID="$GOOGLE_WEB_CLIENT_ID_CLEAN"
