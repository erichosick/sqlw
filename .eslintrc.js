module.exports = {
  env: {
    browser: true,
    es2021: true,
    'jest/globals': true,

    // Stops error: 'webpack' should be listed in the project's dependencies.
    // but also doesn't stop us from importing webpack into our actual code.
    webpack: true,
  },
  extends: [
    'airbnb-base',
    'eslint-plugin-import',
  ],
  parser: '@typescript-eslint/parser',
  parserOptions: {
    ecmaFeatures: {
      jsx: true,
    },
    ecmaVersion: 'latest',
    sourceType: 'module',
  },
  plugins: [
    '@typescript-eslint',
    'jest',
  ],
  rules: {
    // Stop errors dev development dependencies such as with webpack...
    // 'webpack' should be listed in the project's dependencies.
    // TODO: It looks like projectDependencies: false is enough but we would like to make sure
    // only actual test and configuration files are tested for. Right now, even
    // code files are excluded.
    // 'import/no-extraneous-dependencies': ['error', { devDependencies: ['**/*.spec.ts', '**/*.config.ts'], projectDependencies: false }],
    // see https://stackoverflow.com/questions/55807329/why-eslint-throws-no-unused-vars-for-typescript-interface
    'no-unused-vars': 'off',
    '@typescript-eslint/no-unused-vars': ['error'],
    // see end
    'import/extensions': [
      'error',
      'ignorePackages',
      {
        js: 'never',
        jsx: 'never',
        ts: 'never',
        tsx: 'never',
      },
    ],
    // airbnb
    // https://stackoverflow.com/questions/69905008/stuck-with-eslint-error-separately-loops-should-be-avoided-in-favor-of-array-it
    // https://medium.com/@paul.beynon/thanks-for-taking-the-time-to-write-the-article-i-enjoyed-it-db916026647
    'no-restricted-syntax': 'off',

    // https://basarat.gitbook.io/typescript/main-1/defaultisbad
    'import/prefer-default-export': 'off',

    // see https://stackoverflow.com/questions/63961803/eslint-says-all-enums-in-typescript-app-are-already-declared-in-the-upper-scope
    // note you must disable the base rule as it can report incorrect errors
    'no-shadow': 'off',
    '@typescript-eslint/no-shadow': ['error'],

    // In my opinion, code is more readable if we explicitly write
    // return await ...
    'no-return-await': 'off',

    // Cause I like private class variables to start with _.
    'no-underscore-dangle': 'off',

    'max-classes-per-file': 'off',
  },
  ignorePatterns: ['**/lib/*'],
  settings: {
    'import/resolver': {
      node: {
        extensions: ['.ts'],
      },
    },
  },
};
