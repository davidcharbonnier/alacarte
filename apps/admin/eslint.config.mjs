import { dirname } from "path";
import { fileURLToPath } from "url";
import { FlatCompat } from "@eslint/eslintrc";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const compat = new FlatCompat({
  baseDirectory: __dirname,
});

const eslintConfig = [
  {
    ignores: [
      "**/node_modules/**",
      "**/.next/**",
      "**/out/**",
      "**/build/**",
      "**/*.d.ts",
    ],
  },
  ...compat.extends("next/core-web-vitals", "next/typescript"),
  {
    rules: {
      // Allow 'any' type in specific cases (backend data transformation)
      '@typescript-eslint/no-explicit-any': 'off',
      // Allow @ts-ignore comments
      '@typescript-eslint/ban-ts-comment': 'off',
      // Allow unused vars with underscore prefix
      '@typescript-eslint/no-unused-vars': [
        'warn',
        {
          argsIgnorePattern: '^_',
          varsIgnorePattern: '^_',
          caughtErrorsIgnorePattern: '^_',
        },
      ],
      // Allow 'this' aliasing (needed in some polyfills)
      '@typescript-eslint/no-this-alias': 'off',
      // Allow empty object types
      '@typescript-eslint/no-empty-object-type': 'off',
      // Allow triple-slash references in type definition files
      '@typescript-eslint/triple-slash-reference': 'off',
    },
  },
];

export default eslintConfig;
