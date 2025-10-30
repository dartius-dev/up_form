part of 'up_form.dart';

typedef UpFieldSubmitter<T> = Future<void> Function(T? value);
typedef UpFormDependency = Object Function(UpFormModel formModel);

///
///
///
extension UpFields on Iterable<UpFieldState> {

  Map<String, Object?> keyedValues({String? Function(UpFieldState)? key}) => {
    for (final field in this) 
      if ((key!=null ? key(field) : field.id) case String name) 
        name: field.value
  };

  UpFieldState<T>? fieldById<T>(Object id) => skipWhile((f) => f.id != id || f is! UpFieldState<T>).firstOrNull as UpFieldState<T>?;

  Iterable<UpFieldState> get named => where((f) => f.name!=null);
  Iterable<UpFieldState> get invalid => where((f) => f.hasError);
  Iterable<UpFieldState> get changed => where((f) => f.hasChanged);
  Iterable<UpFieldState> get empty => where((f) => f.isEmpty);
  Iterable<UpFieldState> get notEmpty => where((f) => f.isNotEmpty);
}


///
///
///
class UpField<T> extends StatefulWidget with EqualoneMixin {
  // final Object? id;
  final String? label;
  final bool enabled;
  final bool mandatory;
  final T? initialValue;
  final List components;
  
  final FormFieldValidator<T>? validator;
  
  /// if not set, the form.submitter([field]) will be used 
  final UpFieldSubmitter<T>? submitter;

  final UpFormDependency? dependency;

  final UpFieldKey<T>? formFieldKey;

  final Widget child;

  @override
  List<Object?> get equalones => [
    key, label, enabled, mandatory, initialValue, validator, submitter, dependency, formFieldKey, Equalone(components), child
  ];

  UpField({
    super.key,
    this.label, this.enabled=true, this.mandatory=false, this.initialValue, this.validator,
    this.submitter,
    this.dependency,
    this.formFieldKey, 
    this.components = const [],
    required this.child
  }) : assert(T != dynamic, "$UpField<T>($key) cannot be used with dynamic type.");


  UpField.named({
    required String name, this.label, this.enabled=true, this.mandatory=false, this.initialValue, this.validator,
    this.submitter,
    this.dependency,
    this.formFieldKey,
    this.components = const [],
    required this.child
  }) : assert(T != dynamic, "$UpField<T>($name) cannot be used with dynamic type."), super(key: ValueKey(name));

  static UpFieldState<T> of<T>(BuildContext context, {UpFieldModelCallback<T>? watch, Object? watchId}) 
      => maybeOf<T>(context, watch: watch, watchId: watchId)!;

  static UpFieldState<T>? maybeOf<T>(BuildContext context, {UpFieldModelCallback<T>? watch, Object? watchId}) {
    assert(T != dynamic, "$UpField<T>($watchId) cannot be used with dynamic type.");
    final aspect = watch!=null ? UpFieldModelAspect<T>(watch: watch, uid: watchId) : null;
    return context.dependOnInheritedWidgetOfExactType<UpFieldModel<T>>(aspect: aspect)?.field;
  }

  static V? valueOf<T,V>(BuildContext context, {
    UpFieldModelValueCallback<T,V>? value, UpFieldModelCallback<T>? watch, Object? watchId
  }) {
    // assert((value!=null && aspect==null) || (aspect!=null && value==null));
    final aspect = UpFieldValueAspect<T,V>(value: value, watch: watch ?? value, uid: watchId);
    return aspect.valueOf(_dependOnUpFieldModel<T>(context, aspect));
  }

  static UpFieldState<T> forFormField<T>(BuildContext context) => of(context, watch: forFormFieldWatch);
  
  static UpFieldState<T>? find<T>(BuildContext context) => context.getInheritedWidgetOfExactType<UpFieldModel<T>>()?.field;

  static Object? forFormFieldWatch<T>(UpFieldModel<T> model) => [model.initialValue, model.forceError, model.enabled];

  static UpFieldModel<T>? _dependOnUpFieldModel<T>(BuildContext context, UpFieldModelAspect<T>? aspect) {
    final model = context.dependOnInheritedWidgetOfExactType<UpFieldModel<T>>(aspect: aspect); 

    assert(model!=null || (){
      context.visitAncestorElements((Element e) {
        if (e.widget case UpFieldModel m) {
          throw FlutterError('${m.runtimeType}(id: ${m.id}) was found, when ${UpFieldModel<T>} is requested');
        }
        return true;
      });
      return true;
    }());

    return model;
  }

