"use strict";

module.exports = {
  "env": {
    "browser": true,
    "es2021": true,
    "node": true,
  },
  "extends": [
    "eslint:recommended",
    "plugin:@typescript-eslint/recommended",
    // https://eh-career.com/engineerhub/entry/2021/08/26/110000
    "plugin:import/recommended",
    "plugin:import/typescript",
    "prettier"
  ],
  "parser": "@typescript-eslint/parser",
  "parserOptions": {
    "ecmaVersion": 12,
    "sourceType": "module"
  },
  "plugins": [
    "@typescript-eslint"
  ],
  "rules": {
    "no-unused-vars": ["warn", { "argsIgnorePattern": "^_" }],
    "@typescript-eslint/no-unused-vars": "off",
    "import/prefer-default-export": "warn",
    // https://eh-career.com/engineerhub/entry/2021/08/26/110000
    "import/no-unresolved": "off",
    "import/no-cycle": "error",
    // "import/no-default-export": "warn",
    "@typescript-eslint/array-type": ["warn", { default: "generic" }],
    "@typescript-eslint/naming-convention": [
      "warn",
      { "selector": "default", "format": ["camelCase", "UPPER_CASE", "PascalCase"], "leadingUnderscore": "allow" },
      { "selector": "typeLike", "format": ["PascalCase"], "leadingUnderscore": "allow" },
      { "selector": "objectLiteralProperty", "format": ["camelCase", "snake_case"], "leadingUnderscore": "allow" },
    ],
    // 以下はrecommendedに入っているものの、実用的には厳しすぎるためoff
    "@typescript-eslint/explicit-module-boundary-types": "off",
    "@typescript-eslint/no-explicit-any": "off",
    "@typescript-eslint/no-empty-interface": "off",
    "@typescript-eslint/no-empty-function": "off",
    "@typescript-eslint/no-var-requires": "off",
    "@typescript-eslint/no-non-null-assertion": "off",
    "@typescript-eslint/ban-ts-comment": "off"
  }
};
