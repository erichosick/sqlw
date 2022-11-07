import {
  join,
} from 'node:path';

import {
  readFileString,
} from '../src/index';

describe('readFileString', () => {
  it('should read a file', async () => {
    const dir = join(__dirname, 'read-file-as-string.unit.spec.ts');
    const content: string | undefined = await readFileString(dir);
    expect(content).toBeDefined();
  });

  it('should NOT error if a file is not found and required = false', async () => {
    const dir = join(__dirname, 'no_such_file.txt');
    const content: string | undefined = await readFileString(dir, { required: false });
    expect(content).toBeUndefined();
  });

  it('should error if a file is not found and the required option is true', async () => {
    const dir = join(__dirname, 'no_such_file.txt');
    await expect(readFileString(dir))
      .rejects
      .toThrow(/^ENOENT: no such file or directory, open '[\S]*__tests__\/no_such_file.txt'$/);
  });
});
