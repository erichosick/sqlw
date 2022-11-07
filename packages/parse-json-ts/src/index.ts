/**
 * Use a reviver function to transform values during parsing.
 *
 * Each member of the parsed object leads to a call to the reviver function.
 * For members with nested objects, the transformation of that nested object
 * occurs before the member.
 *
 * **@remarks**
 * The reviver function can't be implemented using an arrow function.
 *
 * * **@param this** - The complete parsed object instance.
 * * **@param key** - The active member in review.
 * * **@param value** - The active member's value.
 * * **@returns** - The final member's value.
 *
 * **@example**
 * A reviver function that adds 1 to age.
 *
 * ```typescript
 * interface User {
 *   name: string;
 *   age: number;
 * }
 *
 * const reviverUser: ReviverSignature = function reviver(
 *   this: unknown,
 *   key: string,
 *   value: any,
 * ): any {
 *   let newValue = value;
 *   if (key === 'age') {
 *     newValue += 1;
 *   }
 *   return newValue;
 * };
 *
 * const userJson = '[{"name": "Happy User", "age": 23}]';
 *
 * // @remarks: Without providing a verify function, casting of the parsed
 * // json to User[] is done without verification and could lead to runtime
 * // errors.
 * const user: User[] = parseJson<User[]>(
 *   userJson,
 *   { reviver: reviverUser },
 * );
 *
 * expect(user[0].age).toEqual(24);
 * ```
*/
export type ReviverSignature = (
  this: any,
  key: string,
  value: any
) => any;

// -----------------------------------------------------------------------------

/**
 * Use a verify function to verify that the parsed JSON is of the expected type.
 *
 * The verify function should return `true` when the JSON is of the expected
 * type. The verify function should throw an `Error` otherwise.
 *
 * **@example**
 * Verify the object is a User.
 *
 * ```typescript
 * const verifyUser: VerifySignature = (
 *   obj: object,
 * ): true => {
 *   let verified = false;
 *   if (Array.isArray(obj)) {
 *     for (const item of obj) {
 *       if (!('name' in item && 'age' in item)) {
 *         break;
 *       }
 *     }
 *     verified = true;
 *   }
 *
 *   if (verified) {
 *     return true;
 *   }
 *   throw Error('Unable to parse JSON to a User[] type.');
 * };
 *
 * const json = '[{"name": "Happy User", "age": 23}]';
 * const user: User[] = parseJson<User[]>(json, { verify: verifyUser });
 *
 * expect(user).toEqual([{
 *   name: 'Happy User',
 *   age: 23,
 * }]);
```
*/
export type VerifySignature = (
  obj: object
) => true;

// -----------------------------------------------------------------------------

/**
 * Defines the parse options available to parseJson.
 */
export interface ParseOptions {

  /**
   * When provided, parseJson will apply the reviver function. See the
   * ReviverSignature documentation for details
   */
  reviver?: ReviverSignature

  /**
   * When provided, parseJson will apply the verify function. See the
   * VerifySignature documentation for details.
   */
  verify?: VerifySignature
}

/**
 * `parseJson` function signature.
 */
export type ParseJsonSignature = <DataType>(
  data: string,
  options?: ParseOptions,
) => DataType;

/**
 * Convert a string to a javascript object using the generic function
 * `parseJson`. When `options.verify` is provided, parseJson can confirm that
 * the object is of the type returned by the generic.
 *
 * * **@param data** - The string data which contains JSON.
 * * **@param [options]**
 *   * [options.verify] - Verifies that the parsed object is of the desired
 *   type.
 *   * [options.revive] - Mutate the object during parsing.
 * * **@throws** - Throws an error if the data is not valid JSON. If provided,
 *   `verify` might also throw an error.
 * * **@returns** - A javascript object of the type defined by the generic.
 *
 * **@example**
 * Conversion without verification.
 *
 * ```typescript
 * const json = '{"name": "Happy User", "age": 23}';
 *
 * const user: unknown = parseJson(json);
 * expect(user).toEqual({
 *   name: 'Happy User',
 *   age: 23,
 * });
```
*/
export const parseJson: ParseJsonSignature = <DataType>(
  data: string,
  options?: ParseOptions,
): DataType => {
  const parsed = JSON.parse(data, options?.reviver);

  if (options?.verify) {
    // Expect verify to throw an exception if the data is invalid
    options.verify(parsed);
  } // else {} we don't verify risking casting something incorrectly

  return parsed as DataType;
};
