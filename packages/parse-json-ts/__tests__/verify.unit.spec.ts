import {
  parseJson,
  VerifySignature,
} from '../src/index';

describe('parseJson - verify', () => {
  interface User {
    name: string;
    age: number;
  }

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

  it('should verify a the json was a User type', async () => {
    const json = '[{"name": "Happy User", "age": 23}]';
    const user: User[] = parseJson<User[]>(json, { verify: verifyUser });

    expect(user).toEqual([{
      name: 'Happy User',
      age: 23,
    }]);
  });

  it(`should throw an error when the object we are
    verifying fails`, async () => {
    const json = '{"different": "object" }';
    expect(() => { parseJson(json, { verify: verifyUser }); })
      .toThrow('Unable to parse JSON to a User[] type.');
  });
});
