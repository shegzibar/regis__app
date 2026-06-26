import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class NameDialog extends StatefulWidget {
  final String title;
  const NameDialog({super.key, required this.title});

  @override
  State<NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<NameDialog> {
  final _c = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _c,
        autofocus: true,
        decoration: InputDecoration(
          labelText: 'owner_cyber_profile.name'.tr(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('common.cancel'.tr()),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _c.text.trim()),
          child: Text('common.save'.tr()),
        ),
      ],
    );
  }
}
