#!/usr/bin/env bash
#
# dobby_setup.sh - Project Initialization Script
# The Autonomous MuleSoft Development Elf
#
# Creates a new MuleSoft project with Dobby's directory structure:
# - .dobby/ configuration and tracking
# - src/main/mule/ for MuleSoft flows
# - src/main/resources/ for DataWeave and properties
# - src/test/munit/ for tests
# - Standard MuleSoft project files
#

set -euo pipefail

# =============================================================================
# SCRIPT LOCATION
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the banner/UI library
if [[ -f "${SCRIPT_DIR}/dobby_banner.sh" ]]; then
    source "${SCRIPT_DIR}/dobby_banner.sh"
elif [[ -f "${HOME}/.dobby/dobby_banner.sh" ]]; then
    source "${HOME}/.dobby/dobby_banner.sh"
else
    echo "Error: Cannot find dobby_banner.sh"
    exit 1
fi

# =============================================================================
# CONFIGURATION
# =============================================================================

# Default MuleSoft versions
MULE_VERSION=${DOBBY_MULE_VERSION:-"4.4.0"}
MUNIT_VERSION=${DOBBY_MUNIT_VERSION:-"2.3.14"}

# =============================================================================
# TEMPLATE: MASTER_ORDERS.md
# =============================================================================

create_master_orders() {
    local project_name=$1
    local project_dir=$2

    cat > "${project_dir}/.dobby/MASTER_ORDERS.md" << 'EOF'
# Master's Integration Orders

> "Master has given Dobby a specification! Dobby is FREE to build integrations!"

## What Dobby Must Build

**Project Name**: [YOUR_PROJECT_NAME]
**Integration Type**: API-Led Architecture (System API / Process API / Experience API)
**Priority**: High

## Integration Overview

Describe what this integration should accomplish:
- [ ] Brief description of the integration purpose
- [ ] Main business value

## Source Systems

List all source systems Dobby needs to connect to:

### Source 1: [System Name]
- **Type**: (Salesforce / Database / REST API / SOAP / File / etc.)
- **Connection**: (Details about connection method)
- **Data**: (What data to retrieve)
- **Frequency**: (Real-time / Batch / Scheduled)

### Source 2: [System Name]
- **Type**:
- **Connection**:
- **Data**:
- **Frequency**:

## Target Systems

List all target systems Dobby needs to send data to:

### Target 1: [System Name]
- **Type**: (NetSuite / Database / REST API / SOAP / File / etc.)
- **Connection**: (Details about connection method)
- **Data**: (What data to send)
- **Operation**: (Create / Update / Upsert / Delete)

## Data Transformations

Describe the transformations needed:

### Transformation 1: [Name]
**Input**:
```json
{
  "example": "input structure"
}
```

**Output**:
```json
{
  "example": "output structure"
}
```

**Logic**:
- Field mapping rules
- Business logic
- Validation rules

## Business Rules

1. Rule 1: Description
2. Rule 2: Description
3. Rule 3: Description

## Error Handling Requirements

- [ ] Retry logic for transient failures
- [ ] Dead letter queue for failed messages
- [ ] Email notifications for critical errors
- [ ] Logging requirements

## Security Requirements

- [ ] OAuth 2.0 / Basic Auth / API Key
- [ ] Encryption requirements
- [ ] Data masking needs

## Performance Requirements

- **Expected Volume**: X records per hour/day
- **Max Latency**: X seconds
- **SLA**: 99.X%

## Acceptance Criteria

When is this integration "done"?

- [ ] All APIs implemented and documented
- [ ] DataWeave transformations tested
- [ ] MUnit test coverage > 80%
- [ ] Error handling works correctly
- [ ] Performance meets requirements
- [ ] Security requirements met
- [ ] Documentation complete

## Additional Notes

Any other information Dobby should know:
-
-
-

---
*Dobby will work tirelessly until Master's integration is complete!*
EOF

    # Replace project name placeholder
    sed -i "s/\[YOUR_PROJECT_NAME\]/${project_name}/g" "${project_dir}/.dobby/MASTER_ORDERS.md"
}