  @override
  State<UpField<T>> createState() => UpFieldState<T>();
  
}

///
///
///
class UpFieldState<T> extends State<UpField<T>>  {
  final _notifier = ValueNotifier<UpFieldModel<T>?>(null);
  late UpFormState _form;
  UpFieldModel<T>? _model;
  T? _initialValue;

  UpFormState get form => _form;
  ChangeNotifier get notifier => _notifier;
  late final UpFieldKey<T> fieldKey;
  FormFieldState<T>? get _formField => fieldKey.currentState;

  T? get value => _formField?.value;
  T? get initialValue => _initialValue;
  String? get errorText => fieldError ?? forceError;
  String? get fieldError => _formField?.errorText;
  String? get forceError => _form._errorState?.forceErrors[fieldKey];

  bool get hasChanged => value != _initialValue;
  bool get hasError => errorText != null;

  Object? get id => switch(widget.key) { 
    GlobalObjectKey key => key.value, ValueKey key => key.value, ObjectKey key => key.value, _ => null 
  };
  String? get name => switch(id) { String name => name, _ => null };
  String? get label => widget.label;
  bool get mandatory => widget.mandatory;
  bool get enabled => widget.enabled;
  FormFieldValidator<T> get validator => _validator;
  UpFieldSubmitter<T>? get submitter => widget.submitter;

   
  bool get isNotEmpty => !isEmpty;

  bool get isEmpty => switch(value) {
    final String s => s.isEmpty,
    final Iterable i => i.isEmpty,
    final Map m => m.isEmpty,
    final obj => obj==null
  }; 

  InputDecoration decoration({InputDecoration? decoration}) {
    decoration ??= widget.components.firstWhere((c) => c is InputDecoration, orElse: () => const InputDecoration());
    return decoration!.copyWith(
      labelText: widget.label,
      enabled: widget.enabled,
    );
  }

  FocusNode focusNode([UpFieldComponentCreator<FocusNode, dynamic>? create]) 
      => switch(maybeComponent<FocusNode>()) {
        final node? => node,
        _ => registerComponent<FocusNode>(create!=null ? FocusNodeComponentDelegate(create) : const FocusNodeComponentDelegate())
      };

  C? maybeComponent<C extends Object>() => _fetchComponent<C>()?.$1;

  C getComponent<C extends Object>(UpFieldComponentCreator<C,T> create, {UpFieldComponentDisposer<C>? dispose}) 
      => switch(_fetchComponent<C>()) {
        (final component, ) => component,
        _ => (_components[C] = _UpFieldComponentEntry(this, UpFieldComponentCustomDelegate<C,T>(create, dispose: dispose))).instance as C
      };

  C registerComponent<C extends Object>(UpFieldComponentDelegate<C, T> component) 
      => switch(_fetchComponent<C>()) {
        (final component, ) => component,
        _ => (_components[C] = _UpFieldComponentEntry(this, component)).instance as C
      };

  (C,)? _fetchComponent<C extends Object>() {
    if (widget.components.skipWhile((e) => e is! C).firstOrNull case final component?) return (component,);  
    if (_components[C] case final entry?) return (entry.instance as C,);
    return null;
  }

  final Map<Type, _UpFieldComponentEntry> _components = {};

  bool validate() {
    return _form.validate(fieldKey);
  }

  bool _validate() {
    setState(() {});
    return _formField!.validate();
  }
  
  FutureOr<void> submit() {
    setState((){});
    return _form.submit(fieldKey);
  }

  void reset() {
    _formField?.reset();
    didChange(_initialValue);
  } 

  void didChange(T? value) {
    if (value != _formField!.value) _formField!.didChange(value);
    if (value != _model?.value) setState((){});
  }

  FormField<T> buildFormField({
    required FormFieldBuilder<T> builder,
    FormFieldErrorBuilder? errorBuilder,
    AutovalidateMode? autovalidateMode,
    bool? enabled,
    String?  restorationId,    
  }) {
    return FormField<T>(
      key: fieldKey,
      initialValue: initialValue,
      forceErrorText: forceError,
      validator: validator,
      enabled: this.enabled && enabled!=false,
      errorBuilder: errorBuilder,
      autovalidateMode: autovalidateMode,
      restorationId: restorationId,
      builder: builder,
    );
  }

