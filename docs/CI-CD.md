# CI/CD Pipeline Documentation

## Overview

This project uses GitHub Actions for Continuous Integration and Continuous Deployment (CI/CD). The pipeline automatically runs tests, performs code quality checks, and deploys the application when changes are pushed to the main branches.

## Workflow Configuration

The CI/CD pipeline is configured in `.github/workflows/ci.yml` and includes the following jobs:

### 1. Backend Tests (Node.js + Jest)
- **Platform**: Ubuntu Latest
- **Services**: MongoDB 7.0
- **Node.js Version**: 18
- **Test Framework**: Jest with Supertest
- **Tests Executed**:
  - `catalogAPI.test.js` - API endpoint validation
  - `database.test.js` - Database model testing
  - `layoutAPI.test.js` - Layout API functionality

### 2. Frontend Tests (iOS + XCTest)
- **Platform**: macOS Latest
- **Xcode Version**: Latest Stable
- **Test Framework**: XCTest
- **Tests Executed**:
  - `modelsTest.swift` - Model serialization/deserialization

### 3. Integration Tests
- **Platform**: Ubuntu Latest
- **Dependencies**: Backend and Frontend tests must pass first
- **Purpose**: End-to-end testing of API endpoints

### 4. Code Quality Checks
- **Platform**: Ubuntu Latest
- **Checks**: ESLint (when configured), code formatting
- **Purpose**: Ensure code follows project standards

### 5. Security Scanning
- **Platform**: Ubuntu Latest
- **Tools**: npm audit, Snyk security scan
- **Purpose**: Identify security vulnerabilities

### 6. Build and Deploy
- **Platform**: Ubuntu Latest
- **Trigger**: Only on main/master branch
- **Purpose**: Build and deploy to staging environment

## Triggers

The CI pipeline runs automatically on:

- **Push to main/master/develop branches**
- **Pull request creation/updates to main/master/develop**
- **Manual trigger** (workflow_dispatch)

## Environment Variables

### Required Environment Variables:
- `NODE_ENV=test` - Sets Node.js environment to test mode
- `MONGO_URI` - MongoDB connection string for testing
- `PORT=3000` - Backend server port

### Optional Environment Variables:
- `SNYK_TOKEN` - For Snyk security scanning (add to GitHub Secrets)

## Local Testing

### Backend Tests
```bash
cd Homi/Backend
npm test                    # Run all tests
npm run test:ci            # Run tests with coverage
npm run test:integration   # Run integration tests
npm run audit              # Security audit
```

### Frontend Tests
```bash
cd Homi/Frontend/Homi
xcodebuild test -project Homi.xcodeproj -scheme Homi -sdk iphonesimulator
```

## Adding New Tests

### Backend (Jest)
1. Create test file in `Homi/Backend/BackendTests/` with `.test.js` extension
2. Import required modules and write tests using Jest syntax
3. Tests will automatically run in CI

### Frontend (XCTest)
1. Add test methods to existing test files or create new ones
2. Use XCTest framework syntax
3. Tests will automatically run in CI

## CI Status Badge

Add this badge to your README to show CI status:

```markdown
![CI](https://github.com/yourusername/homi/workflows/CI%2FCD%20Pipeline/badge.svg)
```

## Troubleshooting

### Common Issues:

1. **MongoDB Connection Issues**: Ensure MongoDB service is running and accessible
2. **iOS Simulator Issues**: Check Xcode version compatibility
3. **Node.js Version Issues**: Ensure Node.js 18 is used
4. **Test Timeout Issues**: Increase timeout values in Jest configuration

### Debugging:

- Check GitHub Actions logs for detailed error messages
- Run tests locally to reproduce CI issues
- Verify environment variables are set correctly

## Future Enhancements

- Add ESLint configuration for code quality
- Implement automated deployment to production
- Add performance testing
- Configure notifications for failed builds
- Add database migration testing
