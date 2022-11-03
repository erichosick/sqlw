// Integration and Unit Tests

import type { Config } from 'jest';
import unitTestConfig from './jest.unit.config';

const integrationTestConfig: Config = {
  // Merge in configuration from unit tests
  ...unitTestConfig,
  // and overwrite unit tests testMatch with integration tests.
  testMatch: [
    '**/*.unit.spec.ts',
    '**/*.integration.spec.ts',
  ],
};

export default integrationTestConfig;
