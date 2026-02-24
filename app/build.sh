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

# Create .env file from Vercel environment variables
cat > .env << EOF
SUPABASE_URL=$SUPABASE_URL
SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY
API_BASE_URL=$API_BASE_URL
GOOGLE_CLIENT_ID=$GOOGLE_CLIENT_ID
APP_URL=$APP_URL
EOF

# Build Flutter web (canvaskit is default for release builds)
flutter pub get
flutter build web --release
