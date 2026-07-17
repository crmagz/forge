#!/usr/bin/env node

import path from 'node:path';
import {homedir} from 'node:os';

function parseArgs(argv) {
  const args = {};
  for (let index = 0; index < argv.length; index += 1) {
    const arg = argv[index];
    if (!arg.startsWith('--')) continue;
    const key = arg.slice(2);
    const next = argv[index + 1];
    if (!next || next.startsWith('--')) {
      args[key] = true;
      continue;
    }
    args[key] = next;
    index += 1;
  }
  return args;
}

function kebabCase(value) {
  return String(value ?? '')
    .trim()
    .replace(/\.git$/i, '')
    .replace(/([a-z0-9])([A-Z])/g, '$1-$2')
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
    .replace(/-{2,}/g, '-');
}

function basenameFromRepoRoot(repoRoot) {
  if (!repoRoot || typeof repoRoot !== 'string') {
    throw new Error('--repo-root is required');
  }

  const trimmed = repoRoot.trim().replace(/[\\/]+$/g, '');
  if (!trimmed) {
    throw new Error('--repo-root cannot be empty');
  }

  let basename;
  if (/^[a-z]+:\/\//i.test(trimmed)) {
    const url = new URL(trimmed);
    basename = url.pathname.split('/').filter(Boolean).pop();
  } else {
    basename = trimmed.split(/[\\/]/).filter(Boolean).pop();
  }

  const baseRepo = kebabCase(basename);
  if (!baseRepo) {
    throw new Error(`could not derive baseRepo from repo root: ${repoRoot}`);
  }
  if (baseRepo.includes('/') || baseRepo.includes('\\')) {
    throw new Error(`baseRepo must be a single directory basename: ${baseRepo}`);
  }
  return baseRepo;
}

function expandHome(input) {
  if (!input) return input;
  if (input === '~') return homedir();
  if (input.startsWith('~/')) return path.join(homedir(), input.slice(2));
  return input;
}

function defaultPlanHome(args) {
  if (args['plan-home']) return expandHome(args['plan-home']);
  if (process.env.AI_PLAN_HOME) return expandHome(process.env.AI_PLAN_HOME);

  const agent = String(args.agent ?? process.env.AI_PLAN_AGENT ?? '').toLowerCase();
  if (agent === 'cursor') return path.join(homedir(), '.cursor');
  if (agent === 'claude') return path.join(homedir(), '.claude');

  if (process.env.CURSOR_TRACE_ID || process.env.CURSOR_SESSION_ID) {
    return path.join(homedir(), '.cursor');
  }

  return path.join(homedir(), '.claude');
}

function buildFileName({ticket, title}) {
  const ticketSlug = kebabCase(ticket);
  const titleSlug = kebabCase(title || 'plan');

  if (!ticketSlug) return `${titleSlug}.plan.md`;
  if (!titleSlug || titleSlug === 'plan') return `${ticketSlug}.plan.md`;
  if (titleSlug.startsWith(ticketSlug)) return `${titleSlug}.plan.md`;
  return `${ticketSlug}-${titleSlug}.plan.md`;
}

function resolvePlanPath(args) {
  const repoRoot = args['repo-root'] ?? args.repo;
  const baseRepo = basenameFromRepoRoot(repoRoot);
  const planHome = path.resolve(defaultPlanHome(args));
  const fileName = buildFileName({
    ticket: args.ticket,
    title: args.title,
  });
  const parentDir = path.join(planHome, 'plans', baseRepo);
  const planPath = path.join(parentDir, fileName);

  return {
    planHome,
    baseRepo,
    fileName,
    parentDir,
    planPath,
  };
}

try {
  const args = parseArgs(process.argv.slice(2));
  const result = resolvePlanPath(args);
  if (args['path-only']) {
    process.stdout.write(`${result.planPath}\n`);
  } else {
    process.stdout.write(`${JSON.stringify(result, null, 2)}\n`);
  }
} catch (error) {
  process.stderr.write(`${error.message}\n`);
  process.exitCode = 1;
}