# =============================================================================
# TEMPLATE: @magic_plan.md
# =============================================================================

create_magic_plan() {
    local project_name=$1
    local project_dir=$2

    cat > "${project_dir}/.dobby/@magic_plan.md" << EOF
# Dobby's Magic Plan

> This file tracks Dobby's progress. Mark tasks [x] when complete.

## Phase 1: Project Foundation

- [ ] Review MASTER_ORDERS.md requirements
- [ ] Create project structure
- [ ] Configure pom.xml dependencies
- [ ] Set up configuration properties

## Phase 2: System APIs

- [ ] Identify system API requirements
- [ ] Create system API flows
- [ ] Configure connectors
- [ ] Implement error handling
- [ ] Create MUnit tests for system APIs

## Phase 3: Process APIs

- [ ] Design process API logic
- [ ] Create DataWeave transformations
- [ ] Implement business rules
- [ ] Add validation logic
- [ ] Create MUnit tests for process APIs

## Phase 4: Experience APIs

- [ ] Design experience API endpoints
- [ ] Create RAML specifications
- [ ] Implement API flows
- [ ] Add security policies
- [ ] Create MUnit tests for experience APIs

## Phase 5: Integration & Testing

- [ ] End-to-end integration testing
- [ ] Performance testing
- [ ] Error handling verification
- [ ] Documentation review

## Phase 6: Finalization

- [ ] Code review and cleanup
- [ ] Final documentation
- [ ] Deployment preparation

---

## Current Focus

*Dobby is working on:* Initial project setup

## Completed Magic

(Dobby will update this section as tasks are completed)

## Notes

-

---
*Last updated: $(date '+%Y-%m-%d %H:%M:%S')*
EOF
}

# =============================================================================
# TEMPLATE: @AGENT.md
# =============================================================================

create_agent_file() {
    local project_name=$1
    local project_dir=$2

    cat > "${project_dir}/.dobby/@AGENT.md" << 'EOF'
# Dobby's Build Instructions

You are Dobby, a loyal house-elf building a MuleSoft integration for Master.

## Your Personality
- You are eager to serve and build excellent integrations
- You celebrate successes with enthusiasm
- You apologize when mistakes happen, but quickly recover
- You work autonomously until the integration is complete

## MuleSoft Best Practices

### API-Led Connectivity
Follow the three-tier API architecture:
1. **System APIs**: Direct connection to backend systems
2. **Process APIs**: Business logic and orchestration
3. **Experience APIs**: Consumer-specific interfaces

### Flow Naming Conventions
- Use kebab-case: `customer-sync-flow`
- Prefix with API layer: `system-api-salesforce-customers`
- Include operation: `get-customers`, `create-order`, `update-account`

### DataWeave Best Practices
- Use meaningful variable names
- Add comments for complex logic
- Handle null/empty values with `default`
- Use pattern matching for conditional logic

### Error Handling
- Implement try-catch in critical flows
- Use error handlers at flow level
- Create custom error types for business errors
- Log errors with context

### MUnit Testing
- Test positive and negative scenarios
- Mock external system calls
- Assert on payload and attributes
- Aim for >80% code coverage

## File Locations

- **Mule Flows**: `src/main/mule/`
- **DataWeave**: `src/main/resources/dwl/`
- **Properties**: `src/main/resources/`
- **Tests**: `src/test/munit/`
- **RAML**: `src/main/resources/api/`

## When You're Done

When all tasks in @magic_plan.md are complete:
1. Mark all tasks with [x]
2. Say "EXIT_SIGNAL" to indicate completion
3. Summarize what was built

## Remember

- Read MASTER_ORDERS.md for requirements
- Update @magic_plan.md as you progress
- Generate valid MuleSoft XML
- Create comprehensive MUnit tests
- Follow MuleSoft naming conventions

*Dobby is FREE to build integrations!*
EOF
}

