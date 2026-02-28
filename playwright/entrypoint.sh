#!/bin/bash
set -e

# Run Playwright tests (will still continue even if tests fail)
npm run testChrome -- $TEST_ARGS|| true

# Generate Allure report
npx allure generate allure-results --clean -o allure-report
echo "Report generated at /app/allure-report"

# Bind to 0.0.0.0 so it's accessible outside the container
# npx allure open allure-report --port 4040 --host 0.0.0.0