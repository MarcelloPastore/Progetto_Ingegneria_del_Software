import tseslint from 'typescript-eslint';
import eslintPluginSecurity from 'eslint-plugin-security';
import eslintPluginPrettier from 'eslint-plugin-prettier';
import eslintConfigPrettier from 'eslint-config-prettier';

export default [
    {
        ignores: ['dist/', 'node_modules/', 'prisma/']
    },

    ...tseslint.configs.recommended,
    eslintPluginSecurity.configs.recommended,

    {
        files: ['src/**/*.ts'],
        plugins: {
            'prettier': eslintPluginPrettier,
        },
        rules: {
            'prettier/prettier': 'error',

            '@typescript-eslint/no-explicit-any': 'warn',
            '@typescript-eslint/no-unused-vars': [
                'error',
                {
                    argsIgnorePattern: '^_',
                    varsIgnorePattern: '^_',
                },
            ],
            'no-console': ['warn', { allow: ['warn', 'error', 'info'] }],
        },
    },
    eslintConfigPrettier,
];