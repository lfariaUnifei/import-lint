import 'dart:async';
import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer_plugin/plugin/plugin.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as plugin;
import 'package:import_lint/src/infra/error_collector.dart';
import 'package:import_lint/src/infra/factory/rule-container-factory.dart';

import '../src/infra/analysis_options_reader.dart';

// import 'analyzer_plugin_utils.dart';

class ImportLintPlugin extends ServerPlugin {
  ImportLintPlugin({required super.resourceProvider});

  final _errorCollectors = <String, ErrorCollector>{};

  @override
  List<String> get fileGlobsToAnalyze => const ['*.dart'];

  @override
  String get name => 'Import Lint';

  @override
  String get version => '1.0.0-alpha.0';

  @override
  String get contactInfo => 'https://github.com/kawa1214/import-lint';

  AnalysisContextCollection? _contextCollection;

  @override
  Future<void> afterNewContextCollection({
    required AnalysisContextCollection contextCollection,
  }) {
    _contextCollection = contextCollection;

    contextCollection.contexts.forEach(_createConfig);

    return super
        .afterNewContextCollection(contextCollection: contextCollection);
  }

  void _createConfig(AnalysisContext analysisContext) {
    final rootPath = analysisContext.contextRoot.root.path;
    print(rootPath);
    final optionsFilePath = analysisContext.contextRoot.optionsFile?.path;
    if (optionsFilePath == null) {
      throw Exception('Options file path not found');
    }
    print(optionsFilePath);
    final reader = AnalysisOptionsReader(optionsFile: File(optionsFilePath));
    final ruleContainer = RuleContainerFactory(reader);
    _errorCollectors[rootPath] = ErrorCollector(ruleContainer, analysisContext);
  }

  @override
  Future<void> analyzeFile(
      {required AnalysisContext analysisContext, required String path}) async {
    final isAnalyzed = analysisContext.contextRoot.isAnalyzed(path);
    if (!isAnalyzed) {
      return;
    }
    final rootPath = analysisContext.contextRoot.root.path;
    final errorCollector = _errorCollectors[rootPath];

    try {
      final resolvedUnit =
          await analysisContext.currentSession.getResolvedUnit(path);

      if (resolvedUnit is ResolvedUnitResult) {
        final analysisErrors =
            await errorCollector?.collectErrorsFor(resolvedUnit.path) ?? [];

        channel.sendNotification(
          plugin.AnalysisErrorsParams(
            path,
            analysisErrors,
          ).toNotification(),
        );
      } else {
        channel.sendNotification(
          plugin.AnalysisErrorsParams(path, []).toNotification(),
        );
      }
    } on Exception catch (e, stackTrace) {
      channel.sendNotification(
        plugin.PluginErrorParams(false, e.toString(), stackTrace.toString())
            .toNotification(),
      );
    }
  }

  // Future<List<AnalysisError>> _check(
  //   ErrorCollector errorCollector,
  //   AnalysisDriver driver,
  //   ResolvedUnitResult result,
  // ) async {
  //   if (driver.analysisContext?.contextRoot.isAnalyzed(result.path) ?? false) {
  //     final errors = ;
  //     return errors;
  //   }
  //   return [];
  // }
}

// void debuglog(Object value) {
//   final file = io.File('C:\\Users\\luaol\\plugin-report.txt')
//       .openSync(mode: io.FileMode.append);
//   file.writeStringSync('$value\n');
// }
