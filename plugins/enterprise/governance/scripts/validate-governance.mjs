#!/usr/bin/env node

import {existsSync, readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import process from 'node:process';

const PLUGIN_ROOT = resolve(import.meta.dirname, '..');
const MARKETPLACE_ROOT = resolve(PLUGIN_ROOT, '../..');
const CATALOG_PATH = resolve(
  PLUGIN_ROOT,
  'skills/governance-profile-router/references/governance-catalog.json',
);
const APPROVED_EXCEPTIONS_PATH = resolve(
  PLUGIN_ROOT,
  'skills/governance-profile-router/references/approved-exceptions.json',
);

function readJson(filePath) {
  try {
    return JSON.parse(readFileSync(filePath, 'utf8'));
  } catch (error) {
    throw new Error(`Cannot parse ${filePath}: ${error.message}`);
  }
}

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

function parseArgs(args) {
  const repositoryIndex = args.indexOf('--repository');
  const repositoryIdIndex = args.indexOf('--repository-id');
  return {
    repository:
      repositoryIndex === -1 ? undefined : args[repositoryIndex + 1],
    repositoryId:
      repositoryIdIndex === -1 ? undefined : args[repositoryIdIndex + 1],
  };
}

function assertString(value, message) {
  assert(typeof value === 'string' && value.trim().length > 0, message);
}

function assertExpiredAtIsFuture(expiresAt, message) {
  assertString(expiresAt, message);
  const expiry = Date.parse(expiresAt);
  assert(Number.isFinite(expiry), message);
  assert(expiry > Date.now(), message);
}

function validateCatalog() {
  const catalog = readJson(CATALOG_PATH);
  assert(catalog.version === 1, 'Catalog version must be 1.');
  assert(Array.isArray(catalog.profiles), 'Catalog profiles must be an array.');

  const profiles = new Map();
  for (const entry of catalog.profiles) {
    assert(typeof entry.id === 'string', 'Each catalog profile needs an id.');
    assert(typeof entry.plugin === 'string', `Profile ${entry.id} needs a plugin.`);
    assert(typeof entry.path === 'string', `Profile ${entry.id} needs a path.`);
    assert(!profiles.has(entry.id), `Duplicate profile id: ${entry.id}`);

    const pluginRoot = resolve(MARKETPLACE_ROOT, entry.path);
    const manifestPath = resolve(pluginRoot, '.claude-plugin/plugin.json');
    const descriptorPath = resolve(pluginRoot, '.governance-profile.json');
    assert(existsSync(manifestPath), `Missing plugin manifest for ${entry.id}.`);
    assert(existsSync(descriptorPath), `Missing profile descriptor for ${entry.id}.`);

    const manifest = readJson(manifestPath);
    const descriptor = readJson(descriptorPath);
    assert(manifest.name === entry.plugin, `Manifest name mismatch for ${entry.id}.`);
    assert(descriptor.id === entry.id, `Descriptor id mismatch for ${entry.id}.`);
    assert(descriptor.tier === entry.tier, `Descriptor tier mismatch for ${entry.id}.`);
    assert(Array.isArray(descriptor.requires), `Profile ${entry.id} requires must be an array.`);
    assert(Array.isArray(descriptor.owns), `Profile ${entry.id} owns must be an array.`);
    assert(Array.isArray(descriptor.incompatibleWith), `Profile ${entry.id} incompatibleWith must be an array.`);
    profiles.set(entry.id, descriptor);
  }

  for (const [id, descriptor] of profiles) {
    for (const dependency of descriptor.requires) {
      assert(profiles.has(dependency), `${id} requires unknown profile ${dependency}.`);
      assert(dependency !== id, `${id} cannot require itself.`);
    }
    for (const incompatibleProfile of descriptor.incompatibleWith) {
      assert(profiles.has(incompatibleProfile), `${id} is incompatible with unknown profile ${incompatibleProfile}.`);
    }
  }

  const concernOwners = new Map();
  for (const [id, descriptor] of profiles) {
    for (const concern of descriptor.owns) {
      const existingOwner = concernOwners.get(concern);
      assert(
        !existingOwner,
        `${id} and ${existingOwner} both own ${concern}; split the concern or define a single owner.`,
      );
      concernOwners.set(concern, id);
    }
  }

  const visiting = new Set();
  const visited = new Set();
  function visit(id) {
    assert(!visiting.has(id), `Dependency cycle includes ${id}.`);
    if (visited.has(id)) return;
    visiting.add(id);
    for (const dependency of profiles.get(id).requires) visit(dependency);
    visiting.delete(id);
    visited.add(id);
  }
  for (const id of profiles.keys()) visit(id);

  return profiles;
}

function validateApprovedExceptions() {
  const registry = readJson(APPROVED_EXCEPTIONS_PATH);
  assert(registry.version === 1, 'Approved exceptions version must be 1.');
  assert(Array.isArray(registry.exceptions), 'Approved exceptions must be an array.');

  const exceptions = new Map();
  for (const exception of registry.exceptions) {
    assertString(exception.id, 'Each approved exception needs an id.');
    assertString(exception.repository, `Approved exception ${exception.id} needs a repository.`);
    assertString(exception.rule, `Approved exception ${exception.id} needs a rule.`);
    assertString(exception.reason, `Approved exception ${exception.id} needs a reason.`);
    assertString(exception.owner, `Approved exception ${exception.id} needs an owner.`);
    assertString(exception.approvedBy, `Approved exception ${exception.id} needs an approver.`);
    assertString(exception.approvalRef, `Approved exception ${exception.id} needs an approval reference.`);
    assertExpiredAtIsFuture(
      exception.expiresAt,
      `Approved exception ${exception.id} needs an unexpired ISO-8601 expiresAt timestamp.`,
    );
    assert(!exceptions.has(exception.id), `Duplicate approved exception id: ${exception.id}.`);
    exceptions.set(exception.id, exception);
  }
  return exceptions;
}

function validateRepository(repository, repositoryId, profiles, approvedExceptions) {
  const configPath = resolve(repository, '.claude/governance.json');
  assert(existsSync(configPath), `Missing repository profile: ${configPath}`);
  const config = readJson(configPath);
  const allowedKeys = new Set(['version', 'profiles', 'exceptions']);
  for (const key of Object.keys(config)) {
    assert(allowedKeys.has(key), `Repository governance does not allow property ${key}.`);
  }
  assert(config.version === 1, 'Repository governance version must be 1.');
  assert(Array.isArray(config.profiles) && config.profiles.length > 0, 'Repository must select at least one profile.');
  assert(config.profiles.every(id => typeof id === 'string'), 'Repository profile ids must be strings.');

  const selected = new Set(config.profiles);
  assert(selected.size === config.profiles.length, 'Repository profiles must be unique.');
  for (const id of selected) {
    assert(profiles.has(id), `Repository selects unknown profile ${id}.`);
  }
  for (const id of selected) {
    for (const incompatibleProfile of profiles.get(id).incompatibleWith) {
      assert(!selected.has(incompatibleProfile), `${id} conflicts with ${incompatibleProfile}.`);
    }
  }
  if (config.exceptions !== undefined) {
    assert(Array.isArray(config.exceptions), 'Repository exceptions must be an array of approved exception ids.');
    assert(config.exceptions.every(id => typeof id === 'string' && id.length > 0), 'Repository exception ids must be non-empty strings.');
  }
  for (const exceptionId of config.exceptions ?? []) {
    assertString(repositoryId, 'A canonical --repository-id is required when a repository references an exception.');
    const exception = approvedExceptions.get(exceptionId);
    assert(exception, `Repository references unknown approved exception ${exceptionId}.`);
    assert(exception.repository === repositoryId, `Approved exception ${exceptionId} is not authorized for ${repositoryId}.`);
    assertExpiredAtIsFuture(exception.expiresAt, `Approved exception ${exceptionId} is expired.`);
  }
}

try {
  const profiles = validateCatalog();
  const approvedExceptions = validateApprovedExceptions();
  const {repository, repositoryId} = parseArgs(process.argv.slice(2));
  if (repository) validateRepository(repository, repositoryId, profiles, approvedExceptions);
  console.log(repository ? `Governance catalog and ${repository} are valid.` : 'Governance catalog is valid.');
} catch (error) {
  console.error(`Governance validation failed: ${error.message}`);
  process.exitCode = 1;
}
