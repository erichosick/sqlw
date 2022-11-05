# **@sqlw/parse-json-ts**

`pares-json-ts` is a typescript package that converts JSON text to a javascript object: optionally verifying and casting the object type.

## Features

* 100% typescript.
* Can be used with json validators such as:
  * [joi](https://joi.dev/)
  * [yup](https://github.com/jquense/yup)
  * [ts-json-validator](https://www.npmjs.com/package/ts-json-validator)
  * [ts.data.json](https://www.npmjs.com/package/ts.data.json)
  * [typedjson](<https://www.npmjs.com/package/@upe/typedjson>)

## Usage

## **parseJson<DataType>** - Converting A String to a Javascript Object

Convert a string to a javascript object using the generic function
`parseJson`. When `options.verify` is provided, parseJson can confirm that
the object is of the type returned by the generic.

* **@param data** - The string data which contains JSON.
* **@param [options]**
  * [options.verify] - Verifies that the parsed object is of the desired type.
  * [options.revive] - Mutate the object during parsing.
* **@error** - Throws an error if the data is not valid JSON. If provided,
  `verify` might also throw an error.
* **@returns** - A javascript object of the type defined by the generic.

Example conversion without verification:

```typescript
const json = '{"name": "Happy User", "age": 23}';

const user: unknown = parseJson(json);
expect(user).toEqual({
  name: 'Happy User',
  age: 23,
});
```

### VerifySignature - Verifying Parsed Json Is Of A Given Type

Use a verify function to verify that the parsed JSON is of the expected type.

The verify function should return `true` when the JSON is of the expected
type. The verify function should throw an `Error` otherwise.

Example verify function:

```typescript
const verifyUser: VerifySignature = (
  obj: object,
): true => {
  let verified = false;
  if (Array.isArray(obj)) {
    for (const item of obj) {
      if (!('name' in item && 'age' in item)) {
        break;
      }
    }
    verified = true;
  }

  if (verified) {
    return true;
  }
  throw Error('Unable to parse JSON to a User[] type.');
};

const json = '[{"name": "Happy User", "age": 23}]';
const user: User[] = parseJson<User[]>(json, { verify: verifyUser });

expect(user).toEqual([{
  name: 'Happy User',
  age: 23,
}]);
```

### ReviverSignature - Altering Values During Parsing

Use a reviver function to transform values during parsing.

Each member of the parsed object leads to a call to the reviver function.
For members with nested objects, the transformation of that nested object
occurs before the member.

**Warning:** The reviver function can't be implemented using an arrow
function.

* **@param this** - The complete parsed object instance.
* **@param key** - The active member in review.
* **@param value** - The active member's value.
* **@returns** - The final member's value.

 Example reviver function:

```typescript
interface User {
  name: string;
  age: number;
}

const reviverUser: ReviverSignature = function reviver(
  this: unknown,
  key: string,
  value: any,
): any {
  let newValue = value;
  if (key === 'age') {
    newValue += 1;
  }
  return newValue;
};

const userJson = '[{"name": "Happy User", "age": 23}]';

// Warning: Without providing a verify function, casting of the parsed
// json to User[] is done without verification and could lead to runtime
// errors.
const user: User[] = parseJson<User[]>(
  userJson,
  { reviver: reviverUser },
);

expect(user[0].age).toEqual(24);
```

## Intent

* No Emitted Javascript - The intent is to import this typescript library into a typescript project: compiling to Javascript occurring within the project.

## Development

See the [monorepo readme](https://www.github.com/erichosick/sqlw).

## License

Licensed under [MIT](./LICENSE.md).
