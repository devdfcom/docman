// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ModalTextField extends StatefulWidget {
  const ModalTextField({
    required this.selected,
    required this.onSelect,
    this.leftIcon,
    this.suffixText,
    this.textOnly = false,
    this.numbersOnly = false,
    this.canBeEmpty = false,
    this.maxLength,
    this.keyboardType,
    this.customFilter,
    TextCapitalization? textCapitalization,
    super.key,
  }) : textCapitalization = textCapitalization ?? TextCapitalization.none;

  final String selected;
  final Function(String) onSelect;
  final bool canBeEmpty;
  final IconData? leftIcon;
  final String? suffixText;

  ///If true, sets [TextInputFormatter] for letters only & space [a-zA-Zа-яА-Я ]. By default is false
  final bool textOnly;
  final bool numbersOnly;
  final int? maxLength;

  ///Useful to show specific keyboard type on phone,
  final TextInputType? keyboardType;
  final FilteringTextInputFormatter? customFilter;
  final TextCapitalization textCapitalization;

  @override
  State<ModalTextField> createState() => _ModalTextFieldState();
}

class _ModalTextFieldState extends State<ModalTextField> {
  late TextEditingController controller;

  @override
  void initState() {
    //1. Initialize controller
    controller = TextEditingController(text: widget.selected);
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  bool get _isValid =>
      widget.canBeEmpty ? true : controller.value.text.isNotEmpty;

  TextInputFormatter? get _textOnly => widget.textOnly
      ? FilteringTextInputFormatter.allow(RegExp("[a-zA-Zа-яА-Я .]"))
      : null;

  TextInputFormatter? get _numbersOnly =>
      widget.numbersOnly ? FilteringTextInputFormatter.digitsOnly : null;

  TextInputFormatter? get _maxLength => widget.maxLength != null
      ? LengthLimitingTextInputFormatter(widget.maxLength)
      : null;

  ///Collecting all TextInputFormatters in list even with null & filter those.
  List<TextInputFormatter> get _inputFormatters => [
        //Check if we got text only
        _textOnly,
        _numbersOnly,
        _maxLength,
        widget.customFilter,
      ].nonNulls.toList();

  Widget _leftIcon(BuildContext context) => widget.leftIcon != null
      ? Icon(
          widget.leftIcon,
          size: 32,
          color: _isValid
              ? Theme.of(context).colorScheme.secondary
              : Theme.of(context).colorScheme.error,
        )
      : SizedBox(width: 5);

  Widget _suffixIcon(BuildContext context) => Padding(
        padding: EdgeInsets.only(left: 4),
        child: IconButton(
          onPressed: _isValid ? _submit : null,
          style: IconButton.styleFrom(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0)),
          ),
          icon: Icon(
            _isValid ? Icons.done_all_outlined : Icons.close,
            color: _isValid
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.error,
            size: 32,
          ),
        ),
      );

  void _submit() => widget.onSelect(controller.value.text);

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.all(5).copyWith(bottom: 10),
        child: TextField(
          autofocus: true,
          controller: controller,
          onChanged: (val) => setState(() {}),
          onSubmitted: _isValid ? (value) => _submit() : null,

          inputFormatters: _inputFormatters,
          keyboardType: widget.keyboardType ??
              (widget.numbersOnly ? TextInputType.number : null),
          keyboardAppearance: Brightness.dark,
          textInputAction: TextInputAction.done,
          textCapitalization: widget.textCapitalization,
          style: Theme.of(context).textTheme.headlineSmall,
          //textAlign: TextAlign.right,
          decoration: InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 8.0),
            icon: _leftIcon(context),
            errorText: _isValid ? null : '',
            errorStyle: const TextStyle(height: 0),
            hintText: _isValid ? null : 'Enter text',
            hintStyle: Theme.of(context).textTheme.titleSmall,
            suffixText: widget.suffixText,
            suffixStyle: Theme.of(context).textTheme.headlineSmall,
            suffixIcon: _suffixIcon(context),
          ),
        ),
      );
}
