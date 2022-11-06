# **@sqlw/file-async-ts**

`@sqlw/file-async-ts` is a typescript library applying the [facade pattern](https://en.wikipedia.org/wiki/Facade_pattern) to asynchronous file access.

## Features

* 100% typescript.
* 100% asynchronous library.
* functions
  * **fileExists** - Check if a file exists.
  * **readFile** - Read from a file returning a Buffer.
  * **readFileString** -Read from a file returning a string.
  * **allParentPaths** - Returns an array of all parent paths.

## Usage

## **fileExists** - Asynchronously Checking if a File Exists

Asynchronously check if a file exists.

* **@param path** -  The absolute or relative path to the file.
* **@returns** - True when the file exists and false otherwise.

Example usage:

```typescript
import { join } from 'node:path';
import { fileExists } from '@sqlw/file-async-ts';

(async () => {
  const dir = join(__dirname, 'file-exists.unit.spec.ts');
  const exists = await fileExists(dir);
  expect(exists).toEqual(true);
})();
```

## **readFile** - Asynchronously Read All Contents of a File

Given an absolute or relative path, asynchronously reads all the contents of
the file into a buffer.

**Warning:** Intended use is only for relatively small files. For large files
using streams.

* **@param path** - The absolute or relative path to the file.

* **@param [options]**
  * **[options.required=true]** - When `true` or `undefined`, when the file is
  not found an exception is thrown. When `false`, no exception is thrown and
  `undefined` is returned.

* **@error** - Errors if the file is not found when `options.required` is `true`.
* **@returns** - Contents of the file as a buffer if the file existed,
  `undefined` when required is `false` and the file was not found.

Example usage:

```typescript
import { join } from 'node:path';
import { readFile } from '@sqlw/file-async-ts';

(async () => {
  const dir = join(__dirname, 'index.ts');
  const content = await readFile(dir);
  console.log(content);
})();
```

## **readFileString** - Asynchronously Read All Contents of a File Into A String

Given an absolute or relative path, asynchronously reads all the contents of
the file into a string.

**Warning:** Intended use is only for relatively small files. For large files
using streams.

* **@param path** - The absolute or relative path to the file.

* **@param [options]**
  * **[options.required=true]** - When `true` or `undefined`, when the file is
  not found an exception is thrown. When `false`, no exception is thrown and
  `undefined` is returned.

* **@error** - Errors if the file is not found when `options.required` is `true`.
* **@returns** - Contents of the file as a string if the file existed,
  `undefined` when required is `false` and the file was not found.

Example usage:

```typescript
import { join } from 'node:path';
import { readFileString } from '@sqlw/file-async-ts';

(async () => {
  const dir = join(__dirname, 'read-file.unit.spec.ts');
  const content = await readFileString(dir);
  expect(content).toBeDefined();
})();
```

## **allParentPaths** - Getting All Paths of a Child Path

Given an absolute path, `allParentPaths` returns an array containing all
possible parent paths, including the root path ordered by the child path
to the root path.

**Note:** The child path is normalized before all possible parent paths are
generated. For example, `/cat/../and/mouse` becomes `/and/mouse`.

* **@param childPath** - The absolute path used to generate all possible
 parent paths.
* **@error** - An error is thrown if `childPath` is not an absolute path.
* **@returns** - An array containing all possible parent paths
including the root path ordered by the child path first.

Example usage:

```typescript
import {
  allParentPaths,
} from '@sqlw/file-async-ts';

const result = allParentPaths('/cat/mouse');
expect(result).toEqual([
  '/cat/mouse',
  '/cat',
  '/',
]);
```

## Intent

* No Emitted Javascript - The intent is to import this typescript library into a typescript project: compiling to Javascript occurring within the project.
* No Synchronous Calls Exposed - We [facade](https://en.wikipedia.org/wiki/Facade_pattern) only asynchronous functions as a forcing function to simplify architectural decisions. The intent is to add consistency to how files are consumed within a business organization.

## Development

See the [monorepo readme](https://www.github.com/erichosick/sqlw).

## License

Licensed under MIT. See LICENSE.md.
