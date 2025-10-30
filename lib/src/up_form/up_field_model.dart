
part of 'up_form.dart';

typedef UpFieldModelCallback<T> = Object? Function(UpFieldModel<T> model);
typedef UpFieldModelValueCallback<T,V> = V? Function(UpFieldModel<T> model);

///
///
///
@immutable
class UpFieldModel<T> extends UpInheritedWidget {
  final UpField<T> _widget;
  
  final UpFieldState<T> field;
  final Object? id;
  
  /// this value is not actual when form is updated, cuz model is still not updated.
  /// use form.value to get actual value
  final T? value;
  final T? initialValue;
  final String? errorText;
  final String? fieldError;
  final String? forceError;
  final UpFieldKey<T> fieldKey;

  String? get label => _widget.label;
  bool get mandatory => _widget.mandatory;
  bool get enabled => _widget.enabled;
  bool get hasChanged => value != initialValue;


  UpFieldModel({
    super.key, 
    required this.field, required this.initialValue, 
    required super.child, 
  }) : 
    id = field.id,
    _widget = field.widget, 
    fieldKey = field.fieldKey,
    value = field.fieldKey.currentState?.value, 
    forceError = field._form._errorState?.forceErrors[field.fieldKey],
    fieldError = field.fieldKey.currentState?.errorText,
    errorText =  field.fieldKey.currentState?.errorText ?? field._form._errorState?.forceErrors[field.fieldKey];
    // savedValue = state.form._savedValues[state.globalKey];
    
  @override
  List<Object?> get equalones => [
    id, value, initialValue, 
    fieldError, forceError, // errorText is not required
    label, mandatory, enabled,  
    fieldKey, child,
  ];

  @override
  bool shouldNotify(covariant UpFieldModel<T> old, {UpInheritedAspect? aspect}) {
    assert(old.id==id && fieldKey==old.fieldKey);
    return super.shouldNotify(old, aspect: aspect);
  }

  @override
  UpFieldModelElement<T> createElement() => UpFieldModelElement<T>(this);
}

///
///
///
class UpFieldModelElement<T> extends UpInheritedElement {

  UpFieldModelElement(UpFieldModel<T> super.widget);

  @override
  UpFieldModel<T> get widget => super.widget as UpFieldModel<T>;
}



///
///
///
@immutable
class UpFieldModelAspect<T> extends UpInheritedAspect<UpFieldModel<T>> {
  const UpFieldModelAspect({super.watch, super.uid});
}


///
///
///
@immutable
class UpFieldValueAspect<T,V> extends UpFieldModelAspect<T> {
  final UpFieldModelValueCallback<T,V>? value; 

  const UpFieldValueAspect({this.value, super.watch, super.uid});

  @override
  Object? call(UpFieldModel<T> widget) => (watch ?? value)?.call(widget);
  V? valueOf(UpFieldModel<T>? model) => model==null ? null : (value!=null ? value!(model) : model.value as V?);
}
