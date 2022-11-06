import { join } from 'node:path';

import { stat } from 'node:fs/promises';

import { PathLike } from 'fs';
import { FileHandle, readFile as fsReadFile } from 'fs/promises';

// -----------------------------------------------------------------------------

/**
 * `fileExists` function signature.
 */
export type FileExistsSignature = (
  path: string
) => Promise<boolean>;

/**
 * Asynchronously check if a file exists.
 *
 * * **@param path** -  The absolute or relative path to the file.
 * * **@returns** - True when the file exists and false otherwise.
 *
 * Example usage:
 *
 * ```typescript
 * import { join } from 'node:path';
 * import { fileExists } from '@sqlw/file-async-ts';
 *
 * const dir = join(__dirname, 'file-exists.unit.spec.ts');
 * const exists = await fileExists(dir);
 * expect(exists).toEqual(true);
 * ```
*/
export const fileExists = async (
  path: string,
): Promise<boolean> => stat(path)
  .then(() => true)
  .catch(() => false);

// -----------------------------------------------------------------------------

/**
 * ReadFile options interface
 */
export interface ReadOptions {

  /**
   * When `true` or `undefined`, when the file is not found an exception is
   * thrown. When `false`, no exception is thrown and `undefined` is returned.
   */
  required?: boolean
}

/**
 * `readFile` function signature.
 */
export type ReadFileSignature = (
  path: PathLike | FileHandle,
  options?: ReadOptions
) => Promise<Buffer | undefined>;

/**
 * Given an absolute or relative path, asynchronously reads all the contents of
 * the file into a buffer.
 *
 * **Warning:** Intended use is only for relatively small files. For large files
 * using streams.
 *
 * * **@param path** - The absolute or relative path to the file.
 *
 * * **@param [options]**
 *   * **[options.required=true]** - When `true` or `undefined`, when the file is
 *   not found an exception is thrown. When `false`, no exception is thrown and
 *   `undefined` is returned.
 *
 * * **@error** - Errors if the file is not found when `options.required` is `true`.
 * * **@returns** - Contents of the file as a buffer if the file existed,
 *   `undefined` when required is `false` and the file was not found.
 *
 * Example usage:
 *
 * ```typescript
 * import { join } from 'node:path';
 * import { readFile } from '@sqlw/file-async-ts';
 *
 * (async () => {
 *   const dir = join(__dirname, 'index.ts');
 *   const content = await readFile(dir);
 *   console.log(content);
 * })();
 * ```
*/
export const readFile: ReadFileSignature = async (
  path: PathLike | FileHandle,
  options?: ReadOptions,
): Promise<Buffer | undefined> => {
  try {
    return await fsReadFile(path);
  } catch (err) {
    if (undefined === options?.required || options.required) {
      throw (err);
    }
  }
  return undefined;
};

// -----------------------------------------------------------------------------

/**
 * `readFileAsString` function signature.
 */
export type ReadFileAsStringSignature = (
  path: PathLike | FileHandle,
  options?: ReadOptions
) => Promise<string | undefined>;

/**
 * Given an absolute or relative path, asynchronously reads all the contents of
 * the file into a string.
 *
 * **Warning:** Intended use is only for relatively small files. For large files
 * using streams.
 *
 * * **@param path** - The absolute or relative path to the file.
 *
 * * **@param [options]**
 *   * **[options.required=true]** - When `true` or `undefined`, when the file is
 *   not found an exception is thrown. When `false`, no exception is thrown and
 *   `undefined` is returned.
 *
 * * **@error** - Errors if the file is not found when `options.required` is `true`.
 * * **@returns** - Contents of the file as a string if the file existed,
 *   `undefined` when required is `false` and the file was not found.
 *
 * Example usage:
 *
 * ```typescript
 * import { join } from 'node:path';
 * import { readFileAsString } from '@sqlw/file-async-ts';
 *
 * const dir = join(__dirname, 'read-file.unit.spec.ts');
 * const content = await readFileAsString(dir);
 * expect(content).toBeDefined();
 * ```
*/
export const readFileAsString: ReadFileAsStringSignature = async (
  path: PathLike | FileHandle,
  options?: ReadOptions,
): Promise<string | undefined> => {
  const buffer = await readFile(path, options);
  return buffer ? new TextDecoder().decode(buffer) : undefined;
};
