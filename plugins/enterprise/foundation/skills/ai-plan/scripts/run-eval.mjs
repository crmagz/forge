#!/usr/bin/env node
// Behavioral eval runner for the ai-plan skill. Classification-only
// v1: feeds each corpus scenario to a headless `claude -p` run alongside the
// skill instructions, parses the declared risk tier, and compares it to the
// scenario's expectedRisk. Manual/nightly use only — not part of `npm test`.

import { readFileSync, writeFileSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const SCRIPT_DIR = dirname(fileURLToPath(import.meta.url));
const SKILL_DIR = resolve(SCRIPT_DIR, '..');
const PLUGIN_ROOT = resolve(SKILL_DIR, '../..');
const SKILL_PATH = resolve(SKILL_DIR, 'SKILL.md');
const CORPUS_PATH = resolve(
  PLUGIN_ROOT,
  'tests/fixtures/ai-plan/eval-corpus.json',
);
const DEFAULT_REPORT_PATH = resolve(
  PLUGIN_ROOT,
  'tests/fixtures/ai-plan/eval-report.json',
);

const RISK_TIERS = ['Small', 'Medium', 'Large', 'High-risk'];
const RISK_LINE_PATTERN = new RegExp(
  `^Risk:\\s*(${RISK_TIERS.join('|')})\\s*$`,
  'im',
);

export function buildEvalPrompt(skillContent, scenario) {
  return [
    'You are applying the following planning skill instructions exactly.',
    'Do not use tools, do not access the filesystem, and do not perform repo',
    'discovery — classify from the scenario description alone.',
    '',
    '--- SKILL INSTRUCTIONS START ---',
    skillContent,
    '--- SKILL INSTRUCTIONS END ---',
    '',
    `Scenario request: "${scenario.prompt}"`,
    `Input mode: ${scenario.inputMode}`,
    '',
    "Apply the skill's Risk Escalation Rules and state which tier applies.",
    'End your response with exactly one line in this format, with no other',
    'text on that line:',
    'Risk: <Small|Medium|Large|High-risk>',
  ].join('\n');
}

export function parseRiskFromOutput(output) {
  const match = output.match(RISK_LINE_PATTERN);
  if (!match) {
    return null;
  }
  return (
    RISK_TIERS.find(tier => tier.toLowerCase() === match[1].toLowerCase()) ??
    null
  );
}

function invokeClaude(prompt) {
  const result = spawnSync('claude', ['-p', prompt], {
    encoding: 'utf-8',
    maxBuffer: 20 * 1024 * 1024,
  });
  if (result.error) {
    throw new Error(`failed to invoke claude CLI: ${result.error.message}`);
  }
  if (result.status !== 0) {
    throw new Error(
      `claude CLI exited with status ${result.status}: ${result.stderr}`,
    );
  }
  return result.stdout;
}

export function evaluateScenario(scenario, skillContent, invoke = invokeClaude) {
  const prompt = buildEvalPrompt(skillContent, scenario);
  try {
    const output = invoke(prompt);
    const actualRisk = parseRiskFromOutput(output);
    return {
      id: scenario.id,
      expectedRisk: scenario.expectedRisk,
      actualRisk,
      pass: actualRisk === scenario.expectedRisk,
      outputExcerpt: output.slice(-400),
    };
  } catch (error) {
    return {
      id: scenario.id,
      expectedRisk: scenario.expectedRisk,
      actualRisk: null,
      pass: false,
      error: error instanceof Error ? error.message : String(error),
    };
  }
}

export function summarizeResults(results) {
  const total = results.length;
  const passed = results.filter(result => result.pass).length;
  const errored = results.filter(result => result.error).length;
  return {
    total,
    passed,
    failed: total - passed,
    errored,
    passRate: total === 0 ? 0 : passed / total,
  };
}

function getArgValue(args, flag) {
  const index = args.indexOf(flag);
  return index === -1 ? undefined : args[index + 1];
}

function main() {
  const args = process.argv.slice(2);
  const scenarioFilter = getArgValue(args, '--scenario');
  const outPath = getArgValue(args, '--out') ?? DEFAULT_REPORT_PATH;

  const versionCheck = spawnSync('claude', ['--version'], {
    encoding: 'utf-8',
  });
  if (versionCheck.error) {
    console.error(
      'claude CLI not found. Install Claude Code CLI before running the behavioral eval.',
    );
    process.exitCode = 1;
    return;
  }

  const skillContent = readFileSync(SKILL_PATH, 'utf-8');
  const corpus = JSON.parse(readFileSync(CORPUS_PATH, 'utf-8'));
  const scenarios = scenarioFilter
    ? corpus.scenarios.filter(scenario => scenario.id === scenarioFilter)
    : corpus.scenarios;

  if (scenarios.length === 0) {
    console.error(`No scenarios matched filter: ${scenarioFilter}`);
    process.exitCode = 1;
    return;
  }

  const results = [];
  for (const scenario of scenarios) {
    process.stdout.write(`Evaluating ${scenario.id}... `);
    const result = evaluateScenario(scenario, skillContent);
    results.push(result);
    console.log(
      result.pass
        ? 'PASS'
        : `FAIL (expected ${result.expectedRisk}, got ${result.actualRisk ?? 'none'})`,
    );
  }

  const summary = summarizeResults(results);
  const report = {
    generatedAt: new Date().toISOString(),
    corpusVersion: corpus.version,
    summary,
    results,
  };

  writeFileSync(outPath, JSON.stringify(report, null, 2));
  console.log(
    `\n${summary.passed}/${summary.total} scenarios passed. Report written to ${outPath}`,
  );

  process.exitCode = summary.passed === summary.total ? 0 : 1;
}

const isMainModule =
  process.argv[1] && import.meta.url === `file://${process.argv[1]}`;
if (isMainModule) {
  main();
}
