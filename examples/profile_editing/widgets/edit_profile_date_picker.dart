part of '../edit_profile_screen.dart';

class _CustomDatePicker extends StatefulWidget {
  ///Initiates date picker with initial date
  final DateTime? initialDate;

  ///Callback, when value in date picker changes
  final Function(DateTime) onChange;

  ///Placeholder for empty date picker
  final String? hintText;

  const _CustomDatePicker({
    Key? key,
    required this.initialDate,
    required this.onChange,
    this.hintText,
  }) : super(key: key);

  @override
  _CustomDatePickerState createState() => _CustomDatePickerState();
}

class _CustomDatePickerState extends State<_CustomDatePicker> {
  DateTime? _selectedDate;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _getOnTapCallback(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            S.of(context).dateOfBirth,
            style: ProjectTextStyles.ui_14Semi
                .copyWith(color: ColorPalette.lightGray),
          ),
          Container(
            padding: const EdgeInsets.only(bottom: 12, top: 8),
            margin: const EdgeInsets.only(bottom: 12),
            width: double.infinity,
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: ColorPalette.borderLightGray,
                ),
              ),
            ),
            child: Text(
              _selectedDate == null
                  ? widget.hintText ?? 'MM.DD.YYYY'
                  : DateFormat('MMM dd, yyyy').format(_selectedDate!),
              style: ProjectTextStyles.ui_14Regular.copyWith(
                color: ColorPalette.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  VoidCallback _getOnTapCallback() {
    FocusManager.instance.primaryFocus!.unfocus();
    return () =>
    Platform.isIOS ? _presentIOSDatePicker() : _presentAndroidDatePicker();
  }

  void _presentAndroidDatePicker() {
    showDatePicker(
      context: context,
      initialDate: widget.initialDate ??
          DateTime(DateTime.now().year)
              .subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1910),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData(
            primarySwatch: _getPrimarySwatch(),
          ),
          child: child ?? Container(),
        );
      },
    ).then((pickedDate) {
      if (pickedDate == null) return;
      setState(() {
        _selectedDate = pickedDate;
        widget.onChange(_selectedDate!);
      });
    });
  }

  void _presentIOSDatePicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        DateTime? tempPickedDate;
        return SizedBox(
          height: 400,
          child: Column(
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  CupertinoButton(
                    child: Text(S.of(context).cancel),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  CupertinoButton(
                    child: Text(S.of(context).done),
                    onPressed: () {
                      Navigator.of(context).pop(tempPickedDate);
                    },
                  ),
                ],
              ),
              const Divider(
                height: 0,
                thickness: 1,
              ),
              Expanded(
                child: CupertinoDatePicker(
                  initialDateTime: widget.initialDate ??
                      DateTime(DateTime.now().year)
                          .subtract(const Duration(days: 365 * 18)),
                  minimumYear: 1920,
                  maximumDate: DateTime.now().subtract(const Duration(days: 1)),
                  mode: CupertinoDatePickerMode.date,
                  onDateTimeChanged: (DateTime dateTime) {
                    tempPickedDate = dateTime;
                  },
                ),
              ),
            ],
          ),
        );
      },
    ).then((pickedDate) {
      if (pickedDate == null) return;
      setState(() {
        _selectedDate = pickedDate;
        widget.onChange(_selectedDate!);
      });
    });
  }

  MaterialColor _getPrimarySwatch() {
    return MaterialColor(
      ColorPalette.main.value,
      const <int, Color>{
        50: ColorPalette.main,
        100: ColorPalette.main,
        200: ColorPalette.main,
        300: ColorPalette.main,
        400: ColorPalette.main,
        500: ColorPalette.main,
        600: ColorPalette.main,
        700: ColorPalette.main,
        800: ColorPalette.main,
        900: ColorPalette.main,
      },
    );
  }
}