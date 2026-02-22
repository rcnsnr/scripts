#!/bin/bash

# LOC Counter v2 - Multi-language support with independent counting
# Supports hybrid projects (Go + Python + TypeScript/JavaScript)

set -euo pipefail

# Config
WORKS_DIR="/home/orcun/Documents/works"
OUTPUT_FILE="/home/orcun/Documents/works/works-files/docs/loc_counts.md"
DATE=$(date +"%Y-%m-%d %H:%M:%S")

# Projects to analyze
PROJECTS=("ctb" "cps" "trustlayer")

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}📊 LOC Counter v2 - Multi-language Analysis${NC}"
echo "========================================="

# Create output file header
cat > "$OUTPUT_FILE" << EOF
# Lines of Code (LOC) Analysis

Generated: $DATE

> Sadece development kodları dahil edilmiştir
> (vendor, node_modules, docs, .git, test dosyaları hariç)

---

EOF

# Function to count Python files
count_python() {
    local project_dir=$1
    
    cd "$project_dir"
    
    # Count Python files (excluding tests, docs, vendor, venv)
    python_files=$(find . -type f -name "*.py" \
        ! -path "./tests/*" \
        ! -path "./test/*" \
        ! -path "./.venv/*" \
        ! -path "./venv/*" \
        ! -path "./.lite-venv/*" \
        ! -path "./docs/*" \
        ! -path "./.git/*" \
        ! -path "./vendor/*" \
        ! -path "./__pycache__/*" \
        ! -name "*_test.py" \
        ! -name "test_*.py" 2>/dev/null | wc -l)
    
    if [[ $python_files -gt 0 ]]; then
        python_loc=$(find . -type f -name "*.py" \
            ! -path "./tests/*" \
            ! -path "./test/*" \
            ! -path "./.venv/*" \
            ! -path "./venv/*" \
            ! -path "./.lite-venv/*" \
            ! -path "./docs/*" \
            ! -path "./.git/*" \
            ! -path "./vendor/*" \
            ! -path "./__pycache__/*" \
            ! -name "*_test.py" \
            ! -name "test_*.py" -exec wc -l {} + 2>/dev/null | tail -1 | awk '{print $1}' || echo "0")
    else
        python_loc=0
    fi
    
    echo "$python_files $python_loc"
}

# Function to count Go files
count_go() {
    local project_dir=$1
    
    cd "$project_dir"

    # Skip Go counting if no module indicators
    if [[ ! -f "go.mod" && ! -f "go.sum" ]]; then
        echo "0 0"
        return
    fi
    
    # Count Go files (excluding vendor, docs, tests)
    go_files=$(find . -type f -name "*.go" \
        ! -path "./vendor/*" \
        ! -path "./docs/*" \
        ! -path "./.git/*" \
        ! -path "./*_test.go" \
        ! -path "./test/*" \
        ! -name "*_test.go" 2>/dev/null | wc -l)
    
    if [[ $go_files -gt 0 ]]; then
        go_loc=$(find . -type f -name "*.go" \
            ! -path "./vendor/*" \
            ! -path "./docs/*" \
            ! -path "./.git/*" \
            ! -path "./*_test.go" \
            ! -path "./test/*" \
            ! -name "*_test.go" -exec wc -l {} + 2>/dev/null | tail -1 | awk '{print $1}' || echo "0")
    else
        go_loc=0
    fi
    
    echo "$go_files $go_loc"
}

