/** Conventional Commits — see docs/coding-conventions.md §10. */
export default {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'scope-case': [2, 'always', 'kebab-case'],
    'subject-case': [0],
  },
};
