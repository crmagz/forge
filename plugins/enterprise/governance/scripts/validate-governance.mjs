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
  return {
    repository:
      repositoryIndex === -1 ? undefined : args[repositoryIndex + 1],
  };
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

function validateRepository(repository, profiles) {
  const configPath = resolve(repository, '.claude/governance.json');
  assert(existsSync(configPath), `Missing repository profile: ${configPath}`);
  const config = readJson(configPath);
  assert(config.version === 1, 'Repository governance version must be 1.');
  assert(Array.isArray(config.profiles) && config.profiles.length > 0, 'Repository must select at least one profile.');

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
  for (const exception of config.exceptions ?? []) {
    assert(exception.rule && exception.reason && exception.owner && exception.expires, 'Exceptions need rule, reason, owner, and expires.');
    assert(new Date(`${exception.expires}T00:00:00Z`) >= new Date(), `Exception for ${exception.rule} is expired.`);
  }
}

try {
  const profiles = validateCatalog();
  const {repository} = parseArgs(process.argv.slice(2));
  if (repository) validateRepository(repository, profiles);
  console.log(repository ? `Governance catalog and ${repository} are valid.` : 'Governance catalog is valid.');
} catch (error) {
  console.error(`Governance validation failed: ${error.message}`);
  process.exitCode = 1;
}
