import tseslint from "typescript-eslint";
import eslintPluginAiGuard from "eslint-plugin-ai-guard";
import eslintPluginNoSecrets from "eslint-plugin-no-secrets";
import eslintPluginSecurity from "eslint-plugin-security";
import eslintPluginSonarjs from "eslint-plugin-sonarjs";
import eslintPluginPrettier from "eslint-plugin-prettier";
import eslintConfigPrettier from "eslint-config-prettier";

export default [
  {
    ignores: ["dist/", "node_modules/", "prisma/", "scripts/", "test/**/*.ts"],
  },

  ...tseslint.configs.recommendedTypeChecked,
  eslintPluginSecurity.configs.recommended,
  ...(eslintPluginSonarjs.configs?.recommended
    ? [eslintPluginSonarjs.configs.recommended]
    : []),

  {
    files: [
      "src/**/*.ts",
      //"test/**/*.ts",
      "index.ts",
      "eslint.config.ts",
      "prisma.config.ts",
      "vitest.config.ts",
    ],
    languageOptions: {
      parserOptions: {
        projectService: true,
        tsconfigRootDir: process.cwd(),
      },
    },
    plugins: {
      "ai-guard": eslintPluginAiGuard,
      "no-secrets": eslintPluginNoSecrets,
      prettier: eslintPluginPrettier,
    },
    rules: {
      "ai-guard/no-empty-catch": "error",
      "ai-guard/no-floating-promise": "error",
      "ai-guard/no-hardcoded-secret": "error",
      "ai-guard/no-async-array-callback": "warn",

      "no-secrets/no-secrets": [
        "warn",
        {
          tolerance: 4.5,
        },
      ],

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
