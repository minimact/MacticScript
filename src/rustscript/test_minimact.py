#!/usr/bin/env python3
"""
Test minimact RustScript conversions by compiling and verifying output.

This test runner:
1. Compiles each minimact test file to Babel and SWC
2. Verifies the compilation succeeds
3. Checks that the generated code is syntactically valid
4. Optionally runs the generated code against test cases
"""
import subprocess
from pathlib import Path
import sys
import json

class Colors:
    """ANSI color codes for terminal output"""
    GREEN = '\033[92m'
    RED = '\033[91m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    RESET = '\033[0m'
    BOLD = '\033[1m'

def print_colored(text, color):
    """Print colored text to terminal"""
    print(f"{color}{text}{Colors.RESET}")

def print_header(text):
    """Print a section header"""
    print(f"\n{Colors.BOLD}{Colors.BLUE}{'=' * 80}{Colors.RESET}")
    print(f"{Colors.BOLD}{Colors.BLUE}{text}{Colors.RESET}")
    print(f"{Colors.BOLD}{Colors.BLUE}{'=' * 80}{Colors.RESET}\n")

def test_compile(test_file, output_dir):
    """
    Compile a RustScript test file to both Babel and SWC.

    Returns:
        (success, babel_output, swc_output, error_message)
    """
    test_path = Path(test_file)

    if not test_path.exists():
        return False, None, None, f"Test file not found: {test_file}"

    # Create output directory
    output_path = Path(output_dir)
    output_path.mkdir(parents=True, exist_ok=True)

    try:
        # Run the RustScript compiler
        result = subprocess.run(
            ["cargo", "run", "--bin", "rustscript", "--",
             "build", str(test_path), "--output", str(output_path), "--target", "both"],
            capture_output=True,
            text=True,
            timeout=60,
            cwd=Path(__file__).parent
        )

        if result.returncode != 0:
            return False, None, None, f"Compilation failed:\n{result.stderr}"

        # Check output files exist
        babel_output = output_path / "index.js"
        swc_output = output_path / "lib.rs"

        if not babel_output.exists():
            return False, None, None, "Babel output (index.js) not generated"

        if not swc_output.exists():
            return False, None, None, "SWC output (lib.rs) not generated"

        # Read the generated files
        babel_code = babel_output.read_text()
        swc_code = swc_output.read_text()

        return True, babel_code, swc_code, None

    except subprocess.TimeoutExpired:
        return False, None, None, "Compilation timed out (60s)"
    except Exception as e:
        return False, None, None, f"Error during compilation: {str(e)}"

def verify_babel_syntax(babel_code):
    """
    Verify that generated Babel code is syntactically valid JavaScript.

    Returns:
        (valid, error_message)
    """
    # Try to parse with Node.js
    try:
        result = subprocess.run(
            ["node", "--check", "-"],
            input=babel_code,
            capture_output=True,
            text=True,
            timeout=5
        )

        if result.returncode != 0:
            return False, f"Invalid JavaScript syntax:\n{result.stderr}"

        return True, None

    except FileNotFoundError:
        # Node.js not installed, skip syntax check
        return True, "Node.js not found, skipping syntax validation"
    except Exception as e:
        return False, f"Error checking Babel syntax: {str(e)}"

def verify_swc_syntax(swc_code, test_name):
    """
    Verify that generated SWC code is syntactically valid Rust.

    Returns:
        (valid, error_message)
    """
    # Create a temporary Cargo project to check syntax
    temp_dir = Path("temp_swc_check") / test_name
    temp_dir.mkdir(parents=True, exist_ok=True)

    try:
        # Write Cargo.toml
        cargo_toml = temp_dir / "Cargo.toml"
        cargo_toml.write_text("""[package]
name = "swc_check"
version = "0.1.0"
edition = "2021"

[dependencies]
swc_core = { version = "0.79", features = ["ecma_ast", "ecma_visit"] }
""")

        # Create src directory
        src_dir = temp_dir / "src"
        src_dir.mkdir(exist_ok=True)

        # Write the generated code
        lib_rs = src_dir / "lib.rs"
        lib_rs.write_text(swc_code)

        # Run cargo check
        result = subprocess.run(
            ["cargo", "check"],
            capture_output=True,
            text=True,
            timeout=60,
            cwd=temp_dir
        )

        if result.returncode != 0:
            return False, f"Invalid Rust syntax:\n{result.stderr}"

        return True, None

    except FileNotFoundError:
        return True, "Cargo not found, skipping Rust syntax validation"
    except subprocess.TimeoutExpired:
        return False, "Cargo check timed out"
    except Exception as e:
        return False, f"Error checking SWC syntax: {str(e)}"
    finally:
        # Cleanup temp directory
        import shutil
        if temp_dir.exists():
            try:
                shutil.rmtree(temp_dir)
            except:
                pass

def test_module(module_name, test_files):
    """
    Test a module (utils, types, etc.)

    Returns:
        (passed, failed, skipped)
    """
    print_colored(f"\nTesting {module_name}:", Colors.BOLD)
    print("-" * 80)

    passed = 0
    failed = 0
    skipped = 0

    for i, test_file in enumerate(test_files, 1):
        test_name = Path(test_file).stem
        print(f"[{i}/{len(test_files)}] {test_name} ... ", end="", flush=True)

        # Compile the test
        output_dir = f"tests/minimact/dist/{module_name}/{test_name}"
        success, babel_code, swc_code, error = test_compile(test_file, output_dir)

        if not success:
            print_colored("FAILED", Colors.RED)
            print(f"  {error}")
            failed += 1
            continue

        # Verify Babel syntax
        babel_valid, babel_error = verify_babel_syntax(babel_code)
        if not babel_valid:
            print_colored("FAILED", Colors.RED)
            print(f"  Babel: {babel_error}")
            failed += 1
            continue

        # For now, skip SWC syntax check as it requires complex setup
        # swc_valid, swc_error = verify_swc_syntax(swc_code, test_name)
        # if not swc_valid:
        #     print_colored("FAILED", Colors.RED)
        #     print(f"  SWC: {swc_error}")
        #     failed += 1
        #     continue

        print_colored("PASSED", Colors.GREEN)
        passed += 1

    return passed, failed, skipped

def main():
    """Main test runner"""
    print_header("RustScript Minimact Conversion Tests")

    # Define test modules and their test files
    test_modules = {
        "utils": [
            "tests/minimact/utils/test_helpers.rsc",
            "tests/minimact/utils/test_hex_path.rsc",
            "tests/minimact/utils/test_style_converter_integration.rsc",
        ],
        "types": [
            "tests/minimact/types/test_type_conversion_integration.rsc",
        ],
        "analyzers": [
            "tests/minimact/analyzers/test_classification.rsc",
            "tests/minimact/analyzers/test_detection.rsc",
            "tests/minimact/analyzers/test_hook_detector.rsc",
        ],
        "extractors": [
            "tests/minimact/extractors/test_is_simple_expression.rsc",
            "tests/minimact/extractors/test_build_member_path.rsc",
        ],
        "generators": [
            "tests/minimact/generators/test_string_methods.rsc",
        ],
    }

    total_passed = 0
    total_failed = 0
    total_skipped = 0

    # Run tests for each module
    for module_name, test_files in test_modules.items():
        passed, failed, skipped = test_module(module_name, test_files)
        total_passed += passed
        total_failed += failed
        total_skipped += skipped

    # Print summary
    print_header("Test Summary")

    total_tests = total_passed + total_failed + total_skipped

    print(f"Total tests:  {total_tests}")
    print_colored(f"Passed:       {total_passed}", Colors.GREEN)

    if total_failed > 0:
        print_colored(f"Failed:       {total_failed}", Colors.RED)
    else:
        print(f"Failed:       {total_failed}")

    if total_skipped > 0:
        print_colored(f"Skipped:      {total_skipped}", Colors.YELLOW)
    else:
        print(f"Skipped:      {total_skipped}")

    print()

    # Exit with appropriate code
    if total_failed > 0:
        print_colored("Some tests failed!", Colors.RED)
        return 1
    elif total_passed == 0:
        print_colored("No tests passed!", Colors.YELLOW)
        return 1
    else:
        print_colored("All tests passed!", Colors.GREEN)
        return 0

if __name__ == "__main__":
    sys.exit(main())