  @override
  void initState() {
    assert(T!=dynamic, "$UpField<T>($id) cannot be used with dynamic type.");
    super.initState();
    fieldKey = widget.formFieldKey ?? UpFieldKey<T>();
    _initialValue = widget.initialValue;
    UpFieldGroup.maybeOf(context)?._register(this);
    _notifier.addListener(_onModelUpdated);
  }

  @override
  @protected
  void setState([VoidCallback fn = UpForm._noop]) {
    if (!mounted) return;
    super.setState(fn);
  }

  @override
  void dispose() {
    _notifier.dispose();  
    for (var c in _components.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  void activate() {
    UpFieldGroup.maybeOf(context)?._register(this);
    super.activate();
  }

  @override
  void deactivate() {
    UpFieldGroup.maybeOf(context)?._unregister(this);
    UpForm.of(context)._unregister(this);
    super.deactivate();
  }

  @override
  void didUpdateWidget(covariant UpField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_initialValue != widget.initialValue) {
      _initialValue = widget.initialValue;
      if (fieldKey.currentState!=null && fieldKey.currentState!.value != _initialValue) {
        Timer.run(() {
          fieldKey.currentState?.didChange(_initialValue);
        });
      }
    }
    assert(oldWidget.formFieldKey == widget.formFieldKey, "Do not change `formFieldKey`");
  }

  String? _validator(T? value) {
    String? error;
    if (mandatory) {
      error = ContextBasedValidator.required().validate(value, context);
    }
    return error ?? widget.validator?.call(value); 
  }

  Future<void> Function()? get _submitter => widget.submitter == null ? null :()=>widget.submitter!(value);

  void _submitted() {
    if (_initialValue==fieldKey.currentState!.value) return;
    _initialValue = fieldKey.currentState!.value;
    setState((){});
  }
  
  /// used to refresh the field model when FormField is changed or force error is set.
  void _refresh() { 
    // forceError has priority over fieldState.errorText
    if (_model?.value == value && _model?.errorText == errorText && (forceError == null || forceError == fieldError)) return;

    bool shouldResetError = _model?.value != value && _model?.errorText != null && errorText == _model?.errorText;
    if (shouldResetError) {
      if (_formField?.errorText != null) {
        if (maybeComponent<TextEditingController>() case final textController?) {
          final textEditingValue = textController.value;
          _formField?.reset(); // to reset errorText
          textController.value = textEditingValue;
        } else {
          _formField?.reset(); // to reset errorText
          _formField?.didChange(value);
        }
      }
      if (forceError != null) {
        // to reset forceError
        _form._errorState?.forceErrors.remove(fieldKey);
      }
    }

    setState((){});
  }

  @override
  Widget build(BuildContext context) {
    _form = UpForm.of(context, watch: _formDependency); 
    _form._register(this);
    _model = UpFieldModel<T>(field: this, initialValue: _initialValue, child: widget.child);

    Timer.run(() => _notifier.value = _model); // notify listeners after the build is done

    return _model!;
  }

  void _onModelUpdated() {
    if (!mounted) return;
    _form._onFieldModelUpdated();
  }

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    final props = [if(id!=null) '$id', if(label!=null) '"$label"'];
    return props.isEmpty 
      ? super.toString(minLevel: minLevel)
      : "${props.join(' ')} ${super.toString(minLevel: minLevel)}";
  }

  List _formDependency(UpFormModel model) => [
    model.widget, model._errorState?.forceErrors[fieldKey], Equalone(widget.dependency?.call(model))
  ];
}

///
///
///
class UpFieldKey<T> extends GlobalKey<FormFieldState<T>> {
  factory UpFieldKey() {
    assert(T!=dynamic, "${UpFieldKey<T>()} cannot be used with dynamic type.");
    return UpFieldKey<T>.constructor();
  }
  const UpFieldKey.constructor() : super.constructor();
  
  UpFieldState<T> upField() {
    final model = UpForm.of(currentContext!).fieldByKey<T>(this)!;
    return model;
  }
  @override
  String toString() {

    return kDebugMode 
      ? super.toString().replaceFirst(' ', "[id:${currentContext?.findAncestorStateOfType<UpFormState>()?.fieldByKey(this)?.id}] ")
      : super.toString();
  }
}



// Legacy Handy* component entries removed — components use Up-prefixed entries now.

