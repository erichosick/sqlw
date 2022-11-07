import {
  parseJson,
  ReviverSignature,
} from '../src';

describe('parseJson - reviver', () => {
  it('should support a reviver function', () => {
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

    // @remarks: Without providing a verify function, casting of the parsed
    // json to User[] is done without verification and could lead to runtime
    // errors.
    const user: User[] = parseJson<User[]>(
      userJson,
      { reviver: reviverUser },
    );

    expect(user[0].age).toEqual(24);
  });
});
