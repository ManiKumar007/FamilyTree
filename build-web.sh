#!/bin/bash
set -e

echo "=== Flutter Web Build Script for Vercel ==="

# Set Flutter path
export PATH="$PATH:$HOME/flutter/bin"

# Navigate to app directory
cd app

# Create .env file from Vercel environment variables (if set)
if [ -n "$SUPABASE_URL" ]; then
  cat > .env << EOF
SUPABASE_URL=$SUPABASE_URL
SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY
API_BASE_URL=$API_BASE_URL
GOOGLE_CLIENT_ID=$GOOGLE_CLIENT_ID
APP_URL=$APP_URL
EOF
  echo "Environment variables configured"
fi

# Enable web platform if needed
if [ ! -d "web" ]; then
  echo "Enabling web platform..."
  flutter create . --platforms web
fi

# Build
echo "Running flutter pub get..."
flutter pub get

echo "Building Flutter web app..."
flutter build web --release --web-renderer canvaskit

echo "Build complete!"
