import {
  parseJson,
} from '../src/index';

describe('parseJson', () => {
  it('should parse json without providing a DataType', async () => {
    const json = '{"name": "Happy User", "age": 23}';

    const user: unknown = parseJson(json);
    expect(user).toEqual({
      name: 'Happy User',
      age: 23,
    });
  });

  it('should parse json while providing a DataType', async () => {
    interface User {
      name: string;
      age: number;
    }

    const json = '{"name": "Happy User", "age": 23}';

    const user: User = parseJson<User>(json);
    expect(user).toEqual({
      name: 'Happy User',
      age: 23,
    });
  });

  it('should throw an error when invalid json is provided', async () => {
    const json = '{"name": "Happy User", age": 23}';
    expect(() => { parseJson(json); })
      .toThrow('Unexpected token a in JSON at position 23');
  });
});
