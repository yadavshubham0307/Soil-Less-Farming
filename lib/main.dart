import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';


void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'BLE',
        theme: ThemeData(
          primarySwatch: Colors.green,
        ),
        home: MyHomePage(title: 'BLE Devices'),
      );
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;
  final FlutterBlue flutterBlue = FlutterBlue.instance;
  final List<BluetoothDevice> devicesList = new List<BluetoothDevice>();
  final Map<Guid, List<int>> readValues = new Map<Guid, List<int>>();

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _writeController = TextEditingController();
  final String SERVICE_UUID = "208fc8fc-64ed-4423-ba22-2230821ae406";
  final String CHARACTERISTIC_UUID = "e462c4e9-3704-4af8-9a20-446fa2eef1d0";
  BluetoothDevice _connectedDevice;
  List<BluetoothService> _services;
  List<int> strArr=[];
  String display=" ";
  bool mswitch_1=false;
  bool mswitch_2=false;
  List<int> switch_1_on = utf8.encode('S,M,1,0');
  List<int> switch_1_off = utf8.encode('S,M,0,0');
  List<int> switch_2_on = utf8.encode('S,M,0,1');
  List<int> switch_2_off = utf8.encode('S,M,0,0');
  List<int> switch_both_on = utf8.encode('S,M,1,1');
  List<int> switch_both_off = utf8.encode('S,M,0,0');
  _addDeviceTolist(final BluetoothDevice device) {
    if (!widget.devicesList.contains(device)) {
      setState(() {
        widget.devicesList.add(device);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    widget.flutterBlue.connectedDevices
        .asStream()
        .listen((List<BluetoothDevice> devices) {
      for (BluetoothDevice device in devices) {
        _addDeviceTolist(device);
      }
    });
    widget.flutterBlue.scanResults.listen((List<ScanResult> results) {
      for (ScanResult result in results) {
        _addDeviceTolist(result.device);
      }
    });
    widget.flutterBlue.startScan();
  }

  ListView _buildListViewOfDevices() {
    List<Container> containers = new List<Container>();
    for (BluetoothDevice device in widget.devicesList) {
      containers.add(
        Container(
          height: 80,
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  children: <Widget>[
                    Text(device.name ==''?'(unknown device)': device.name,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 23,  color: Colors.black),),
                    Text(device.id.toString(),
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17,  color: Colors.grey),),
                  ],
                ),
              ),
              FlatButton(
                color: Colors.green,
                child: Text(
                  'Connect',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 23, color: Colors.black),
                ),
                onPressed: () async {
                  widget.flutterBlue.stopScan();
                  try {
                    await device.connect();
                  } catch (e) {
                    if (e.code != 'already_connected') {
                      throw e;
                    }
                  } finally {
                    _services = await device.discoverServices();
                  }
                  setState(() {
                    _connectedDevice = device;
                  });
                },
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(8),
      children: <Widget>[
        ...containers,
      ],
    );
  }

  List<ButtonTheme> _buildReadWriteNotifyButton(
      BluetoothCharacteristic characteristic) {
    List<ButtonTheme> buttons = new List<ButtonTheme>();
           print("Characterstics----");
          print(BluetoothCharacteristic);
    print("------------------");
    if (characteristic.properties.read) {

      buttons.add(
        ButtonTheme(
          minWidth: 10,
          height: 35,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: RaisedButton(
              color: Colors.brown,
              child: Text('READ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 23, color: Colors.white)),
              onPressed: () async {

                  print("-----------");
                  int no=2;
                  for(var i = 1; i <= no; i++){
                    var sub = characteristic.value.listen((value)
                    {
                      setState(() {
                        widget.readValues[characteristic.uuid] = value;
                      });
                    });
                    await characteristic.read();

                 }

                  print("Read Data in UTF8--");
                  print(widget.readValues[characteristic.uuid]);
                  print("---------");
                  strArr = widget.readValues[characteristic.uuid];
                  display=utf8.decode(strArr);
                  List<int> bytes = utf8.encode('I');
                  characteristic.write(bytes);
                  print("Write data");
                  print(bytes);
                  print("---------");
                  if(display=="I"){

                    display=" ";
                  }
                  print("Read Data In String--");
                  print(display);
                  print("---------");

               // }
                //print(widget.readValues[characteristic.uuid].toString());
               // print(display);
                //sub.cancel();
              },
            ),
          ),
        ),
      );
    }

    if (characteristic.properties.write) {
      buttons.add(
        ButtonTheme(
          minWidth: 10,
          height: 35,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: RaisedButton(
              color: Colors.brown,
              child: Text('WRITE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 23, color: Colors.white)),
              onPressed: () async {
                await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text("Write"),
                        content: Row(
                          children: <Widget>[
                            Expanded(
                              child: TextField(
                                controller: _writeController,
                              ),
                            ),
                          ],
                        ),
                        actions: <Widget>[
                          FlatButton(
                            child: Text("Send"),
                            onPressed: () {
                              characteristic.write(
                                  utf8.encode(_writeController.value.text));
                              print(_writeController);
                              Navigator.pop(context);
                            },
                          ),
                          FlatButton(
                            child: Text("Cancel"),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      );
                    });
              },
            ),
          ),
        ),
      );
    }
    /*if (characteristic.properties.write) {
      buttons.add(
        ButtonTheme(
          minWidth: 100,
          height: 35,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: RaisedButton(
              child: Text('WRITE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 23, color: Colors.white),),
              onPressed: () async {
                await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text("Write",style: TextStyle(fontWeight: FontWeight.bold, fontSize: 23, color: Colors.black)),
                        content: Row(
                          children: <Widget>[
                            //Expanded(
                              //child: TextField(
                               // controller: _writeController,
                             // ),
                           // ),
                          ],
                        ),
                        actions: <Widget>[
                          FlatButton(
                            child: Text("Send",style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.blue)),
                            onPressed: () {
                              characteristic.write(//utf8.encode(_writeController.value.text)
                               [73] ,);
                              print("write Data!");
                              print(utf8.encode(_writeController.value.text));
                              print("-----------");
                              Navigator.pop(context);
                            },
                          ),
                          FlatButton(
                            child: Text("Cancel",style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black)),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      );
                    });
              },
            ),
          ),
        ),
      );
    }
 */

    /*if (characteristic.properties.notify) {
      buttons.add(
        ButtonTheme(
          minWidth: 10,
          height: 20,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: RaisedButton(
              child: Text('NOTIFY', style: TextStyle(color: Colors.white)),
              onPressed: () async {
                characteristic.value.listen((value) {
                  widget.readValues[characteristic.uuid] = value;
                });
                await characteristic.setNotifyValue(true);
              },
            ),
          ),
        ),
      );
    }*/

    return buttons;
  }




  ListView _buildConnectDeviceView() {
    List<Container> containers = new List<Container>();

    for (BluetoothService service in _services) {
      if(service.uuid.toString() == SERVICE_UUID){
      List<Widget> characteristicsWidget = new List<Widget>();

      for (BluetoothCharacteristic characteristic in service.characteristics) {
        if (characteristic.uuid.toString() == CHARACTERISTIC_UUID) {
          // print("jjk");
          strArr = widget.readValues[characteristic.uuid];
          // print(strArr);
          //  display=utf8.decode(strArr);
          // print(widget.readValues[characteristic.uuid].toString());

          characteristicsWidget.add(
            Align(
              alignment: Alignment.centerLeft,
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Text('Switches Info:     ' //+display
                          ,style: TextStyle(fontWeight: FontWeight.bold, fontSize: 26, color: Colors.brown)),
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      Center(
                        child: Text("       " + display,
                            style: TextStyle(fontWeight: FontWeight.bold,
                              fontSize: 30,
                              color: Colors.green,)),
                      ),
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      ..._buildReadWriteNotifyButton(characteristic),
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      Center(child:Text('               <-Manual->' //+display
                          ,style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30, color: Colors.black)),),

                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      new RaisedButton(
                        child: Text("Both Switch On", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.green)),
                        elevation: 5.0,
                        color: Colors.white,
                        onPressed: () {
                          characteristic.write(switch_both_on);
                          // Do something here
                        },
                      ),

                      new RaisedButton(
                        child: Text("Both Switch Off", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.red)),
                        elevation: 5.0,
                        color: Colors.white,
                        onPressed: () {
                          characteristic.write(switch_both_off);
                          // Do something here
                        },
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      new RaisedButton(
                        child: Text("Switch 1 On",style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.green)),
                        elevation: 5.0,
                        color: Colors.white,
                        onPressed: () {
                          characteristic.write(switch_1_on);
                          // Do something here
                        },
                      ),
                      new RaisedButton(
                        child: Text("Switch 1 Off", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.red)),
                        elevation: 5.0,
                        color: Colors.white,
                        onPressed: () {
                          characteristic.write(switch_1_off);
                          // Do something here
                        },
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      new RaisedButton(
                        child: Text("Switch 2 On", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.green)),
                        elevation: 5.0,
                        color: Colors.white,
                        onPressed: () {
                          characteristic.write(switch_2_on);
                          // Do something here
                        },
                      ),
                      new RaisedButton(
                        child: Text("Switch 2 Off", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.red)),
                        elevation: 5.0,
                        color: Colors.white,
                        onPressed: () {
                          characteristic.write(switch_2_off);
                          // Do something here
                        },
                      ),
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      Center(child:Text("               <-Periodic->"
                          ,style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30, color: Colors.black)),),

                    ],
                  ),
                  Card(
                    child:  Container(

                        )
                      ),
                  /* Row(
                  children: <Widget>[
                    Text('Value: ' //+display
                        ,style: TextStyle(fontWeight: FontWeight.bold, fontSize: 26, color: Colors.grey)),
                      // widget.readValues[characteristic.uuid].toString()),
                  ],
                ),   */
                  Divider(),
                ],
              ),
            ),
          );
        }

       containers.add(
          Container(
            child: ExpansionTile(
                title: Center(child:Text("---------Switch---------",style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30, color: Colors.black)) ,),
                children: characteristicsWidget,
            ),
          ),
        );
      }
    }
    }

    return ListView(
      padding: const EdgeInsets.all(8),
      children: <Widget>[
        ...containers,
      ],
    );
  }




  ListView _buildView() {
    if (_connectedDevice != null) {
      return _buildConnectDeviceView();
    }
    return _buildListViewOfDevices();

  }



  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Center(child:Text("Switch", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30, color: Colors.black)),),
        ),
        body: _buildView(),

      );
}
