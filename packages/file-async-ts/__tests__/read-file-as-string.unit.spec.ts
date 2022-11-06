import { join } from 'node:path';
import { readFileAsString } from '../src/index';

describe('readFileAsString', () => {
  it('should read a file', async () => {
    const dir = join(__dirname, 'read-file-as-string.unit.spec.ts');
    const content = await readFileAsString(dir);
    expect(content).toBeDefined();
  });

  it('should NOT error if a file is not found and required = false', async () => {
    const dir = join(__dirname, 'no_such_file.txt');
    const content = await readFileAsString(dir, { required: false });
    expect(content).toBeUndefined();
  });

  it('should error if a file is not found and the required option is true', async () => {
    const dir = join(__dirname, 'no_such_file.txt');
    await expect(readFileAsString(dir))
      .rejects
      .toThrow(/^ENOENT: no such file or directory, open '[\S]*__tests__\/no_such_file.txt'$/);
  });
});