# Function to count TypeScript/JavaScript files
count_ts_js() {
    local project_dir=$1
    
    cd "$project_dir"
    
    # Count TS/JS files (excluding node_modules, docs, .git)
    ts_files=$(find . -type f \( -name "*.ts" -o -name "*.tsx" \) \
        ! -path "*/node_modules/*" \
        ! -path "./docs/*" \
        ! -path "./.git/*" \
        ! -path "./dist/*" \
        ! -path "./build/*" \
        ! -path "./.next/*" \
        ! -path "./coverage/*" \
        ! -path "./.cache/*" \
        ! -path "./__generated__/*" \
        ! -name "*.test.ts" \
        ! -name "*.spec.ts" 2>/dev/null | wc -l)
    
    if [[ $ts_files -gt 0 ]]; then
        ts_loc=$(find . -type f \( -name "*.ts" -o -name "*.tsx" \) \
            ! -path "*/node_modules/*" \
            ! -path "./docs/*" \
            ! -path "./.git/*" \
            ! -path "./dist/*" \
            ! -path "./build/*" \
            ! -path "./.next/*" \
            ! -path "./coverage/*" \
            ! -path "./.cache/*" \
            ! -path "./__generated__/*" \
            ! -name "*.test.ts" \
            ! -name "*.spec.ts" -exec wc -l {} + 2>/dev/null | tail -1 | awk '{print $1}' || echo "0")
    else
        ts_loc=0
    fi
    
    js_files=$(find . -type f \( -name "*.js" -o -name "*.jsx" \) \
        ! -path "*/node_modules/*" \
        ! -path "./docs/*" \
        ! -path "./.git/*" \
        ! -path "./dist/*" \
        ! -path "./build/*" \
        ! -path "./.next/*" \
        ! -path "./coverage/*" \
        ! -path "./.cache/*" \
        ! -path "./__generated__/*" \
        ! -name "*.test.js" \
        ! -name "*.spec.js" 2>/dev/null | wc -l)
    
    if [[ $js_files -gt 0 ]]; then
        js_loc=$(find . -type f \( -name "*.js" -o -name "*.jsx" \) \
            ! -path "*/node_modules/*" \
            ! -path "./docs/*" \
            ! -path "./.git/*" \
            ! -path "./dist/*" \
            ! -path "./build/*" \
            ! -path "./.next/*" \
            ! -path "./coverage/*" \
            ! -path "./.cache/*" \
            ! -path "./__generated__/*" \
            ! -name "*.test.js" \
            ! -name "*.spec.js" -exec wc -l {} + 2>/dev/null | tail -1 | awk '{print $1}' || echo "0")
    else
        js_loc=0
    fi
    
    echo "$((ts_files + js_files)) $((ts_loc + js_loc))"
}

