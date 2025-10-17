module.exports = {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'scope-enum': [
      2,
      'always',
      [
        'api',
        'client',
        'admin',
        'deps',
        'ci',
        'docs',
        'release'
      ]
    ],
    'scope-empty': [2, 'never'],
    'subject-case': [2, 'always', 'sentence-case']
  }
};
