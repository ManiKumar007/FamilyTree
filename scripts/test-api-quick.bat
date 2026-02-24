@echo off
echo.
echo ========================================
echo  Test API Endpoints - MyFamilyTree
echo ========================================
echo.

echo Testing Health Endpoint...
curl -s http://localhost:3000/api/health
echo.
echo.

echo Testing Your Profile...
curl -s http://localhost:3000/api/persons/me/profile
echo.
echo.

echo Testing Family Tree...
curl -s "http://localhost:3000/api/tree" > tree-response.json
echo Family tree saved to tree-response.json
echo.

echo Testing Search...
curl -s "http://localhost:3000/api/search?q=Kumar"
echo.
echo.

echo ========================================
echo  If you see data above, the API works!
echo  Just refresh your browser with Ctrl+Shift+R
echo ========================================
echo.
pause
