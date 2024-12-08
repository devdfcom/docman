import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show FilteringTextInputFormatter, TextInputFormatter;

class MethodParamInput extends StatelessWidget {
  const MethodParamInput({
    required this.fieldName,
    required this.initialValue,
    required this.onSaved,
    this.textOnly = false,
    this.numbersOnly = false,
    this.keyboardType,
    this.textInputAction = TextInputAction.done,
    this.validator,
    super.key,
  });

  final Function(String?) onSaved;

  /// Field validator. If null, no validation is performed.
  final String? Function(String?)? validator;

  ///Field name is used as [labelText] && used in validation to show error
  final String fieldName;

  ///Initial field value.
  final String initialValue;

  ///Useful to show specific keyboard type on phone,
  final TextInputType? keyboardType;

  /// Use [TextInputAction] to set the action button on the keyboard.
  final TextInputAction textInputAction;

  ///If true, sets [TextInputFormatter] for letters only & space [a-zA-Zа-яА-Я ]. By default is false
  final bool textOnly;

  final bool numbersOnly;

  TextInputFormatter? get _textOnly => textOnly
      ? FilteringTextInputFormatter.allow(RegExp("[a-zA-Zа-яА-Я ]"))
      : null;

  TextInputFormatter? get _numbersOnly =>
      numbersOnly ? FilteringTextInputFormatter.digitsOnly : null;

  ///Collecting all TextInputFormatters in list even with null & filter those.
  List<TextInputFormatter> get _inputFormatters => [
        _textOnly,
        _numbersOnly,
      ].nonNulls.toList();

  @override
  Widget build(BuildContext context) {
    final textController = TextEditingController(text: initialValue);

    return TextFormField(
      onFieldSubmitted: onSaved,
      controller: textController,
      // The validator receives the text that the user has entered.
      validator: validator,
      autovalidateMode:
          validator != null ? AutovalidateMode.onUserInteraction : null,
      onTapOutside: (event) {
        if (validator != null) {
          if (validator!(textController.text) == null)
            onSaved(textController.text);
        } else {
          onSaved(textController.text);
        }

        FocusManager.instance.primaryFocus?.unfocus();
      },
      onEditingComplete: null,
      textInputAction: textInputAction,
      textCapitalization: TextCapitalization.none,
      keyboardType: numbersOnly ? TextInputType.number : keyboardType,
      keyboardAppearance: Brightness.dark,
      inputFormatters: _inputFormatters.isNotEmpty ? _inputFormatters : null,
      style: Theme.of(context).textTheme.bodyMedium,
      decoration: InputDecoration(
        //contentPadding: EdgeInsets.only(bottom: 10),
        isDense: true,
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        border: const OutlineInputBorder(),
        labelText: fieldName,
        labelStyle: Theme.of(context).textTheme.titleMedium,
        floatingLabelStyle: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}