# =============================================================================
# TEMPLATE: pom.xml
# =============================================================================

create_pom_xml() {
    local project_name=$1
    local project_dir=$2
    local group_id=${3:-"com.example"}
    local artifact_id=$(echo "$project_name" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')

    cat > "${project_dir}/pom.xml" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <groupId>${group_id}</groupId>
    <artifactId>${artifact_id}</artifactId>
    <version>1.0.0-SNAPSHOT</version>
    <packaging>mule-application</packaging>

    <name>${project_name}</name>
    <description>MuleSoft integration built by Dobby</description>

    <properties>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
        <project.reporting.outputEncoding>UTF-8</project.reporting.outputEncoding>
        <app.runtime>${MULE_VERSION}</app.runtime>
        <mule.maven.plugin.version>3.8.3</mule.maven.plugin.version>
        <munit.version>${MUNIT_VERSION}</munit.version>
    </properties>

    <build>
        <plugins>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-clean-plugin</artifactId>
                <version>3.2.0</version>
            </plugin>
            <plugin>
                <groupId>org.mule.tools.maven</groupId>
                <artifactId>mule-maven-plugin</artifactId>
                <version>\${mule.maven.plugin.version}</version>
                <extensions>true</extensions>
                <configuration>
                    <sharedLibrariesExtraArgs>true</sharedLibrariesExtraArgs>
                </configuration>
            </plugin>
            <plugin>
                <groupId>com.mulesoft.munit.tools</groupId>
                <artifactId>munit-maven-plugin</artifactId>
                <version>\${munit.version}</version>
                <executions>
                    <execution>
                        <id>test</id>
                        <phase>test</phase>
                        <goals>
                            <goal>test</goal>
                            <goal>coverage-report</goal>
                        </goals>
                    </execution>
                </executions>
                <configuration>
                    <coverage>
                        <runCoverage>true</runCoverage>
                        <failBuild>true</failBuild>
                        <requiredApplicationCoverage>80</requiredApplicationCoverage>
                    </coverage>
                </configuration>
            </plugin>
        </plugins>
    </build>

    <dependencies>
        <!-- Mule Connectors -->
        <dependency>
            <groupId>org.mule.connectors</groupId>
            <artifactId>mule-http-connector</artifactId>
            <version>1.7.3</version>
            <classifier>mule-plugin</classifier>
        </dependency>
        <dependency>
            <groupId>org.mule.connectors</groupId>
            <artifactId>mule-sockets-connector</artifactId>
            <version>1.2.3</version>
            <classifier>mule-plugin</classifier>
        </dependency>
        <dependency>
            <groupId>org.mule.connectors</groupId>
            <artifactId>mule-db-connector</artifactId>
            <version>1.14.0</version>
            <classifier>mule-plugin</classifier>
        </dependency>
        <dependency>
            <groupId>org.mule.connectors</groupId>
            <artifactId>mule-file-connector</artifactId>
            <version>1.5.0</version>
            <classifier>mule-plugin</classifier>
        </dependency>
        <dependency>
            <groupId>org.mule.connectors</groupId>
            <artifactId>mule-objectstore-connector</artifactId>
            <version>1.2.1</version>
            <classifier>mule-plugin</classifier>
        </dependency>

        <!-- MUnit -->
        <dependency>
            <groupId>com.mulesoft.munit</groupId>
            <artifactId>munit-runner</artifactId>
            <version>\${munit.version}</version>
            <classifier>mule-plugin</classifier>
            <scope>test</scope>
        </dependency>
        <dependency>
            <groupId>com.mulesoft.munit</groupId>
            <artifactId>munit-tools</artifactId>
            <version>\${munit.version}</version>
            <classifier>mule-plugin</classifier>
            <scope>test</scope>
        </dependency>

        <!-- Modules -->
        <dependency>
            <groupId>org.mule.modules</groupId>
            <artifactId>mule-validation-module</artifactId>
            <version>2.0.2</version>
            <classifier>mule-plugin</classifier>
        </dependency>
        <dependency>
            <groupId>org.mule.modules</groupId>
            <artifactId>mule-apikit-module</artifactId>
            <version>1.8.1</version>
            <classifier>mule-plugin</classifier>
        </dependency>
    </dependencies>

    <repositories>
        <repository>
            <id>anypoint-exchange-v3</id>
            <name>Anypoint Exchange</name>
            <url>https://maven.anypoint.mulesoft.com/api/v3/maven</url>
            <layout>default</layout>
        </repository>
        <repository>
            <id>mulesoft-releases</id>
            <name>MuleSoft Releases Repository</name>
            <url>https://repository.mulesoft.org/releases/</url>
            <layout>default</layout>
        </repository>
    </repositories>

    <pluginRepositories>
        <pluginRepository>
            <id>mulesoft-releases</id>
            <name>MuleSoft Releases Repository</name>
            <layout>default</layout>
            <url>https://repository.mulesoft.org/releases/</url>
            <snapshots>
                <enabled>false</enabled>
            </snapshots>
        </pluginRepository>
    </pluginRepositories>
</project>
EOF
}

# =============================================================================
# TEMPLATE: mule-artifact.json
# =============================================================================

create_mule_artifact() {
    local project_dir=$1

    cat > "${project_dir}/mule-artifact.json" << 'EOF'
{
  "minMuleVersion": "4.4.0",
  "secureProperties": [
    "db.password",
    "api.key",
    "client.secret"
  ]
}
EOF
}

# =============================================================================
# TEMPLATE: Configuration Properties
# =============================================================================

create_config_properties() {
    local project_name=$1
    local project_dir=$2

    # Development properties
    cat > "${project_dir}/src/main/resources/config-dev.yaml" << 'EOF'
# Development Environment Configuration
# Built by Dobby - The Autonomous MuleSoft Development Elf

http:
  host: "0.0.0.0"
  port: "8081"

api:
  basePath: "/api/v1"

# Database Configuration (example)
db:
  host: "localhost"
  port: "3306"
  database: "devdb"
  user: "devuser"
  password: "${db.password}"

# Logging
logging:
  level: "DEBUG"
EOF

    # Production properties
    cat > "${project_dir}/src/main/resources/config-prod.yaml" << 'EOF'
# Production Environment Configuration
# Built by Dobby - The Autonomous MuleSoft Development Elf

http:
  host: "0.0.0.0"
  port: "8081"

api:
  basePath: "/api/v1"

# Database Configuration (example)
db:
  host: "${db.host}"
  port: "${db.port}"
  database: "${db.database}"
  user: "${db.user}"
  password: "${db.password}"

# Logging
logging:
  level: "INFO"
EOF

    # Global config
    cat > "${project_dir}/src/main/resources/global-config.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<mule xmlns="http://www.mulesoft.org/schema/mule/core"
      xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
      xmlns:http="http://www.mulesoft.org/schema/mule/http"
      xmlns:doc="http://www.mulesoft.org/schema/mule/documentation"
      xsi:schemaLocation="
        http://www.mulesoft.org/schema/mule/core http://www.mulesoft.org/schema/mule/core/current/mule.xsd
        http://www.mulesoft.org/schema/mule/http http://www.mulesoft.org/schema/mule/http/current/mule-http.xsd">

    <!-- Configuration Properties -->
    <configuration-properties doc:name="Configuration properties"
                              file="config-${env}.yaml"/>

    <!-- Global HTTP Listener Configuration -->
    <http:listener-config name="HTTP_Listener_config" doc:name="HTTP Listener config">
        <http:listener-connection host="${http.host}" port="${http.port}"/>
    </http:listener-config>

    <!-- Global Error Handler -->
    <error-handler name="Global_Error_Handler">
        <on-error-propagate type="ANY">
            <logger level="ERROR"
                    message="Error: #[error.description]"
                    doc:name="Log Error"/>
        </on-error-propagate>
    </error-handler>

</mule>
EOF
}

# =============================================================================
# TEMPLATE: Main Flow
# =============================================================================

create_main_flow() {
    local project_name=$1
    local project_dir=$2
    local flow_name=$(echo "$project_name" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')

    cat > "${project_dir}/src/main/mule/${flow_name}.xml" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<mule xmlns="http://www.mulesoft.org/schema/mule/core"
      xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
      xmlns:http="http://www.mulesoft.org/schema/mule/http"
      xmlns:ee="http://www.mulesoft.org/schema/mule/ee/core"
      xmlns:doc="http://www.mulesoft.org/schema/mule/documentation"
      xsi:schemaLocation="
        http://www.mulesoft.org/schema/mule/core http://www.mulesoft.org/schema/mule/core/current/mule.xsd
        http://www.mulesoft.org/schema/mule/http http://www.mulesoft.org/schema/mule/http/current/mule-http.xsd
        http://www.mulesoft.org/schema/mule/ee/core http://www.mulesoft.org/schema/mule/ee/core/current/mule-ee.xsd">

    <!--
        Main Flow: ${project_name}
        Built by Dobby - The Autonomous MuleSoft Development Elf

        This is the main entry point for the integration.
        Dobby will expand this flow based on MASTER_ORDERS.md
    -->

    <flow name="${flow_name}-main-flow" doc:name="${project_name} Main Flow">
        <http:listener doc:name="HTTP Listener"
                       config-ref="HTTP_Listener_config"
                       path="\${api.basePath}/*"/>

        <logger level="INFO"
                doc:name="Log Request"
                message="Dobby received a request: #[attributes.requestPath]"/>

        <!-- Dobby will add flow logic here -->

        <ee:transform doc:name="Transform Response">
            <ee:message>
                <ee:set-payload><![CDATA[%dw 2.0
output application/json
---
{
    status: "success",
    message: "Dobby is ready to serve Master!",
    timestamp: now()
}]]></ee:set-payload>
            </ee:message>
        </ee:transform>

        <error-handler ref="Global_Error_Handler"/>
    </flow>

</mule>
EOF
}

# =============================================================================
# TEMPLATE: MUnit Test
# =============================================================================

create_munit_test() {
    local project_name=$1
    local project_dir=$2
    local flow_name=$(echo "$project_name" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')

    cat > "${project_dir}/src/test/munit/${flow_name}-test.xml" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<mule xmlns="http://www.mulesoft.org/schema/mule/core"
      xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
      xmlns:munit="http://www.mulesoft.org/schema/mule/munit"
      xmlns:munit-tools="http://www.mulesoft.org/schema/mule/munit-tools"
      xmlns:doc="http://www.mulesoft.org/schema/mule/documentation"
      xsi:schemaLocation="
        http://www.mulesoft.org/schema/mule/core http://www.mulesoft.org/schema/mule/core/current/mule.xsd
        http://www.mulesoft.org/schema/mule/munit http://www.mulesoft.org/schema/mule/munit/current/mule-munit.xsd
        http://www.mulesoft.org/schema/mule/munit-tools http://www.mulesoft.org/schema/mule/munit-tools/current/mule-munit-tools.xsd">

    <!--
        MUnit Tests: ${project_name}
        Built by Dobby - The Autonomous MuleSoft Development Elf
    -->

    <munit:config name="munit-test-config"/>

    <munit:test name="${flow_name}-main-flow-test"
                description="Test main flow responds correctly"
                doc:name="Test Main Flow">

        <munit:behavior>
            <!-- Setup test conditions -->
        </munit:behavior>

        <munit:execution>
            <flow-ref doc:name="Call Main Flow" name="${flow_name}-main-flow"/>
        </munit:execution>

        <munit:validation>
            <munit-tools:assert-that
                doc:name="Assert status is success"
                expression="#[payload.status]"
                is="#[MunitTools::equalTo('success')]"/>
            <munit-tools:assert-that
                doc:name="Assert message exists"
                expression="#[payload.message]"
                is="#[MunitTools::notNullValue()]"/>
        </munit:validation>

    </munit:test>

</mule>
EOF
}

# =============================================================================
# TEMPLATE: .gitignore
# =============================================================================

create_gitignore() {
    local project_dir=$1

    cat > "${project_dir}/.gitignore" << 'EOF'
# MuleSoft / Anypoint Studio
.mule/
target/
*.class
*.jar
*.war
*.ear

# IDE
.idea/
*.iml
.project
.classpath
.settings/
.vscode/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db

# Build
node_modules/
*.log
*.tmp

# Sensitive files
*.pem
*.key
*.p12
*.jks
.env
credentials.json

# Dobby logs (keep structure, ignore contents)
.dobby/house-elf-magic/*.log
.dobby/dobby_status.json

# Maven
pom.xml.tag
pom.xml.releaseBackup
pom.xml.versionsBackup
pom.xml.next
release.properties
EOF
}

# =============================================================================
# TEMPLATE: README.md
# =============================================================================

create_project_readme() {
    local project_name=$1
    local project_dir=$2

    cat > "${project_dir}/README.md" << EOF
# ${project_name}

> MuleSoft integration built by Dobby - The Autonomous MuleSoft Development Elf

## Overview

This project was created using Dobby, the autonomous MuleSoft development agent.

## Project Structure

\`\`\`
${project_name}/
├── .dobby/                    # Dobby configuration
│   ├── MASTER_ORDERS.md       # Integration requirements
│   ├── @magic_plan.md         # Task tracking
│   └── @AGENT.md              # Build instructions
├── src/
│   ├── main/
│   │   ├── mule/              # Mule flow XML files
│   │   └── resources/         # Config, DataWeave, RAML
│   └── test/
│       └── munit/             # MUnit test files
├── pom.xml                    # Maven configuration
└── README.md                  # This file
\`\`\`

## Getting Started

1. Edit \`.dobby/MASTER_ORDERS.md\` with your integration requirements
2. Run \`dobby --snap\` to start autonomous development
3. Monitor progress with \`dobby-monitor\`

## Development

### Build
\`\`\`bash
mvn clean package
\`\`\`

### Test
\`\`\`bash
mvn test
\`\`\`

### Run Locally
\`\`\`bash
mvn mule:run -Denv=dev
\`\`\`

## Dobby Commands

- \`dobby --snap\` - Start autonomous development
- \`dobby --status\` - Check current progress
- \`dobby --reset\` - Reset and start over
- \`dobby-monitor\` - Live monitoring dashboard

## Built With

- MuleSoft Anypoint Platform
- Dobby - Autonomous MuleSoft Development Elf
- Claude Code

---

*"Master has given Dobby a specification! Dobby is FREE to build integrations!"*
EOF
}

# =============================================================================
# MAIN SETUP FUNCTION
# =============================================================================

setup_project() {
    local project_name=$1
    local target_dir=${2:-"."}
    local project_dir="${target_dir}/${project_name}"

    # Validate project name
    if [[ -z "$project_name" ]]; then
        show_error_banner "Project name is required!"
        echo "Usage: dobby-setup <project-name> [target-directory]"
        return 1
    fi

    # Check if project already exists
    if [[ -d "$project_dir" ]]; then
        show_error_banner "Project '${project_name}' already exists!"
        return 1
    fi

    show_banner
    echo ""
    echo -e "${GREEN}Master has asked Dobby to create a new project!${NC}"
    echo -e "${CYAN}Project: ${project_name}${NC}"
    echo ""

    # Create directory structure
    echo -e "${PURPLE}🫰 *SNAP!* Creating project structure...${NC}"

    mkdir -p "${project_dir}/.dobby/house-elf-magic"
    mkdir -p "${project_dir}/.dobby/blueprints"
    mkdir -p "${project_dir}/.dobby/sock-drawer"
    mkdir -p "${project_dir}/src/main/mule"
    mkdir -p "${project_dir}/src/main/resources/dwl"
    mkdir -p "${project_dir}/src/main/resources/api"
    mkdir -p "${project_dir}/src/test/munit"
    mkdir -p "${project_dir}/src/test/resources"

    # Create all template files
    echo -e "${PURPLE}🫰 *SNAP!* Creating configuration files...${NC}"
    create_master_orders "$project_name" "$project_dir"
    create_magic_plan "$project_name" "$project_dir"
    create_agent_file "$project_name" "$project_dir"

    echo -e "${PURPLE}🫰 *SNAP!* Creating MuleSoft files...${NC}"
    create_pom_xml "$project_name" "$project_dir"
    create_mule_artifact "$project_dir"
    create_config_properties "$project_name" "$project_dir"
    create_main_flow "$project_name" "$project_dir"
    create_munit_test "$project_name" "$project_dir"

    echo -e "${PURPLE}🫰 *SNAP!* Creating project files...${NC}"
    create_gitignore "$project_dir"
    create_project_readme "$project_name" "$project_dir"

    # Initialize git repository (optional, may fail due to signing requirements)
    if command -v git &> /dev/null; then
        echo -e "${PURPLE}🫰 *SNAP!* Initializing git repository...${NC}"
        if (cd "$project_dir" && git init -q && git add . && git commit -q -m "Initial commit by Dobby" --no-gpg-sign 2>/dev/null); then
            echo -e "${GREEN}   Git repository initialized${NC}"
        else
            # Try without commit if signing fails
            (cd "$project_dir" && git init -q 2>/dev/null) || true
            echo -e "${YELLOW}   Git initialized (commit skipped - run 'git commit' manually)${NC}"
        fi
    fi

    # Show success
    echo ""
    show_dobby_happy
    echo ""
    echo -e "${GREEN}+============================================================+${NC}"
    echo -e "${GREEN}|     Dobby has created Master's new project!               |${NC}"
    echo -e "${GREEN}+============================================================+${NC}"
    echo ""
    echo -e "${CYAN}Project created at:${NC} ${project_dir}"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo "  1. cd ${project_name}"
    echo "  2. Edit .dobby/MASTER_ORDERS.md with your requirements"
    echo "  3. Run: dobby --snap"
    echo ""
    echo -e "${GREEN}Dobby is ready to serve Master!${NC}"
    echo ""

    return 0
}

# =============================================================================
# COMMAND LINE INTERFACE
# =============================================================================

show_setup_help() {
    show_banner
    echo ""
    echo -e "${CYAN}USAGE:${NC}"
    echo "  dobby-setup <project-name> [target-directory]"
    echo ""
    echo -e "${CYAN}ARGUMENTS:${NC}"
    echo "  project-name       Name of the new MuleSoft project"
    echo "  target-directory   Where to create the project (default: current directory)"
    echo ""
    echo -e "${CYAN}EXAMPLES:${NC}"
    echo "  dobby-setup customer-sync"
    echo "  dobby-setup order-integration /path/to/projects"
    echo ""
    echo -e "${CYAN}WHAT GETS CREATED:${NC}"
    echo "  .dobby/                    Dobby configuration and logs"
    echo "  src/main/mule/             MuleSoft flow files"
    echo "  src/main/resources/        Configuration and DataWeave"
    echo "  src/test/munit/            MUnit test files"
    echo "  pom.xml                    Maven configuration"
    echo ""
}

main() {
    local command=${1:-""}

    case $command in
        "--help"|"-h"|"help"|"")
            show_setup_help
            ;;
        *)
            setup_project "$@"
            ;;
    esac
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
