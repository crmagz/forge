---
description: Standardized CDK repository directory layout and file organization
alwaysApply: true
version: 1.0.0
---

# CDK Directory Structure

All CDK repositories must follow this standardized structure:

```
├── bin/
│   ├── app.ts                          # CDK app entry point
│   └── environments.ts                 # Environment-specific configuration
├── lib/
│   └── project-stack.ts                # Main stack(s)
├── src/
│   ├── constant/
│   │   └── *.ts                        # Application constants
│   ├── constructs/
│   │   └── *.ts                        # Custom construct implementations
│   ├── enums/
│   │   └── *.ts                        # Enum definitions
│   ├── interfaces/
│   │   └── *.ts                        # Interface definitions
│   ├── lambda/
│   │   ├── lambda-function-1/
│   │   │   └── lambda_function.py      # Python Lambda handler
│   │   └── lambda-function-2/
│   │       └── index.ts                # Node.js Lambda handler
│   ├── services/
│   │   └── *.ts                        # Service implementations
│   ├── types/
│   │   ├── environment-type.ts         # ProjectEnvironment type extensions
│   │   └── *.ts                        # Type definitions
│   └── util/
│       └── *.ts                        # Utility functions
├── docs/
│   └── *.md                            # Detailed documentation
├── test/
│   └── *.test.ts                       # Unit and integration tests
├── README.md                           # High-level summary and ToC
├── package.json
└── tsconfig.json
```

## Directory Purposes

- **`bin/`**: Application entry point and environment configuration
  - `app.ts`: CDK app initialization
  - `environments.ts`: Array of `ProjectEnvironment` configurations for each deployment environment

- **`lib/`**: CDK stacks only
  - Stack definitions that orchestrate infrastructure by calling constructs and package functions
  - Keep stacks minimal — primarily configuration assembly and resource orchestration
  - No `util/` or other subdirectories inside `lib/`

- **`src/`**: Application code and shared utilities
  - `constant/`: Immutable configuration values
  - `constructs/`: Custom CDK construct implementations (only when needed for complex, reusable infrastructure patterns)
  - `enums/`: Enumerated types for type-safe constants
  - `interfaces/`: Service and component interfaces
  - `lambda/`: Lambda function source code (Python, Node.js, etc.)
  - `services/`: Service implementations (with interface-first pattern)
  - `types/`: Custom TypeScript types, including `ProjectEnvironment` extensions
  - `util/`: Shared utility functions

- **`docs/`**: Detailed technical documentation (not in README)

- **`test/`**: Unit and integration test files
