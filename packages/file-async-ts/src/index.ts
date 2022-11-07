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
 * * **@param path** - The absolute or relative path to the file.
 * * **@returns** - True when the file exists and false otherwise.
 *
 * **@example**
 * Checks if a file exits.
 *
 * ```typescript
 * import { join } from 'node:path';
 * import { fileExists } from '@sqlw/file-ts';
 *
 * const dir = join(__dirname, 'file-exists.unit.spec.ts');
 * const exists: boolean = await fileExists(dir);
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
   *
   * **@defaultValue** - True or undefined
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
 * **@remarks**
 * Intended use is only for relatively small files. For large files
 * use streams.
 *
 * * **@param path** - The absolute or relative path to the file.
 *
 * * **@param [options]**
 *   * **[options.required=true]** - When `true` or `undefined`, when the file is
 *   not found an exception is thrown. When `false`, no exception is thrown and
 *   `undefined` is returned.
 *
 * * **@throws** - Errors if the file is not found when `options.required` is `true`.
 * * **@returns** - Contents of the file as a buffer if the file existed,
 *   `undefined` when required is `false` and the file was not found.
 *
 * **@example**
 * Reads the contents of a file into a `Buffer`.
 *
 * ```typescript
 * import { join } from 'node:path';
 * import { readFile } from '@sqlw/file-ts';
 *
 * (async () => {
 *   const dir = join(__dirname, 'index.ts');
 *   const content: Buffer | undefined = await readFile(dir);
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
 * **@remarks**
 * Intended use is only for relatively small files. For large files
 * use streams.
 *
 * * **@param path** - The absolute or relative path to the file.
 *
 * * **@param [options]**
 *   * **[options.required=true]** - When `true` or `undefined`, when the file is
 *   not found an exception is thrown. When `false`, no exception is thrown and
 *   `undefined` is returned.
 *
 * * **@throws** - Errors if the file is not found when `options.required` is `true`.
 * * **@returns** - Contents of the file as a string if the file existed,
 *   `undefined` when required is `false` and the file was not found.
 *
 * **@example**
 * Reads the contents of a file into a `string`.
 *
 * ```typescript
 * import { join } from 'node:path';
 * import { readFileString } from '@sqlw/file-ts';
 *
 * const dir = join(__dirname, 'read-file.unit.spec.ts');
 * const content: string | undefined = await readFileString(dir);
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
 * **@remarks**
 * The child path is normalized before all possible parent paths are
 * generated. For example, `/cat/../and/mouse` becomes `/and/mouse`.
 *
 * * **@param childPath** - The absolute path used to generate all possible
 *  parent paths.
 * * **@throws** - An error is thrown if `childPath` is not an absolute path.
 * * **@returns** - An array containing all possible parent paths
 * including the root path ordered by the child path first.
 *
 * **@example**
 *
 * ```typescript
 * import {
 *   allParentPaths,
 * } from '@sqlw/file-async-ts';
 *
 * const result: string[] = allParentPaths('/cat/mouse');
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

/**
 * Associates content with it's source.
 *
 * **@example**
 * If the content source is a file then source would be the path to the file.
 */
export interface ContentSource<ContentType> {

  /**
   * The source of the content.
   *
   * **@example**
   * A path to a file.
   */
  sourcePath: string,

  /**
   * The content at the source of the type defined by the generic.
   *
   * **@example**
   * The contents of a file.
   */
  content: ContentType
}

export type ContentSources<ContentType> = ContentSource<ContentType>[];

/**
 * `fileContentDetailStr` function signature.
 */

export type FileContentDetailStrSignature = (
  path: string,
  options?: ReadOptions,
) => Promise<ContentSource<string> | undefined>;

/**
 * Reads the contents of a file, converting the contents to a string, and
 * returning the contents of the file associated with the path of the file.
 *
 * * **@param path** -  The absolute or relative path to the file.
 * * **@param [options]**
 *   * **[options.required=true]** - When `true` or `undefined`, when the file is
 *   not found an exception is thrown. When `false`, no exception is thrown and
 *   `undefined` is returned.
 * * **@throws** - An error is thrown if the file is not found and
 * `options.required` was set to true.
 * * **returns** - The contents of the file along with the associated path.
 * Undefined may be returned if the `options.required` was set to false.
 *
 * **@example**
 * Return file meta data and content details.
 *
 * ```typescript
 * import { join } from 'node:path';
 * import { fileContentDetailStr } from '@sqlw/file-async-ts';
 *
 * (async () => {
 *   const dir = join(__dirname, 'test-files', 'info.txt');
 *   const contentDetail = await fileContentDetailStr(dir);
 *   expect(contentDetail?.content)
 *     .toEqual('A file with content.');
 *   expect(contentDetail?.filePath)
 *     .toMatch(/[\S]*\/__tests__\/test-files\/info.txt$/);
 * })();
 * ```
*/
export const fileContentDetailStr: FileContentDetailStrSignature = async (
  path: string,
  options?: ReadOptions,
): Promise<ContentSource<string> | undefined> => {
  const content = await readFileString(path, options);
  return content === undefined ? undefined
    : {
      sourcePath: path,
      content,
    };
};
