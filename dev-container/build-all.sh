#!/bin/bash
set -e

# Build O3DE engine and optionally a project
# Usage: ./build-all.sh [--project <path>] [--config debug|profile|release] [--create]
#
# Examples:
#   ./build-all.sh                                    # Build engine only
#   ./build-all.sh --project AutomatedTesting         # Build engine + AutomatedTesting
#   ./build-all.sh --project MyProject --create       # Create + build new project
#   ./build-all.sh --project MyProject --create --template MinimalProject

O3DE_ROOT="${O3DE_ROOT:-$(pwd)}"
PROJECT_PATH=""
CONFIGURATION="${CONFIGURATION:-debug}"
SKIP_ENGINE=false
CREATE_PROJECT=false
TEMPLATE_NAME="DefaultProject"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --project|-p)
            PROJECT_PATH="$2"
            shift 2
            ;;
        --config|-c)
            CONFIGURATION="$2"
            shift 2
            ;;
        --skip-engine)
            SKIP_ENGINE=true
            shift
            ;;
        --create)
            CREATE_PROJECT=true
            shift
            ;;
        --template|-t)
            TEMPLATE_NAME="$2"
            shift 2
            ;;
        --help|-h)
            echo "Usage: $0 [--project <path>] [--config debug|profile|release] [--skip-engine] [--create] [--template <name>]"
            echo ""
            echo "Options:"
            echo "  --project, -p     Path to project (relative to O3DE root, or absolute)"
            echo "  --config, -c      Build configuration: debug, profile, or release (default: debug)"
            echo "  --skip-engine     Skip engine build, only build project"
            echo "  --create          Create the project if it doesn't exist"
            echo "  --template, -t    Template to use when creating (default: DefaultProject)"
            echo "                    Available: DefaultProject, MinimalProject, ScriptOnlyProject"
            echo ""
            echo "Examples:"
            echo "  $0                                        # Build engine only"
            echo "  $0 --project AutomatedTesting             # Build engine + existing project"
            echo "  $0 --project MyProject --create           # Create + build new project"
            echo "  $0 --project MyProject --create --skip-engine  # Create + build (no engine rebuild)"
            echo "  $0 --project MyProject --create --template MinimalProject"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

echo "=============================================="
echo "O3DE Build Script"
echo "=============================================="
echo "O3DE Root:     $O3DE_ROOT"
echo "Configuration: $CONFIGURATION"
echo "Project:       ${PROJECT_PATH:-<none>}"
echo "Create:        $CREATE_PROJECT"
echo "Template:      $TEMPLATE_NAME"
echo "Skip Engine:   $SKIP_ENGINE"
echo "=============================================="

# Bootstrap Python (needed for both engine and project builds)
echo ""
echo "[build] Bootstrapping Python..."
"${O3DE_ROOT}/python/get_python.sh"

# Build the engine
if [ "$SKIP_ENGINE" = false ]; then
    echo ""
    echo "=============================================="
    echo "[build] Building O3DE Engine..."
    echo "=============================================="

    export CONFIGURATION
    export CMAKE_TARGET="Editor"
    export OUTPUT_DIRECTORY="$O3DE_ROOT/build"
    export CMAKE_OPTIONS="-G \"Ninja Multi-Config\" -DLY_PARALLEL_LINK_JOBS=4 -DLY_DISABLE_TEST_MODULES=TRUE -DCMAKE_EXPORT_COMPILE_COMMANDS=ON"

    (
        cd "$O3DE_ROOT"
        "$O3DE_ROOT/scripts/build/Platform/Linux/build_linux.sh"
    )

    echo "[build] Engine build complete."
fi

# Build the project if specified
if [ -n "$PROJECT_PATH" ]; then
    echo ""
    echo "=============================================="
    echo "[build] Processing Project: $PROJECT_PATH"
    echo "=============================================="

    # Resolve project path
    if [[ "$PROJECT_PATH" = /* ]]; then
        # Absolute path
        FULL_PROJECT_PATH="$PROJECT_PATH"
    else
        # Relative to O3DE root
        FULL_PROJECT_PATH="$O3DE_ROOT/$PROJECT_PATH"
    fi

    # Extract project name from path (last component)
    PROJECT_NAME=$(basename "$FULL_PROJECT_PATH")

    # Create project if requested and doesn't exist
    if [ "$CREATE_PROJECT" = true ] && [ ! -f "$FULL_PROJECT_PATH/project.json" ]; then
        echo "[build] Creating new project: $PROJECT_NAME"
        echo "[build] Template: $TEMPLATE_NAME"
        echo "[build] Path: $FULL_PROJECT_PATH"

        TEMPLATE_PATH="$O3DE_ROOT/Templates/$TEMPLATE_NAME"
        if [ ! -d "$TEMPLATE_PATH" ]; then
            echo "[build] ERROR: Template not found at $TEMPLATE_PATH"
            echo "[build] Available templates:"
            ls -1 "$O3DE_ROOT/Templates/" | grep -E "Project$"
            exit 1
        fi

        "$O3DE_ROOT/scripts/o3de.sh" create-project \
            --project-path "$FULL_PROJECT_PATH" \
            --project-name "$PROJECT_NAME" \
            --template-path "$TEMPLATE_PATH"

        echo "[build] Project created successfully."
    fi

    # Verify project exists
    if [ ! -f "$FULL_PROJECT_PATH/project.json" ]; then
        echo "[build] ERROR: project.json not found at $FULL_PROJECT_PATH"
        echo "[build] Use --create to create a new project, or check the path."
        exit 1
    fi

    # Read actual project name from project.json (may differ from folder name)
    PROJECT_NAME=$(grep -o '"project_name"[[:space:]]*:[[:space:]]*"[^"]*"' "$FULL_PROJECT_PATH/project.json" | cut -d'"' -f4)
    PROJECT_BUILD_DIR="$FULL_PROJECT_PATH/build"

    echo "[build] Project name: $PROJECT_NAME"
    echo "[build] Project path: $FULL_PROJECT_PATH"
    echo "[build] Build directory: $PROJECT_BUILD_DIR"

    mkdir -p "$PROJECT_BUILD_DIR"
    cd "$PROJECT_BUILD_DIR"

    # Register the project with the engine
    echo "[build] Registering project with engine..."
    "$O3DE_ROOT/scripts/o3de.sh" register --project-path "$FULL_PROJECT_PATH"

    # Configure the project
    echo "[build] Configuring project..."
    cmake -B . -S "$FULL_PROJECT_PATH" \
        -G "Ninja Multi-Config" \
        -DLY_PARALLEL_LINK_JOBS=4 \
        -DCMAKE_EXPORT_COMPILE_COMMANDS=ON

    # Build the project
    echo "[build] Building project..."
    cmake --build . --target "${PROJECT_NAME}.GameLauncher" "${PROJECT_NAME}.ServerLauncher" Editor --config "$CONFIGURATION" -j$(nproc)

    echo "[build] Project build complete."
    echo "[build] Binaries at: $PROJECT_BUILD_DIR/bin/$CONFIGURATION/"
fi

echo ""
echo "=============================================="
echo "[build] All builds complete!"
echo "=============================================="

# Print next steps
if [ -n "$PROJECT_PATH" ]; then
    echo ""
    echo "Next steps:"
    echo "  # Run the Editor (requires display):"
    echo "  $FULL_PROJECT_PATH/build/bin/$CONFIGURATION/Editor"
    echo ""
    echo "  # Run the Game Launcher:"
    echo "  $FULL_PROJECT_PATH/build/bin/$CONFIGURATION/${PROJECT_NAME}.GameLauncher"
fi
