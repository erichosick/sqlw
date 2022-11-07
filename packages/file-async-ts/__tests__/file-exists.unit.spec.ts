import {
  join,
} from 'node:path';

import {
  fileExists,
} from '../src/index';

describe('fileExists', () => {
  it('should return true if a file exits', async () => {
    const dir = join(__dirname, 'file-exists.unit.spec.ts');
    const exists: boolean = await fileExists(dir);
    expect(exists).toEqual(true);
  });

  it('should return false if a file does not exist', async () => {
    const dir = join(__dirname, 'no-such-file.txt');
    const exists: boolean = await fileExists(dir);
    expect(exists).toEqual(false);
  });
});
