import 'package:equalone/equalone.dart';
import 'package:flutter/widgets.dart';



typedef UpWatchCallback<T extends InheritedWidget> = Object? Function(T widget);

///
///
///
@immutable
abstract class UpInheritedWidget extends InheritedWidget with EqualoneMixin {
  const UpInheritedWidget({super.key, required super.child});

  @override
  bool updateShouldNotify(UpInheritedWidget old) => shouldNotify(old);

  bool shouldNotify(UpInheritedWidget old, {UpInheritedAspect? aspect}) {
    return aspect==null
      ? this!=old
      : !Equalone.equals(aspect(old), aspect(this));
  }

  @override
  UpInheritedElement createElement();
}

///
///
///
class UpInheritedElement<W extends UpInheritedWidget> extends InheritedElement {

  UpInheritedElement(W super.widget);

  @override
  W get widget => super.widget as W;

  @override
  void updateDependencies(Element dependent, covariant UpInheritedAspect? aspect) {
    final dependencies = getDependencies(dependent) as Set<UpInheritedAspect>?;
    if (/*dependencies?.contains(aspect)==true ||*/ dependencies?.isEmpty==true) {
      return;
    }

    if (aspect == null) {
      setDependencies(dependent, const <UpInheritedAspect>{});
    } else {
      setDependencies(dependent, (dependencies ?? <UpInheritedAspect>{})..remove(aspect)..add(aspect));
    }
  }

  @override
  void notifyDependent(covariant W oldWidget, Element dependent) {
    final dependencies = getDependencies(dependent) as Set<UpInheritedAspect>?;
    if (dependencies == null) {
      return;
    }
    if (dependencies.isEmpty || dependencies.any((aspect)=>widget.shouldNotify(oldWidget, aspect: aspect))) {
      dependent.didChangeDependencies();
    }
  }
}

///
///
///
@immutable
class UpInheritedAspect<T extends InheritedWidget> {
  final Object? uid;
  final UpWatchCallback<T>? watch; 

  const UpInheritedAspect({this.watch, this.uid});

  Object? call(T widget) => watch?.call(widget);
  
  @override
  bool operator ==(Object other) => other is UpInheritedAspect<T> && runtimeType==other.runtimeType && uid==other.uid;
  
  @override
  int get hashCode => runtimeType.hashCode^uid.hashCode;
  
}

