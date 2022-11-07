import {
  join,
} from 'node:path';

import {
  fileContentDetailStr,
} from '../src/index';

describe('fileContentDetailStr', () => {
  it('should read a file along with the contents', async () => {
    const dir = join(__dirname, 'test-files', 'info.txt');
    const contentDetail = await fileContentDetailStr(dir);
    expect(contentDetail?.content).toEqual('A file with content.');
    expect(contentDetail?.sourcePath)
      .toMatch(/[\S]*\/__tests__\/test-files\/info.txt$/);
  });

  it(`should NOT error if a file is not found and
    required = false`, async () => {
    const dir = join(__dirname, 'no_such_file.txt');
    const content = await fileContentDetailStr(dir, { required: false });
    expect(content).toBeUndefined();
  });

  it(`should error if a file is not found and the
    required option is true`, async () => {
    const dir = join(__dirname, 'no_such_file.txt');
    await expect(fileContentDetailStr(dir))
      .rejects
      .toThrow(/^ENOENT: no such file or directory, open '[\S]*__tests__\/no_such_file.txt'$/);
  });
});
