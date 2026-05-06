# openDAQ-CI

This repository contains reusable GitHub Actions CI workflows for openDAQ-based module projects.

## Table of Contents

- [Unified Reusable Workflow](#unified-reusable-workflow)
  - [Inputs](#inputs)
  - [Outputs](#outputs)
  - [Overview](#overview)
    - [Job Naming](#job-naming)
      - [Platform Naming](#platform-naming)
    - [Pipeline Configuration](#pipeline-configuration)
    - [Job Execution](#job-execution)
  - [Usage](#usage)
    - [Basic](#basic)
    - [Upstream Ref](#upstream-ref)
    - [Exclude Jobs](#exclude-jobs)
    - [Exclude Tests](#exclude-tests)
    - [Additional Packages](#additional-packages)
    - [Post-Package Command](#post-package-command)
    - [Rename Artifacts](#rename-artifacts)
- [License](#license)

## Unified Reusable Workflow

[![Test Reusable CI](https://github.com/openDAQ/openDAQ-CI/actions/workflows/test-reusable.yml/badge.svg)](https://github.com/openDAQ/openDAQ-CI/actions/workflows/test-reusable.yml)

The unified `reusable.yml` workflow is designed to provide a centralized approach to CI management and compatibility testing of openDAQ-based projects against upstream SDK. It dynamically configures CI pipelines from caller inputs — handling toolchain selection and environment setup — and orchestrates jobs across target platforms, architectures, and compilers.

### Inputs

```yaml
- uses: openDAQ/openDAQ-CI/.github/workflows/reusable.yml@main
  with:
    # Override openDAQ SDK git reference.
    # Format: tag, branch, or SHA
    # Optional: '' - empty string, resolved by the caller
    opendaq-ref: ''

    # Exclude matrix jobs by name.
    # Format: JSON array of strings
    # Pattern: wildcard
    # Optional: [] empty, no jobs excluded
    # Example: '["*-debug", "macos-*"]'
    exclude-jobs: ''

    # Install additional packages per job.
    # Format: JSON array of objects
    # Fields:
    #   match-jobs     — job names list (optional: ["*"] default)
    #   apt-install    — apt packages (optional, collect)
    #   pip-install    — pip packages (optional, collect)
    #   brew-install   — brew packages (optional, collect)
    #   choco-install  — choco packages (optional, collect)
    #   winget-install — winget packages (optional, collect)
    #   run            — run after packages setup (optional, last match wins)
    # Optional: [] empty, no extra packages
    # Example: >
    #   [
    #     {
    #       "match-jobs": ["ubuntu-*"],
    #       "apt-install": ["libpcap-dev", "mosquitto"],
    #       "run": "mosquitto -d"
    #     },
    #     {
    #       "match-jobs": ["windows-*"],
    #       "winget-install": ["EclipseFoundation.Mosquitto"]
    #     },
    #     {
    #       "match-jobs": ["macos-*"],
    #       "brew-install": ["mosquitto"],
    #       "run": "$(brew --prefix mosquitto)/sbin/mosquitto -d"
    #     }
    #   ]
    packages: ''

    # Map CMake presets to jobs.
    # Format: JSON array of objects
    # Fields:
    #   match-jobs       — job names list (optional: ["*"] default)
    #   configure-preset — configure preset name (mostly required)
    #                      inherited, toolchains and build type are ignored
    #   test-preset      — test preset name (optional)
    #                      if omitted, tests will not run for matched jobs
    # Optional: [] empty, no configuration inherited, no tests run
    # Example: >
    #   [
    #     {
    #       "configure-preset": "module",
    #       "test-preset": "module-test"
    #     }
    #   ]
    cmake-presets: ''

    # Artifact names pattern, `*` is replaced with original name.
    # Use to avoid conflicts when calling reusable.yml multiple times within the same workflow.
    # Format: string with `*` placeholder
    # Optional: '*' default
    #           '' disables artifact upload
    # Example: 'full-*'
    upload-pattern: ''

    # Override job timeout per platform.
    # Format: JSON array of objects
    # Fields:
    #   match-jobs      — job names list (optional: ["*"] default)
    #   timeout-minutes — job timeout in minutes (required)
    # Optional: [] empty, default 120 minutes
    # Example: >
    #   [
    #     {
    #       "timeout-minutes": 180
    #     },
    #     {
    #       "match-jobs": ["windows-*"],
    #       "timeout-minutes": 240
    #     }
    #   ]
    timeout: ''
```

### Outputs

| Output | Description |
|--------|-------------|
| `matrix` | Generated jobs matrix content, JSON |
| `cmake-user-presets` | Generated CMakeUserPresets.json content |

### Overview

The workflow runs in two stages:

- **Generate** — configures the pipeline: creates the jobs matrix and CMake user presets from caller inputs
- **CI** — uses a matrix strategy to run each job on a dedicated runner within its own environment

#### Job Naming

Every CI job has a unique name that serves as a key — the caller uses it to request additional packages for the environment and to map CMake presets for building and testing the project. Job names follow this pattern:

```txt
<os>-<arch>-<generator>-<compiler>-<build_type>
```

The pattern components and their values are listed in the platform naming table:

##### Platform Naming

| os | arch | generator | compiler | build_type |
|----|------|-----------|----------|------------|
| windows-2022 | x86_64 | msvs | v143 | debug |
| windows-2022 | x86 | msvs | v143 | release |
| ubuntu-20.04 | x86_64 | ninja | gcc-7 | release |
| ubuntu-20.04 | x86_64 | ninja | clang-9 | release |
| ubuntu-24.04 | x86_64 | ninja | gcc-14 | debug |
| ubuntu-24.04 | x86_64 | ninja | gcc-14 | release |
| ubuntu-24.04 | x86_64 | ninja | clang-18 | release |
| macos-26 | x86_64 | ninja | appleclang | debug |
| macos-26 | armv8 | ninja | appleclang | release |
| macos-15 | x86_64 | ninja | appleclang | release |

Example: `ubuntu-24.04-x86_64-ninja-gcc-14-release`

This naming approach allows the caller to flexibly configure which jobs to run or to set additional parameters for a specific job or a group of jobs using wildcard patterns. Moreover, using an array of patterns or full names enables targeting multiple jobs with a single argument.

#### Pipeline Configuration

The generate stage takes the full set of matrix jobs and processes them as follows:

**Exclude filtering.** Each job name is matched against `exclude-jobs` patterns. Filters are applied until the first match — if a match is found, the job is excluded from the matrix. If no patterns match, the job is created.

**Package resolution.** The `packages` array is iterated in order. For each entry, the `match-jobs` filter is applied to the job name — if it matches, the corresponding package lists are appended to the packages that will be installed during that job's execution. The `run` command, if specified, is executed after package installation; each subsequent match overrides the previous — last match wins. The `run` value can be a direct command or a path (absolute or relative to the working directory) to a shell script within the project repository.

**Preset mapping.** The `cmake-presets` array is iterated in the same way. If the job name matches the `match-jobs` filter, the configure and test preset names are recorded in the matrix entry to be used as inherited presets in the generated `CMakeUserPresets.json`. If the configure preset is explicitly set to an empty string, the job will run with a default preset containing only the compiler and build type. If no test preset is provided or it is set to an empty string explicitly, tests will not run for that job.

**Artifact naming.** GTest results are uploaded as artifacts named `test-results-<job-name>`. If the reusable workflow is called more than once within the same workflow, artifact names will collide and produce an error. To avoid this, pass `upload-pattern` with a `*` placeholder — each call should have its own unique pattern. The `*` is replaced with the original artifact name, e.g. `my-call (*)` renames `test-results-windows-2022-x86_64-msvs-v143-release` into `my-call (test-results-windows-2022-x86_64-msvs-v143-release)`.

**CMake user presets.** Based on the matrix — specifically build type, compiler, and inherited preset names — the generate stage produces a `CMakeUserPresets.json` file with preset names matching job names. These presets are then used in CMake commands for configuration, building, and running tests. *Output directories*, *build types*, *compilers*, and *generators* are set in the generated presets to ensure consistent CMake invocations across the execution environment. Even if these parameters are defined in the parent preset, the generated user preset overrides them.

#### Job Execution

Each CI matrix job runs the following steps:

```bash
# Checkout the caller project
git checkout <project-url>

# Install packages: ubuntu
sudo apt-get install -y <apt-packages>

# Install packages: macos
brew install <brew-packages>

# Install packages: windows
choco install -y <choco-packages>
winget install --id <winget-package> #; winget install --id <winget-another-package>; <etc>

# Install packages: all
pip install <pip-packages>

# Run post-package command (if passed via packages input)
<run-command>

# Write generated CMake user presets
cat > CMakeUserPresets.json <<'EOF'
<generated-presets>
EOF

# Configure
cmake --preset <job-name>

# Build
cmake --build --preset <job-name>

# Test (if test preset is passed via cmake-presets input)
ctest --preset <job-name>
```

### Usage

#### Basic

The recommended approach is to create minimal configure and test presets in your module's `CMakePresets.json`:

```json
{
    "version": 4,
    "configurePresets": [
        {
            "name": "module",
            "hidden": true,
            "cacheVariables": {
                "MY_MODULE_ENABLE_TESTS": "ON"
            }
        }
    ],
    "testPresets": [
        {
            "name": "module-test",
            "hidden": true,
            "configurePreset": "module"
        }
    ]
}
```

Then call the workflow without specifying `match-jobs`, implying the presets apply to all configurations:

```yaml
jobs:
  ci:
    name: My Module
    uses: openDAQ/openDAQ-CI/.github/workflows/reusable.yml@main
    with:
      cmake-presets: >
        [
          {
            "configure-preset": "module",
            "test-preset": "module-test"
          }
        ]
```

#### Upstream Ref

To build against a specific openDAQ SDK git ref:

```yaml
jobs:
  ci:
    name: My Module
    uses: openDAQ/openDAQ-CI/.github/workflows/reusable.yml@main
    with:
      opendaq-ref: 'main'
      cmake-presets: >
        [
          {
            "configure-preset": "module",
            "test-preset": "module-test"
          }
        ]
```

#### Exclude Jobs

To exclude all debug jobs and all macOS ARM jobs:

```yaml
jobs:
  ci:
    name: My Module
    uses: openDAQ/openDAQ-CI/.github/workflows/reusable.yml@main
    with:
      exclude-jobs: '["*-debug", "macos-*-armv8-*"]'
      cmake-presets: >
        [
          {
            "configure-preset": "module",
            "test-preset": "module-test"
          }
        ]
```

#### Exclude Tests

To enable tests for all jobs but skip them on macOS. The first entry implicitly applies `configure-preset` to all jobs, while the second explicitly clears `test-preset` for macOS, so tests will not run on those jobs:

```yaml
jobs:
  ci:
    name: My Module
    uses: openDAQ/openDAQ-CI/.github/workflows/reusable.yml@main
    with:
      cmake-presets: >
        [
          {
            "configure-preset": "module",
            "test-preset": "module-test"
          },
          {
            "match-jobs": ["macos-*"],
            "test-preset": ""
          }
        ]
```

#### Additional Packages

To install extra packages on specific platforms:

```yaml
jobs:
  ci:
    name: My Module
    uses: openDAQ/openDAQ-CI/.github/workflows/reusable.yml@main
    with:
      packages: >
        [
          {
            "match-jobs": ["ubuntu-*"],
            "apt-install": ["libpcap-dev"]
          }
        ]
```

When multiple entries match the same job, packages are chained. For example:

```yaml
      packages: >
        [
          {
            "match-jobs": ["ubuntu-*"],
            "apt-install": ["libpcap-dev"]
          },
          {
            "match-jobs": ["ubuntu-20.04-*"],
            "apt-install": ["mosquitto"]
          }
        ]
```

In this case, Ubuntu 20.04 runners will execute:
```shell
apt install libpcap-dev mosquitto
```
while Ubuntu 24.04 runners will only install:
```shell
apt install libpcap-dev
```

**Important:** The reusable workflow chains only packages, but not the `run` field value, as explained below.

#### Post-Package Command

To run a command after package installation, e.g. starting a service:

```yaml
jobs:
  ci:
    name: My Module
    uses: openDAQ/openDAQ-CI/.github/workflows/reusable.yml@main
    with:
      packages: >
        [
          {
            "match-jobs": ["ubuntu-*"],
            "apt-install": ["mosquitto"],
            "run": "mosquitto -d"
          },
          {
            "match-jobs": ["macos-*"],
            "brew-install": ["mosquitto"],
            "run": "$(brew --prefix mosquitto)/sbin/mosquitto -d"
          },
          {
            "match-jobs": ["windows-*"],
            "winget-install": ["EclipseFoundation.Mosquitto"],
            "run": "Start-Process 'C:\\Program Files\\mosquitto\\mosquitto.exe' -WindowStyle Hidden"
          }
        ]
```

The result is expanded as follows:

```bash
# All Ubuntu runners:
apt install mosquitto
mosquitto -d
```

```bash
# All macOS runners:
brew install mosquitto
$(brew --prefix mosquitto)/sbin/mosquitto -d
```

```powershell
# All Windows runners:
winget install --id EclipseFoundation.Mosquitto
Start-Process 'C:\Program Files\mosquitto\mosquitto.exe' -WindowStyle Hidden
```

Although packages are chained when multiple entries match, the `run` field applies a last-match-wins strategy — the order of entries matters. Consider the following input:

```yml
    with:
      packages: >
        [
          {
            "match-jobs": ["ubuntu-*"],
            "run": "./common-linux-config.sh"
          },
          {
            "match-jobs": ["ubuntu-20.04-*"],
            "run": "./special-linux-config.sh"
          }
        ]
```

The result is expanded as follows:

```bash
# Ubuntu 24.04 runners will execute:
./common-linux-config.sh
```

```bash
# Ubuntu 20.04 runners will execute:
./special-linux-config.sh
```

Since the order matters, it is possible to skip `run` for specific configurations by setting it to an empty string:

```yml
      packages: >
        [
          {
            "match-jobs": ["ubuntu-*"],
            "run": "./common-linux-config.sh"
          },
          {
            "match-jobs": ["ubuntu-20.04-*"],
            "run": ""
          }
        ]
```

In this case, the input will expand only into:

```bash
# Only Ubuntu 24.04 runners will execute:
./common-linux-config.sh

# while Ubuntu 20.04 runners will skip the command
```

**⚠️ Important:** There is a limitation that follows from the `run` exclusion approach and the last-match-wins strategy: the latest match overrides the previous one if the entries order is reversed.

❌ Consider the following mistake:
```yml
      packages: >
        [
          {
            "match-jobs": ["ubuntu-20.04-*"],
            "run": "./special-linux-config.sh"
          },
          {
            "match-jobs": ["ubuntu-*"],
            "run": "./common-linux-config.sh"
          }
        ]
```

The result will differ from the caller's intent:

```bash
# Caller expects Ubuntu 20.04 to execute
# ./special-linux-config.sh
#
# But instead all Ubuntu runners will execute:
./common-linux-config.sh
```

#### Rename Artifacts

To call the reusable workflow multiple times within the same workflow, use `upload-pattern` to avoid artifact name collisions:

```yaml
jobs:
  ci-unit:
    name: Unit Tests
    uses: openDAQ/openDAQ-CI/.github/workflows/reusable.yml@main
    with:
      upload-pattern: 'unit-*'
      cmake-presets: >
        [
          {
            "configure-preset": "module",
            "test-preset": "module-unit-test"
          }
        ]

  ci-integration:
    name: Integration Tests
    uses: openDAQ/openDAQ-CI/.github/workflows/reusable.yml@main
    with:
      upload-pattern: 'integration-*'
      cmake-presets: >
        [
          {
            "configure-preset": "module",
            "test-preset": "module-integration-test"
          }
        ]
```

#### Job Timeout

The default job timeout is 120 minutes. To override it for all jobs:

```yaml
jobs:
  ci:
    name: My Module
    uses: openDAQ/openDAQ-CI/.github/workflows/reusable.yml@main
    with:
      timeout: '[{"timeout-minutes": 240}]'
```

To set different timeouts per platform:

```yaml
jobs:
  ci:
    name: My Module
    uses: openDAQ/openDAQ-CI/.github/workflows/reusable.yml@main
    with:
      timeout: >
        [
          {
            "timeout-minutes": 180
          },
          {
            "match-jobs": ["windows-*"],
            "timeout-minutes": 240
          }
        ]
```

In this example, all jobs get a 180-minute timeout, except Windows jobs which get 240 minutes.

**⚠️ Important:** The last-match-wins strategy applies to `timeout` the same way as to `run`. The order of entries matters — the latest match overrides the previous one if the entries order is reversed.

❌ Consider the following mistake:
```yml
with:
  timeout: >
    [
      {
        "match-jobs": ["windows-*"],
        "timeout-minutes": 240
      },
      {
        "timeout-minutes": 180 
      }
    ]
```

The caller expects Windows runners to have 240-minute timeout. But instead all runners including Windows will get 180-minute timeout.

## License

This project is licensed under the [Apache License 2.0](LICENSE).
