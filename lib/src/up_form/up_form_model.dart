part of 'up_form.dart';

typedef UpFormModelCallback = Object? Function(UpFormModel model);
typedef UpFormModelValueCallback<V> = V? Function(UpFormModel model);

///
///
///
class UpFormModel extends UpInheritedWidget {
  const UpFormModel._(this._state, {
    required this.widget,
    required this.fields,
    required this.canSubmit,
    required _UpFormErrorState? errorState, 
    required super.child
  }) : _errorState = errorState;

  final UpForm widget;
  final List<UpFieldModel> fields;
  final bool canSubmit;

  bool get hasError => _errorState != null;

  UpFormState state() => _state;

  // String? forceErrorOf(UpFormFieldKey fieldKey) => _errorState?.forceErrors[fieldKey];

  UpFieldModel<T>? fieldById<T>(Object id) {
    return fields.skipWhile((m) => m.id == id).firstOrNull as UpFieldModel<T>?;
  }

  List<UpFieldModel> fieldsById(List<Object> ids) {
    return fields.where((m) => ids.contains(m.id)).toList();
  }

  V? valueByFieldId<V>(Object id, {UpFieldModelCallback? value}) {
    return switch(fields.skipWhile((m) => m.id != id).firstOrNull) {
      UpFieldModel m => value!=null ? value(m) : m.value,
      null => null,
    };
  }
  List<Object?> valuesByFieldId(List<Object> ids, {UpFieldModelCallback? value}) {
    return fields.where((m) => ids.contains(m.id)).map((m) => value!=null ? value(m) : m.value).toList();
  }


  final _UpFormErrorState? _errorState;
  final UpFormState _state;

  @override
  List<Object?> get equalones => [widget, _errorState, Equalone(fields), canSubmit];

  @override
  UpInheritedElement createElement() => UpInheritedElement<UpFormModel>(this);
}

///
///
///
@immutable
class UpFormModelAspect extends UpInheritedAspect<UpFormModel> {
  const UpFormModelAspect({super.watch, super.uid});
}

///
///
///
@immutable
class UpFormValueAspect<V> extends UpFormModelAspect {
  final UpFormModelValueCallback<V> value; 

  const UpFormValueAspect({required this.value, super.watch, super.uid});

  @override
  Object? call(UpFormModel widget) => (watch ?? value).call(widget);
  V? valueOf(UpFormModel? model) => model==null ? null : value(model);
}
