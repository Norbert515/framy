import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:framy_annotation/framy_annotation.dart';
import 'package:framy_generator/framy_object.dart';
import 'package:framy_generator/json_formatter.dart';
import 'package:source_gen/source_gen.dart';

class ModelResolver extends GeneratorForAnnotation<FramyModel> {
  @override
  String generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) {
    final framyObjectsToReturn = <FramyObject>[];
    final framyObject = _modelObjectFromElement(element);
    if (element is ClassElement) {
      framyObject.constructors = [];
      if (element.isEnum) {
        framyObject.type = FramyObjectType.enumModel;
      } else {
        if (element.isBuiltValue) {
          _generateForBuiltValueModel(element, framyObject);
        } else {
          for (final constructorElement in element.constructors) {
            if (constructorElement.isPrivate) continue;

            var constructorName = constructorElement.name;
            if (constructorName.isNotEmpty) {
              constructorName = '.$constructorName';
            }
            final constructorObject =
                FramyObjectConstructor(constructorName, []);

            for (final param in constructorElement.parameters) {
              constructorObject.dependencies.add(
                FramyObjectDependency(
                  param.name,
                  parseDartType(param.type),
                  param.defaultValueCode,
                  param.isNamed,
                ),
              );
            }

            framyObject.constructors.add(constructorObject);
          }
        }
      }
    }

    framyObjectsToReturn.add(framyObject);

    return framyObjectsToReturn.toJson();
  }

  void _generateForBuiltValueModel(
      ClassElement element, FramyObject framyObject) {
    final constructorObject =
        FramyObjectConstructor('', [], isBuiltValue: true);

    for (final param in element.accessors) {
      constructorObject.dependencies.add(
        FramyObjectDependency(
          param.name,
          parseDartType(param.returnType),
          null,
          false,
        ),
      );
    }
    framyObject.constructors.add(constructorObject);
  }

  String parseDartType(DartType type) {
    final stringType = type.getDisplayString(withNullability: false);
    if (stringType == 'num') {
      return 'double';
    }
    return stringType;
  }

  FramyObject _modelObjectFromElement(Element element) =>
      FramyObject.fromElement(element)..type = FramyObjectType.model;
}

extension on ClassElement {
  bool get isBuiltValue => allSupertypes
      .any((interfaceType) => interfaceType.element.name == 'Built');
}
