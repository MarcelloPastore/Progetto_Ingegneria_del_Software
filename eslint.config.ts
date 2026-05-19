import tseslint from "typescript-eslint";
import eslintPluginSecurity from "eslint-plugin-security";
import eslintPluginSonarjs from "eslint-plugin-sonarjs";
import eslintPluginPrettier from "eslint-plugin-prettier";
import eslintConfigPrettier from "eslint-config-prettier";

export default [
  {
    ignores: ["dist/", "node_modules/", "prisma/"],
  },

  ...tseslint.configs.recommendedTypeChecked,
  eslintPluginSecurity.configs.recommended,
  ...(eslintPluginSonarjs.configs?.recommended
    ? [eslintPluginSonarjs.configs.recommended]
    : []),

  {
    files: ["src/**/*.ts", "index.ts", "eslint.config.ts", "prisma.config.ts"],
    languageOptions: {
      parserOptions: {
        projectService: true,
        tsconfigRootDir: process.cwd(),
      },
    },
    plugins: {
      prettier: eslintPluginPrettier,
    },
    rules: {
      "prettier/prettier": "error",

      "@typescript-eslint/no-explicit-any": "warn",
      "@typescript-eslint/no-unused-vars": [
        "error",
        {
          argsIgnorePattern: "^_",
          varsIgnorePattern: "^_",
        },
      ],
      "security/detect-object-injection": "off",
      "no-console": ["warn", { allow: ["warn", "error", "info"] }],
    },
  },
  eslintConfigPrettier,
];
