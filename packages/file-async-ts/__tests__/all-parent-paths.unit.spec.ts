import {
  allParentPaths,
} from '../src/index';

describe('allParentPaths', () => {
  describe('POSIX', () => {
    it(`should return all all possible parent paths 
      including the child path`, async () => {
      const result: string[] = allParentPaths('/cat/mouse');
      expect(result).toEqual([
        '/cat/mouse',
        '/cat',
        '/',
      ]);
    });

    it(`should normalize the child path before return all all possible
    parent paths  including the child path`, async () => {
      const result: string[] = allParentPaths('/cat/../and/mouse');
      expect(result).toEqual(
        [
          '/and/mouse',
          '/and',
          '/',
        ],
      );
    });

    it('should expect an absolute path', () => {
      expect(() => { allParentPaths('../cat'); })
        .toThrowError('The path \'../cat\' must be an absolute path.');
    });
  });
});
