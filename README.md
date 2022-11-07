# sqlw

[![lerna](https://img.shields.io/badge/maintained%20with-lerna-cc00ff.svg)](https://lerna.js.org/)

## Development

Development requirements:

* Node + Yarn

```bash

# init all the projects
yarn

# continuously run tests
yarn test:unit:watch

# build any distributables and run unit tests
yarn test:unit

# build javascript library from typescript library
yarn build

# continuously build javascript library from typescript library
yarn build:watch

# publish all packages that have changed to npmjs.com
yarn publish:all
```

### Pushing Changes

```bash
# verify test run
yarn test:unit

# verify build works
yarn build

# make sure everything is commented, checked in and pushed into git
# TODO: Document code review process

# publish all packages that have changed
# you will need to have setup the account with npmjs.com
yarn publish:all

# enter the one-time password generated using 
# select correct version bump
```

### Adding a New Project

```bash
# Add a new project
yarn lerna:create {@name/new-package-name}  # @example yarn lerna:create @sqlw/http-context

# Link it to other projects
yarn lerna add {@name/existing-module} --scope={@name/new-package-name}
```

### Linking To Another Project

```bash
yarn lerna add {@name/existing-module} --scope={@name/new-package-name}
# example
 yarn lerna add @sqlw/universal-schema --scope=@sqlw/iso-schema
```
