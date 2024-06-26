// Copyright 2019 Aleksander Woźniak
// SPDX-License-Identifier: Apache-2.0

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class CustomIconButton extends StatelessWidget {
  final Widget icon;
  final VoidCallback onTap;
  final EdgeInsets margin;
  final EdgeInsets padding;

  const CustomIconButton({
    Key? key,
    required this.icon,
    required this.onTap,
    this.margin = const EdgeInsets.only(top: 14.0, left: 10, right: 10),
    this.padding = const EdgeInsets.all(0.0),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;

    return Padding(
      padding: margin,
      child: !kIsWeb &&
              (platform == TargetPlatform.iOS ||
                  platform == TargetPlatform.macOS)
          ? CupertinoButton(
              onPressed: onTap,
              padding: padding,
              child: icon,
            )
          : Material(
              color: Colors.transparent,
              child: InkWell(
                hoverColor: Color.fromARGB(255, 245, 245, 247),
                onTap: onTap,
                borderRadius: BorderRadius.circular(100.0),
                child: Padding(
                  padding: padding,
                  child: icon,
                ),
              ),
            ),
    );
  }
}
