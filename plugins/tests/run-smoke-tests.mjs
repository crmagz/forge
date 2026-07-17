#!/usr/bin/env node

import {
  mkdtempSync,
  mkdirSync,
  rmSync,
  writeFileSync,
} from 'node:fs';
import {tmpdir} from 'node:os';
import {join, resolve} from 'node:path';
import {spawnSync} from 'node:child_process';

const PLUGINS_ROOT = resolve(import.meta.dirname, '..');
const GOVERNANCE_VALIDATOR = join(
  PLUGINS_ROOT,
  'enterprise/governance/scripts/validate-governance.mjs',
);
const PLAN_RESOLVER = join(
  PLUGINS_ROOT,
  'enterprise/foundation/skills/ai-plan/scripts/resolve-plan-path.mjs',
);

function runNode(script, args, options = {}) {
  return spawnSync(process.execPath, [script, ...args], {
    encoding: 'utf8',
    ...options,
  });
}

function assertSuccess(result, label) {
  if (result.status !== 0) {
    throw new Error(`${label} failed:\n${result.stderr || result.stdout}`);
  }
}

function assertFailure(result, label) {
  if (result.status === 0) {
    throw new Error(`${label} unexpectedly succeeded.`);
  }
}

const temporaryRoot = mkdtempSync(join(tmpdir(), 'forge-plugin-smoke-'));
try {
  assertSuccess(runNode(GOVERNANCE_VALIDATOR, []), 'Catalog validation');
  assertSuccess(
    runNode(GOVERNANCE_VALIDATOR, [
      '--repository',
      join(PLUGINS_ROOT, 'enterprise/governance/tests/fixtures/sre-python-service'),
    ]),
    'Fixture repository validation',
  );

  const governedRepository = join(temporaryRoot, 'governed-repository');
  mkdirSync(join(governedRepository, '.claude'), {recursive: true});
  writeFileSync(
    join(governedRepository, '.claude/governance.json'),
    JSON.stringify({
      version: 1,
      profiles: ['sre-python-service'],
      exceptions: ['self-authorized-exception'],
    }),
  );
  assertFailure(
    runNode(GOVERNANCE_VALIDATOR, [
      '--repository',
      governedRepository,
      '--repository-id',
      'example-org/governed-repository',
    ]),
    'Self-authorized exception validation',
  );

  const planHome = join(temporaryRoot, 'plan-home');
  const planResult = runNode(
    PLAN_RESOLVER,
    ['--repo-root', governedRepository, '--ticket', 'TEST-123', '--title', 'Plugin smoke'],
    {
      cwd: governedRepository,
      env: {...process.env, AI_PLAN_HOME: planHome},
    },
  );
  assertSuccess(planResult, 'Plugin-scoped plan path resolution');
  const plan = JSON.parse(planResult.stdout);
  if (!plan.planPath.startsWith(join(planHome, 'plans'))) {
    throw new Error(`Plan path was not rooted in AI_PLAN_HOME: ${plan.planPath}`);
  }

  console.log('Plugin smoke tests passed.');
} finally {
  rmSync(temporaryRoot, {force: true, recursive: true});
}
