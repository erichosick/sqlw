type AddSignature = <T>(left: T, right: T) => T;
type AddSignature2 = (left: number, right: number) => number;

const add: AddSignature = (left: number, right: number): number => {
  // eslint-disable-next-line no-console
  console.log(left);
  return left + right;
};

export default add;

const foo = <T,>(x: T) => x;

const foo2 = <T>(x: T) => x; // ERROR : unclosed `T` tag

const foo3 = <T extends unknown>(x: T) => x;

// https://www.reddit.com/r/typescript/comments/mmgnbd/x_could_be_instantiated_with_an_arbitrary_type/
// https://stackoverflow.com/questions/32308370/what-is-the-syntax-for-typescript-arrow-functions-with-generics
// https://www.typescriptlang.org/docs/handbook/2/generics.html
// see https://github.com/vitejs/vite/issues/6147
// trailing comma for .jsx files that want to use generics.

// Newer typescript compilers also support trailing comma const foo = <T,>(x: T) => x; to sidestep the JSX ambiguity. –  Thomas May 21, 2019 at 16:54
