# Fix Person constructors in test files by adding required phone parameter

$testFiles = @(
    "app\test\models\connection_models_test.dart",
    "app\test\features\connection\connection_finder_test.dart",
    "app\test\widgets\person_card_test.dart"
)

foreach ($file in $testFiles) {
    $fullPath = Join-Path $PSScriptRoot $file
    if (Test-Path $fullPath) {
        Write-Host "Fixing $file..." -ForegroundColor Cyan
        
        $content = Get-Content $fullPath -Raw
        
        # Pattern 1: Person with id, name, gender only
        $content = $content -replace "Person\(\s*id:\s*'([^']+)',\s*name:\s*'([^']+)',\s*gender:\s*'([^']+)'\s*\)", "Person(id: '`$1', name: '`$2', gender: '`$3', phone: '')"
        
        # Pattern 2: Person with id, name, gender, username
        $content = $content -replace "Person\(\s*id:\s*'([^']+)',\s*name:\s*'([^']+)',\s*gender:\s*'([^']+)',\s*username:\s*'([^']+)'\s*\)", "Person(id: '`$1', name: '`$2', gender: '`$3', phone: '', username: '`$4')"
        
        # Pattern 3: Person with birthDate and deathDate
        $content = $content -replace "const Person\(\s*\n\s*id:\s*'([^']+)',\s*\n\s*name:\s*'([^']+)',\s*\n\s*gender:\s*'([^']+)',\s*\n\s*birthDate:\s*'([^']+)',\s*\n\s*deathDate:\s*'([^']+)',\s*\n\s*\)", "const Person(`n        id: '`$1',`n        name: '`$2',`n        gender: '`$3',`n        phone: '',`n        birthDate: '`$4',`n        deathDate: '`$5',`n      )"
        
        # Pattern 4: Person with just birthDate  
        $content = $content -replace "const Person\(\s*\n\s*id:\s*'([^']+)',\s*\n\s*name:\s*'([^']+)',\s*\n\s*gender:\s*'([^']+)',\s*\n\s*birthDate:\s*'([^']+)',\s*\n\s*\)", "const Person(`n        id: '`$1',`n        name: '`$2',`n        gender: '`$3',`n        phone: '',`n        birthDate: '`$4',`n      )"
        
        $content | Set-Content $fullPath -NoNewline
        Write-Host "Fixed $file" -ForegroundColor Green
    } else {
        Write-Host "File not found: $fullPath" -ForegroundColor Red
    }
}

Write-Host "`nAll test files have been fixed!" -ForegroundColor Green
