import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:import_lint/src/domain/import.dart';
import 'package:import_lint/src/domain/rule_container.dart';

import '../utils.dart';

class ImportLintVisitor extends SimpleAstVisitor<void> {
  ImportLintVisitor(
    this.ruleContainer,
    this.filePath,
    this.packageName,
    this.unit,
    this.onError,
  );

  final RuleContainer ruleContainer;
  final String filePath;
  final String packageName;
  final CompilationUnit unit;
  final Function(AnalysisError) onError;

  @override
  void visitImportDirective(ImportDirective node) {
    final importSource = _createImportSource(node);

    if (importSource == null) {
      return;
    }
    if (!ruleContainer.isAnyRuleViolatedBy(importSource)) {
      return;
    }
    _reportError(node);
  }

  Import? _createImportSource(ImportDirective node) {
    final element = node.element2!;
    final uri = element.uri as DirectiveUriWithSource;
    final encodedSelectedSourceUri = uri.source.uri.toString();

    return Import.create(
      uriUsedToImport: uri.relativeUriString,
      fullImportPath: Uri.decodeFull(encodedSelectedSourceUri),
      sourceFilePath: toPackagePath(filePath),
    );
  }

  void _reportError(ImportDirective node) {
    final lineInfo = unit.lineInfo;
    final loc = lineInfo.getLocation(node.uri.offset);
    final locEnd = lineInfo.getLocation(node.uri.end);

    final error = AnalysisError(
      AnalysisErrorSeverity('WARNING'),
      AnalysisErrorType.LINT,
      Location(
        filePath,
        node.offset,
        node.length,
        loc.lineNumber,
        loc.columnNumber,
        endLine: locEnd.lineNumber,
        endColumn: locEnd.columnNumber,
      ),
      'Found Import Lint Error: ${ruleContainer.name}',
      'import_lint',
      correction: 'Try removing the import.',
      hasFix: false,
    );

    onError(error);
  }
}
