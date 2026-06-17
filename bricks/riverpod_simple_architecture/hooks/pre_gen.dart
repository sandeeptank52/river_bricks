import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:mason/mason.dart';
import 'package:yaml/yaml.dart';

void run(HookContext context) {
  context.logger.info('Pre generation started');

  // Resolve project_name: prefer the declared var, fall back to host pubspec.yaml.
  final providedName =
      ((context.vars['project_name'] as String?)?.trim() ?? '');

  String projectName;
  if (providedName.isNotEmpty) {
    projectName = providedName;
  } else {
    // Fall back to reading the `name:` field from the host pubspec.yaml.
    final pubspec = File(path.join('.', 'pubspec.yaml'));
    if (!pubspec.existsSync()) {
      context.logger.err('Could not find pubspec.yaml');
      context.logger.info('Pre generation stopped');
      return;
    }

    final content = pubspec.readAsStringSync();
    final yamlMap = loadYaml(content) as YamlMap?;
    final defaultName = yamlMap?['name'] as String?;
    if (defaultName == null) {
      context.logger.err('Could not find the "name" field in pubspec.yaml');
      context.logger.info('Pre generation stopped');
      return;
    }
    projectName = defaultName;
  }

  // Set the resolved project name in context vars.
  context.vars['project_name'] = projectName;
  context.logger.info('Project name: $projectName');

  // Derive a display title from the project name when not provided.
  final providedTitle = (context.vars['app_title'] as String?)?.trim() ?? '';
  if (providedTitle.isEmpty) {
    final title = projectName
        .replaceAll(RegExp(r'[_\-]+'), ' ')
        .trim()
        .split(RegExp(r'\s+'))
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
    context.vars['app_title'] = title;
  } else {
    context.vars['app_title'] = providedTitle;
  }

  // Normalize the seed color: strip a leading '#' and whitespace.
  final seed = (context.vars['seed_color'] as String?)?.trim() ?? '3F51B5';
  context.vars['seed_color'] =
      seed.startsWith('#') ? seed.substring(1) : seed;

  context.logger.info('App title: ${context.vars['app_title']}');
  context.logger.info('Seed color: ${context.vars['seed_color']}');
  context.logger.info('Pre generation completed');
}
