import {
  normalize,
  isAbsolute,
  dirname,
  parse,
} from 'node:path';
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
 * import { fileExists } from '@sqlw/file-ts';
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
 * import { readFile } from '@sqlw/file-ts';
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
 * `readFileString` function signature.
 */
export type readFileStringSignature = (
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
 * import { readFileString } from '@sqlw/file-ts';
 *
 * const dir = join(__dirname, 'read-file.unit.spec.ts');
 * const content = await readFileString(dir);
 * expect(content).toBeDefined();
 * ```
*/
export const readFileString: readFileStringSignature = async (
  path: PathLike | FileHandle,
  options?: ReadOptions,
): Promise<string | undefined> => {
  const buffer = await readFile(path, options);
  return buffer ? new TextDecoder().decode(buffer) : undefined;
};

// -----------------------------------------------------------------------------

/**
 * `allParentPaths` function signature.
 */
export type AllParentPathsSignature = (
  childPath: string,
) => string[];

/**
 * Given an absolute path, `allParentPaths` returns an array containing all
 * possible parent paths, including the root path ordered by the child path
 * to the root path.
 *
 * **Note:** The child path is normalized before all possible parent paths are
 * generated. For example, `/cat/../and/mouse` becomes `/and/mouse`.
 *
 * * **@param childPath** - The absolute path used to generate all possible
 *  parent paths.
 * * **@error** - An error is thrown if `childPath` is not an absolute path.
 * * **@returns** - An array containing all possible parent paths
 * including the root path ordered by the child path first.
 *
 * Example usage:
 *
 * ```typescript
 * import {
 *   allParentPaths,
 * } from '@sqlw/file-async-ts';
 *
 * const result = allParentPaths('/cat/mouse');
 * expect(result).toEqual([
 *   '/cat/mouse',
 *   '/cat',
 *   '/',
 * ]);
 * ```
*/
export const allParentPaths: AllParentPathsSignature = (
  childPath: string,
): string[] => {
  const normalizedPath = normalize(childPath);

  if (!isAbsolute(normalizedPath)) {
    throw new Error(`The path '${childPath}' must be an absolute path.`);
  }

  const pathRoot = parse(normalizedPath).root;
  let currentPath = normalizedPath;
  const paths: string[] = [];

  while (currentPath !== '') {
    paths.push(currentPath);
    if (currentPath === pathRoot) {
      currentPath = '';
    } else {
      currentPath = dirname(currentPath);
    }
  }
  return paths;
};

// -----------------------------------------------------------------------------

// /**
//  * allParentPath options interface
//  */
//  export interface AllParentPathOptions {

//   /**
//    * When true, an exception is thrown if the childPath doesn't exists.
//    */
//   verifyChildPathExists: boolean,
// }

// /**
//  * `allParentPaths` function signature.
//  */
// export type AllParentPathsSignature = (
//   childPath: string,
//   options?: AllParentPathOptions,
// ) => Promise<string[]>;

// export const allParentPaths: AllParentPathsSignature = async (
//   childPath: string,
//   options?: AllParentPathOptions,
// ): Promise<string[]> => {
//   const normalizedPath = normalize(childPath);

//   if (!isAbsolute(normalizedPath)) {
//     throw new Error(`The path '${childPath}' must be an absolute path.`);
//   }

//   if (options?.verifyChildPathExists) {
//     const exists = await fileExists(normalizedPath);
//     if (!exists) {
//       throw new Error(`The path '${childPath}' was not found.`);
//     }
//   }

//   const pathRoot = parse(normalizedPath).root;
//   let currentPath = normalizedPath;
//   const paths: string[] = [];

//   while (currentPath !== '') {
//     paths.push(currentPath);
//     if (currentPath === pathRoot) {
//       currentPath = '';
//     } else {
//       currentPath = dirname(currentPath);
//     }
//   }
//   return paths;
// };

// Given an absolute path, returns an array containing all possible parent paths
// including the root path ordered by the child path first.

// * **@param childPath** - The absolute path used to generate all possible
//  parent paths.
// * **@param [options]**
//   * [options.verifyChildPathExists = false] - When true, an exception is
//    thrown if the childPath doesn't exists.
// * **error** - An error is thrown if `options.verifyChildPathExists` is set
// to true and the `childPath` does not exists.
// * **@returns** - An array containing all possible parent paths
// including the root path ordered by the child path first.

// Example usage:

// ```typescript
// import { readFileString } from '@sqlw/file-async-ts';

// (async () => {

// const result = await allParentPaths('/cat/mouse');
// expect (result).toEqual([
//   '/cat/mouse',
//   '/cat',
//   '/'
// ]);