# Generic counter for multiple extensions
count_generic() {
    local project_dir=$1
    shift
    local patterns=("$@")

    cd "$project_dir"

    if [[ ${#patterns[@]} -eq 0 ]]; then
        echo "0 0"
        return
    fi

    # Prefer git ls-files to avoid venv/node_modules/etc tracked dışı dosyalar
    if command -v git >/dev/null 2>&1 && [[ -d "$project_dir/.git" ]]; then
        files_list=$(git -C "$project_dir" ls-files -- "${patterns[@]}" 2>/dev/null | \
            grep -Ev '(^tests/|/tests/|/test/|_test\.|\.test\.|\.spec\.)' | \
            grep -Ev '(^docs/|^vendor/|^node_modules/|^dist/|^build/|^\.next/|^coverage/|^htmlcov/|^\.cache/|^__generated__/|^\.venv/|^venv/|^\.lite-venv/|site-packages/|dist-packages/)' )

        if [[ -n "$files_list" ]]; then
            files=$(printf "%s\n" "$files_list" | sed '/^$/d' | wc -l)
            loc=$(printf "%s\n" "$files_list" | xargs -r -P 4 -I{} wc -l "$project_dir/{}" 2>/dev/null | awk '{s+=$1} END {print s+0}')
            echo "$files $loc"
            return
        fi
    fi

    local find_args=(find "$project_dir" -type f "(")
    for i in "${!patterns[@]}"; do
        find_args+=(-name "${patterns[$i]}")
        if [[ $i -lt $((${#patterns[@]}-1)) ]]; then
            find_args+=(-o)
        fi
    done
    find_args+=("\)")
    find_args+=(! -path "*/.git/*" ! -path "*/docs/*" ! -path "*/vendor/*" ! -path "*/node_modules/*")
    find_args+=(! -path "*/dist/*" ! -path "*/build/*" ! -path "*/.next/*" ! -path "*/coverage/*" ! -path "*/htmlcov/*")
    find_args+=(! -path "*/.cache/*" ! -path "*/__generated__/*" ! -path "*/.venv/*" ! -path "*/venv/*" ! -path "*/.lite-venv/*")
    find_args+=(! -path "*/site-packages/*" ! -path "*/dist-packages/*" ! -path "*/__pycache__/*" ! -path "*/.mypy_cache/*" ! -path "*/.pytest_cache/*" ! -path "*/.ruff_cache/*")
    find_args+=(! -path "*/.idea/*" ! -path "*/.vscode/*" ! -path "*/.tox/*" ! -path "*/.eval/*" ! -path "*/.mypy_cache/*")
    find_args+=(! -path "*/tests/*" ! -path "*/test/*" ! -name "*_test.*" ! -name "*.test.*" ! -name "*.spec.*")

    files=$("${find_args[@]}" 2>/dev/null | wc -l)
    if [[ $files -gt 0 ]]; then
        loc=$("${find_args[@]}" -exec wc -l {} + 2>/dev/null | tail -1 | awk '{print $1}' || echo "0")
    else
        loc=0
    fi

    echo "$files $loc"
}

# Function to count C/C++ files (including wrappers)
count_cpp() {
    local project_dir=$1

    cd "$project_dir"

    cpp_files=$(find . -type f \( -name "*.c" -o -name "*.cc" -o -name "*.cpp" -o -name "*.cxx" -o -name "*.h" -o -name "*.hpp" \) \
        ! -path "./vendor/*" \
        ! -path "./docs/*" \
        ! -path "./.git/*" \
        ! -path "./build/*" \
        ! -path "./dist/*" \
        ! -path "./.next/*" \
        ! -path "./node_modules/*" \
        ! -path "./venv/*" \
        ! -path "./.venv/*" \
        ! -path "./.lite-venv/*" \
        ! -name "*_test.*" \
        ! -path "./test/*" 2>/dev/null | wc -l)

    if [[ $cpp_files -gt 0 ]]; then
        cpp_loc=$(find . -type f \( -name "*.c" -o -name "*.cc" -o -name "*.cpp" -o -name "*.cxx" -o -name "*.h" -o -name "*.hpp" \) \
            ! -path "./vendor/*" \
            ! -path "./docs/*" \
            ! -path "./.git/*" \
            ! -path "./build/*" \
            ! -path "./dist/*" \
            ! -path "./.next/*" \
            ! -path "./node_modules/*" \
            ! -path "./venv/*" \
            ! -path "./.venv/*" \
            ! -path "./.lite-venv/*" \
            ! -name "*_test.*" \
            ! -path "./test/*" -exec wc -l {} + 2>/dev/null | tail -1 | awk '{print $1}' || echo "0")
    else
        cpp_loc=0
    fi

    echo "$cpp_files $cpp_loc"
}

# Function to count Cython files
count_cython() {
    local project_dir=$1

    cd "$project_dir"

    cython_files=$(find . -type f \( -name "*.pyx" -o -name "*.pxd" -o -name "*.pxi" \) \
        ! -path "./tests/*" \
        ! -path "./test/*" \
        ! -path "./vendor/*" \
        ! -path "./docs/*" \
        ! -path "./.git/*" \
        ! -path "./venv/*" \
        ! -path "./.venv/*" \
        ! -path "./.lite-venv/*" \
        ! -path "*/site-packages/*" \
        ! -path "*/dist-packages/*" \
        ! -path "./node_modules/*" 2>/dev/null | wc -l)

    if [[ $cython_files -gt 0 ]]; then
        cython_loc=$(find . -type f \( -name "*.pyx" -o -name "*.pxd" -o -name "*.pxi" \) \
            ! -path "./tests/*" \
            ! -path "./test/*" \
            ! -path "./vendor/*" \
            ! -path "./docs/*" \
            ! -path "./.git/*" \
            ! -path "./venv/*" \
            ! -path "./.venv/*" \
            ! -path "./.lite-venv/*" \
            ! -path "*/site-packages/*" \
            ! -path "*/dist-packages/*" \
            ! -path "./node_modules/*" -exec wc -l {} + 2>/dev/null | tail -1 | awk '{print $1}' || echo "0")
    else
        cython_loc=0
    fi

    echo "$cython_files $cython_loc"
}

# Function to count configuration files
count_config() {
    local project_dir=$1
    
    cd "$project_dir"
    
    config_files=$(find . -type f \( \
        -name "*.yml" -o -name "*.yaml" -o -name "*.json" -o -name "*.toml" -o \
        -name "Dockerfile*" -o -name "*.dockerfile" -o -name "docker-compose*" -o \
        -name "*.env*" -o -name "*.ini" -o -name "*.cfg" -o -name "*.conf" -o \
        -name "Makefile" -o -name "*.mk" -o -name "*.sh" -o -name "*.sql" \) \
        ! -path "./.git/*" \
        ! -path "./docs/*" \
        ! -path "*/vendor/*" \
        ! -path "*/node_modules/*" \
        ! -path "*/.venv/*" \
        ! -path "*/venv/*" \
        ! -path "*/.lite-venv/*" 2>/dev/null | wc -l)
    
    if [[ $config_files -gt 0 ]]; then
        config_loc=$(find . -type f \( \
            -name "*.yml" -o -name "*.yaml" -o -name "*.json" -o -name "*.toml" -o \
            -name "Dockerfile*" -o -name "*.dockerfile" -o -name "docker-compose*" -o \
            -name "*.env*" -o -name "*.ini" -o -name "*.cfg" -o -name "*.conf" -o \
            -name "Makefile" -o -name "*.mk" -o -name "*.sh" -o -name "*.sql" \) \
            ! -path "./.git/*" \
            ! -path "./docs/*" \
            ! -path "*/vendor/*" \
            ! -path "*/node_modules/*" \
            ! -path "*/.venv/*" \
            ! -path "*/venv/*" \
            ! -path "*/.lite-venv/*" -exec wc -l {} + 2>/dev/null | tail -1 | awk '{print $1}' || echo "0")
    else
        config_loc=0
    fi
    
    echo "$config_files $config_loc"
}

# Function to analyze a project
analyze_project() {
    local project=$1
    local project_dir="$WORKS_DIR/$project"
    
    if [[ ! -d "$project_dir" ]]; then
        echo -e "${RED}❌ Project directory not found: $project_dir${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}🔍 Analyzing: $project${NC}"
    
    # Count each language independently
    python_result=$(count_python "$project_dir")
    go_result=$(count_go "$project_dir")
    tsjs_result=$(count_ts_js "$project_dir")
    cpp_result=$(count_cpp "$project_dir")
    cython_result=$(count_cython "$project_dir")
    rust_result=$(count_generic "$project_dir" "*.rs")
    java_result=$(count_generic "$project_dir" "*.java")
    kotlin_result=$(count_generic "$project_dir" "*.kt" "*.kts")
    scala_result=$(count_generic "$project_dir" "*.scala")
    swift_result=$(count_generic "$project_dir" "*.swift")
    objc_result=$(count_generic "$project_dir" "*.m" "*.mm")
    cs_result=$(count_generic "$project_dir" "*.cs")
    php_result=$(count_generic "$project_dir" "*.php")
    ruby_result=$(count_generic "$project_dir" "*.rb")
    elixir_result=$(count_generic "$project_dir" "*.ex" "*.exs")
    erlang_result=$(count_generic "$project_dir" "*.erl" "*.hrl")
    dart_result=$(count_generic "$project_dir" "*.dart")
    solidity_result=$(count_generic "$project_dir" "*.sol")
    shell_result=$(count_generic "$project_dir" "*.sh")
    lua_result=$(count_generic "$project_dir" "*.lua")
    haskell_result=$(count_generic "$project_dir" "*.hs" "*.lhs")
    r_result=$(count_generic "$project_dir" "*.R" "*.r")
    julia_result=$(count_generic "$project_dir" "*.jl")
    clojure_result=$(count_generic "$project_dir" "*.clj" "*.cljs" "*.cljc")
    config_result=$(count_config "$project_dir")
    
    # Parse results
    python_files=$(echo $python_result | cut -d' ' -f1)
    python_loc=$(echo $python_result | cut -d' ' -f2)
    
    go_files=$(echo $go_result | cut -d' ' -f1)
    go_loc=$(echo $go_result | cut -d' ' -f2)
    
    tsjs_files=$(echo $tsjs_result | cut -d' ' -f1)
    tsjs_loc=$(echo $tsjs_result | cut -d' ' -f2)
    
    cpp_files=$(echo $cpp_result | cut -d' ' -f1)
    cpp_loc=$(echo $cpp_result | cut -d' ' -f2)

    cython_files=$(echo $cython_result | cut -d' ' -f1)
    cython_loc=$(echo $cython_result | cut -d' ' -f2)

    rust_files=$(echo $rust_result | cut -d' ' -f1)
    rust_loc=$(echo $rust_result | cut -d' ' -f2)

    java_files=$(echo $java_result | cut -d' ' -f1)
    java_loc=$(echo $java_result | cut -d' ' -f2)

    kotlin_files=$(echo $kotlin_result | cut -d' ' -f1)
    kotlin_loc=$(echo $kotlin_result | cut -d' ' -f2)

    scala_files=$(echo $scala_result | cut -d' ' -f1)
    scala_loc=$(echo $scala_result | cut -d' ' -f2)

    swift_files=$(echo $swift_result | cut -d' ' -f1)
    swift_loc=$(echo $swift_result | cut -d' ' -f2)

    objc_files=$(echo $objc_result | cut -d' ' -f1)
    objc_loc=$(echo $objc_result | cut -d' ' -f2)

    cs_files=$(echo $cs_result | cut -d' ' -f1)
    cs_loc=$(echo $cs_result | cut -d' ' -f2)

    php_files=$(echo $php_result | cut -d' ' -f1)
    php_loc=$(echo $php_result | cut -d' ' -f2)

    ruby_files=$(echo $ruby_result | cut -d' ' -f1)
    ruby_loc=$(echo $ruby_result | cut -d' ' -f2)

    elixir_files=$(echo $elixir_result | cut -d' ' -f1)
    elixir_loc=$(echo $elixir_result | cut -d' ' -f2)

    erlang_files=$(echo $erlang_result | cut -d' ' -f1)
    erlang_loc=$(echo $erlang_result | cut -d' ' -f2)

    dart_files=$(echo $dart_result | cut -d' ' -f1)
    dart_loc=$(echo $dart_result | cut -d' ' -f2)

    solidity_files=$(echo $solidity_result | cut -d' ' -f1)
    solidity_loc=$(echo $solidity_result | cut -d' ' -f2)

    shell_files=$(echo $shell_result | cut -d' ' -f1)
    shell_loc=$(echo $shell_result | cut -d' ' -f2)

    lua_files=$(echo $lua_result | cut -d' ' -f1)
    lua_loc=$(echo $lua_result | cut -d' ' -f2)

    haskell_files=$(echo $haskell_result | cut -d' ' -f1)
    haskell_loc=$(echo $haskell_result | cut -d' ' -f2)

    r_files=$(echo $r_result | cut -d' ' -f1)
    r_loc=$(echo $r_result | cut -d' ' -f2)

    julia_files=$(echo $julia_result | cut -d' ' -f1)
    julia_loc=$(echo $julia_result | cut -d' ' -f2)

    clojure_files=$(echo $clojure_result | cut -d' ' -f1)
    clojure_loc=$(echo $clojure_result | cut -d' ' -f2)

    config_files=$(echo $config_result | cut -d' ' -f1)
    config_loc=$(echo $config_result | cut -d' ' -f2)
    
    # Calculate totals (only for present languages)
    total_files=0
    total_loc=0
    
    # Write to output
    cat >> "$OUTPUT_FILE" << EOF
## $project

| Language | Files | Lines |
|----------|-------|-------|
EOF
    
    if [[ $python_files -gt 0 ]]; then
        echo "| Python | $python_files | $python_loc |" >> "$OUTPUT_FILE"
        total_files=$((total_files + python_files))
        total_loc=$((total_loc + python_loc))
    fi
    
    if [[ $go_files -gt 0 ]]; then
        echo "| Go | $go_files | $go_loc |" >> "$OUTPUT_FILE"
        total_files=$((total_files + go_files))
        total_loc=$((total_loc + go_loc))
    fi
    
    if [[ $tsjs_files -gt 0 ]]; then
        echo "| TypeScript/JS | $tsjs_files | $tsjs_loc |" >> "$OUTPUT_FILE"
        total_files=$((total_files + tsjs_files))
        total_loc=$((total_loc + tsjs_loc))
    fi

    if [[ $cpp_files -gt 0 ]]; then
        echo "| C/C++ | $cpp_files | $cpp_loc |" >> "$OUTPUT_FILE"
        total_files=$((total_files + cpp_files))
        total_loc=$((total_loc + cpp_loc))
    fi

    if [[ $cython_files -gt 0 ]]; then
        echo "| Cython | $cython_files | $cython_loc |" >> "$OUTPUT_FILE"
        total_files=$((total_files + cython_files))
        total_loc=$((total_loc + cython_loc))
    fi

    if [[ $rust_files -gt 0 ]]; then
        echo "| Rust | $rust_files | $rust_loc |" >> "$OUTPUT_FILE"
        total_files=$((total_files + rust_files))
        total_loc=$((total_loc + rust_loc))
    fi

    if [[ $java_files -gt 0 ]]; then
        echo "| Java | $java_files | $java_loc |" >> "$OUTPUT_FILE"
        total_files=$((total_files + java_files))
        total_loc=$((total_loc + java_loc))
    fi

    if [[ $kotlin_files -gt 0 ]]; then
        echo "| Kotlin | $kotlin_files | $kotlin_loc |" >> "$OUTPUT_FILE"
        total_files=$((total_files + kotlin_files))
        total_loc=$((total_loc + kotlin_loc))
    fi

    if [[ $scala_files -gt 0 ]]; then
        echo "| Scala | $scala_files | $scala_loc |" >> "$OUTPUT_FILE"
        total_files=$((total_files + scala_files))
        total_loc=$((total_loc + scala_loc))
    fi

    if [[ $swift_files -gt 0 ]]; then
        echo "| Swift | $swift_files | $swift_loc |" >> "$OUTPUT_FILE"
        total_files=$((total_files + swift_files))
        total_loc=$((total_loc + swift_loc))
    fi

    if [[ $objc_files -gt 0 ]]; then
        echo "| Objective-C | $objc_files | $objc_loc |" >> "$OUTPUT_FILE"
        total_files=$((total_files + objc_files))
        total_loc=$((total_loc + objc_loc))
    fi

    if [[ $cs_files -gt 0 ]]; then
        echo "| C# | $cs_files | $cs_loc |" >> "$OUTPUT_FILE"
        total_files=$((total_files + cs_files))
        total_loc=$((total_loc + cs_loc))
    fi

    if [[ $php_files -gt 0 ]]; then
        echo "| PHP | $php_files | $php_loc |" >> "$OUTPUT_FILE"
        total_files=$((total_files + php_files))
        total_loc=$((total_loc + php_loc))
    fi

    if [[ $ruby_files -gt 0 ]]; then
        echo "| Ruby | $ruby_files | $ruby_loc |" >> "$OUTPUT_FILE"
        total_files=$((total_files + ruby_files))
        total_loc=$((total_loc + ruby_loc))
    fi

    if [[ $elixir_files -gt 0 ]]; then
        echo "| Elixir | $elixir_files | $elixir_loc |" >> "$OUTPUT_FILE"
        total_files=$((total_files + elixir_files))
        total_loc=$((total_loc + elixir_loc))
    fi

    if [[ $erlang_files -gt 0 ]]; then
        echo "| Erlang | $erlang_files | $erlang_loc |" >> "$OUTPUT_FILE"
        total_files=$((total_files + erlang_files))
        total_loc=$((total_loc + erlang_loc))
    fi

    if [[ $dart_files -gt 0 ]]; then
        echo "| Dart | $dart_files | $dart_loc |" >> "$OUTPUT_FILE"
        total_files=$((total_files + dart_files))
        total_loc=$((total_loc + dart_loc))
    fi

    if [[ $solidity_files -gt 0 ]]; then
        echo "| Solidity | $solidity_files | $solidity_loc |" >> "$OUTPUT_FILE"
        total_files=$((total_files + solidity_files))
        total_loc=$((total_loc + solidity_loc))
    fi

    if [[ $shell_files -gt 0 ]]; then
        echo "| Shell | $shell_files | $shell_loc |" >> "$OUTPUT_FILE"
        total_files=$((total_files + shell_files))
        total_loc=$((total_loc + shell_loc))
    fi

    if [[ $lua_files -gt 0 ]]; then
        echo "| Lua | $lua_files | $lua_loc |" >> "$OUTPUT_FILE"
        total_files=$((total_files + lua_files))
        total_loc=$((total_loc + lua_loc))
    fi

    if [[ $haskell_files -gt 0 ]]; then
        echo "| Haskell | $haskell_files | $haskell_loc |" >> "$OUTPUT_FILE"
        total_files=$((total_files + haskell_files))
        total_loc=$((total_loc + haskell_loc))
    fi

    if [[ $r_files -gt 0 ]]; then
        echo "| R | $r_files | $r_loc |" >> "$OUTPUT_FILE"
        total_files=$((total_files + r_files))
        total_loc=$((total_loc + r_loc))
    fi

    if [[ $julia_files -gt 0 ]]; then
        echo "| Julia | $julia_files | $julia_loc |" >> "$OUTPUT_FILE"
        total_files=$((total_files + julia_files))
        total_loc=$((total_loc + julia_loc))
    fi

    if [[ $clojure_files -gt 0 ]]; then
        echo "| Clojure | $clojure_files | $clojure_loc |" >> "$OUTPUT_FILE"
        total_files=$((total_files + clojure_files))
        total_loc=$((total_loc + clojure_loc))
    fi
    
    if [[ $config_files -gt 0 ]]; then
        echo "| Config | $config_files | $config_loc |" >> "$OUTPUT_FILE"
        total_files=$((total_files + config_files))
        total_loc=$((total_loc + config_loc))
    fi

    echo "| **Total** | **$total_files** | **$total_loc** |" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    
    # Print summary
    if [[ $python_files -gt 0 ]]; then
        echo -e "  🐍 Python: $python_files files ($python_loc lines)"
    fi
    if [[ $go_files -gt 0 ]]; then
        echo -e "  🐹 Go: $go_files files ($go_loc lines)"
    fi
    if [[ $tsjs_files -gt 0 ]]; then
        echo -e "  📜 TS/JS: $tsjs_files files ($tsjs_loc lines)"
    fi
    echo -e "  ⚙️  Config: $config_files files ($config_loc lines)"
    echo ""
}

# Main execution
echo ""
echo "Analyzing projects..."
echo ""

for project in "${PROJECTS[@]}"; do
    analyze_project "$project"
done

# Add summary with quoted EOF to prevent expansion
cat >> "$OUTPUT_FILE" << 'EOF'
---

## Summary

> Bu rapor otomatik olarak `loc_counter_v2.sh` script'i ile oluşturulmuştur
> Sadece development kodları dahil edilmiştir

### Exclusions

- Test files (`*_test.py`, `test_*.py`, `*_test.go`, `*.test.ts`, `*.spec.ts`)
- Documentation (`docs/`)
- Dependencies (`vendor/`, `node_modules/`, `venv/`)
- Version control (`.git/`)
- Build artifacts (`__pycache__/`, `dist/`, `build/`)

### Usage

```bash
# Run analysis
./loc_counter_v2.sh

# View results
cat docs/loc_counts.md
```

### Features

- Multi-language support (Python, Go, TypeScript/JavaScript)
- Hybrid project detection
- Config files included
- Test and dependency exclusion

---

EOF

echo -e "${GREEN}✅ Analysis complete!${NC}"
echo -e "${BLUE}📄 Report saved to: $OUTPUT_FILE${NC}"
echo ""
