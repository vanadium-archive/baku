// Copyright 2016 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

final Random random = new Random();

void main() {
  runApp(new BakuDistro());
}

class BakuDistro extends StatefulWidget {
  @override
  _BakuDistroState createState() => new _BakuDistroState();
}

class _Device {
  String name, description;

  _Device(this.name, this.description);
}

class _BakuDistroState extends State<BakuDistro> {
  final Map<String, String> devices = {};
  InputValue data = InputValue.empty;

  _BakuDistroState() {
    HostMessages.addMessageHandler('deviceOnline', _onDeviceOnline);
    HostMessages.addMessageHandler('deviceOffline', _onDeviceOffline);
  }

  void castTo(final String name) {

  }

  @override
  Widget build(final BuildContext context) {
    final List<_Device> sortedDevices = devices.keys.map((name) =>
        new _Device(name, devices[name])).toList(growable: false);
    sortedDevices.sort((a, b) => a.description.compareTo(b.description));

    return new Scaffold(
      appBar: new AppBar(
        title: new Text('Baku Distro Example')
      ),
      body: new Column(
        children: <Widget>[
          new Padding(
            padding: new EdgeInsets.all(8.0),
            child: data.text.isEmpty?
              new Text('No content', style:
                new TextStyle(color: Theme.of(context).disabledColor)) :
              new Text(data.text)
          ),
          new Input(
            value: data,
            labelText: 'Text content',
            onChanged: (value) => setState(() => data = value)
          ),
          new MaterialList(
            type: MaterialListType.oneLine,
            children: sortedDevices.map((d) => new ListItem(
              title: new Text(d.description),
              onTap: () => castTo(d.name)
            ))
          )
        ]
      )
    );
  }

  Future<String> _onDeviceOnline(final String json) async {
    final Map<String, dynamic> message = JSON.decode(json);
    setState(() {
      devices[message['name']] = message['description'];
    });

    return null;
  }

  Future<String> _onDeviceOffline(final String name) async {
    setState(() {
      devices.remove(name);
    });
    return null;
  }
}
