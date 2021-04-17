import 'dart:convert';
import 'package:numberpicker/numberpicker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'toggle_bar.dart';


void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Switch',
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

  TimeOfDay _time_s1_f = TimeOfDay(hour: 00, minute: 00);
  TimeOfDay _time_s1_t = TimeOfDay(hour: 00, minute: 00);
  TimeOfDay _time_s2_f = TimeOfDay(hour: 00, minute: 00);
  TimeOfDay _time_s2_t = TimeOfDay(hour: 00, minute: 00);
  //void _selectTime()

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


  List<int> initial_period=utf8.encode('S,P');
  List<int> dilima =utf8.encode(',');
  var p_switch_1_h_on;
  var p_switch_1_h_off;
  var p_switch_2_h_on;
  var p_switch_2_h_off;
  var p_switch_1_m_on;
  var p_switch_1_m_off;
  var p_switch_2_m_on;
  var p_switch_2_m_off;
  var switch_period = utf8.encode('');
  String p_s_1_h_on="00";
  String p_s_1_h_off="00";
  String p_s_2_h_on="00";
  String p_s_2_h_off="00";
  String p_s_1_m_on="00";
  String p_s_1_m_off="00";
  String p_s_2_m_on="00";
  String p_s_2_m_off="00";

  var switch_rtc_set;
  List<int> initial_timertcframe=utf8.encode('C');
  var switch_timertcframe = utf8.encode('');


  List<int> initial_timeframe=utf8.encode('S,T');

  var t_switch_1_h_from;
  var t_switch_1_h_to;
  var t_switch_2_h_from;
  var t_switch_2_h_to;
  var t_switch_1_m_from;
  var t_switch_1_m_to;
  var t_switch_2_m_from;
  var t_switch_2_m_to;
  var switch_timeframe = utf8.encode('');
  String t_s_1_h_from="00";
  String t_s_1_h_to="00";
  String t_s_2_h_from="00";
  String t_s_2_h_to="00";
  String t_s_1_m_from="00";
  String t_s_1_m_to="00";
  String t_s_2_m_from="00";
  String t_s_2_m_to="00";
  var time=" ";




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



    return buttons;
  }



_show( BluetoothCharacteristic characteristic){

  if (characteristic.properties.read){
    print("-----------");

      var sub = characteristic.value.listen((value)
      {
        setState(() {
          widget.readValues[characteristic.uuid] = value;
        });
      });
      characteristic.read();


    print("Read Data in UTF8--");
    print(widget.readValues[characteristic.uuid]);
    print("---------");
    strArr = widget.readValues[characteristic.uuid];
    display=utf8.decode(strArr);

    if(display=="I"){

      display=" ";
    }
    print("Read Data In String--");
    print(display);
    print("---------");

  }

}



List _time_split(var _time_show){


  String _split=_time_show;//07:50 AM
  var time_split2=_split.split(' ');//[7:50, AM]
  var time_split3=time_split2[0].split(':');//[7, 50]
  String hrs;
  var time;

  var c = int. parse(time_split3[0]);
  if(time_split2[1]=='PM' && time_split3[0]!="12"){
    c=c+12;
    hrs=c.toString();
  }


  if(time_split2[1]=='AM'){
    if(c==12){
      hrs="0";
      hrs="0"+c.toString();
    }

    if(time_split3[0].length==1){
      hrs="0"+c.toString();
    }

  }
  //print(time);



    /*
  String _split=_time_show;
  var time_split2=_split.split(' ');
  var time_split3=time_split2[0].split(':');
  var hrs;
  var time;
  hrs=time_split3[0];
  var c = int. parse(hrs);
  if(time_split2[1]=='PM' && time_split3[0]!="12"){
    c=c+12;
  }
  */
  //time=c.toString()+","+time_split3[1];
  //print(c);
  //print(time_split3[1]);
   time=utf8.encode(hrs+time_split3[1]);


  return time;
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
                        child: Text(display,
                            style: TextStyle(fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Colors.green,)),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      ..._buildReadWriteNotifyButton(characteristic),
                    ],
                  ),
                  Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                  new RaisedButton(
                  child: Text("Switch Reset", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white)),
            elevation: 5.0,
            color: Colors.brown,

            onPressed: () {
                    List<int> switch_reset=utf8.encode("R");
              characteristic.write(switch_reset);
              // Do something here
            },
          ),

                      new RaisedButton(
                        child: Text(" Factory Reset ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white)),
                        elevation: 5.0,
                        color: Colors.brown,
                        onPressed: () {
                          List<int> switch_Factoryreset=utf8.encode("F");
                          characteristic.write(switch_Factoryreset);
                          // Do something here
                        },
                      ),

                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      new RaisedButton(
                        child: Text("Switch Time ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white)),
                        elevation: 5.0,
                        color: Colors.brown,

                        onPressed: () {
                          List<int> switch_T=utf8.encode('T');
                          characteristic.write(switch_T);
/*
                          String time_split=_time.format(context);
                          var time_split2=time_split.split(' ');
                          var time_split3=time_split2[0].split(':');
                          var hrs;
                          print("Time--------");
                          hrs=time_split3[0];
                          var c = int. parse(hrs);
                          if(time_split2[1]=='PM' && time_split3[0]!="12"){
                            c=c+12;
                          }
                          print(c);
                          print(time_split3[1]);
                          print("-------");

*/
                          // Do something here
                        },
                      ),

                      new RaisedButton(
                        child: Text("Switch Resume", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white)),
                        elevation: 5.0,
                        //shape: new RoundedRectangleBorder(borderRadius: new BorderRadius.circular(30.0)),
                        color: Colors.brown,
                        onPressed: () {

                          List<int> switch_Resume=utf8.encode("B");
                          characteristic.write(switch_Resume);
                          // Do something here
                        },
                      ),

                    ],
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      new RaisedButton(
                        child: Text("Auto Mode On ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white)),
                        elevation: 5.0,
                        color: Colors.brown,

                        onPressed: () {
                          List<int> switch_A_1=utf8.encode('A,1');
                          characteristic.write(switch_A_1);

                          // Do something here
                        },
                      ),

                      new RaisedButton(
                        child: Text("Auto Mode Off", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white)),
                        elevation: 5.0,
                        //shape: new RoundedRectangleBorder(borderRadius: new BorderRadius.circular(30.0)),
                        color: Colors.brown,
                        onPressed: () {

                          List<int> switch_A_0=utf8.encode("A,0");
                          characteristic.write(switch_A_0);
                          // Do something here
                        },
                      ),

                    ],
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      new RaisedButton(
                        child: Text("Pause ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white)),
                        elevation: 5.0,
                        color: Colors.brown,

                        onPressed: () {
                          List<int> switch_P=utf8.encode('P');
                          characteristic.write(switch_P);

                          // Do something here
                        },
                      ),


                    ],
                  ),


                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      RaisedButton(
                        color: Colors.brown,
                        child: Text("Set Time", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 23, color: Colors.white)),
                        onPressed: () async {
                          await showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Text("Write", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25, color: Colors.black)),
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
                                      child: Text("Set"),
                                      onPressed: () {
                                        switch_rtc_set=utf8.encode(_writeController.value.text);

                                        print("switch_rtc_set----");
                                        print(_writeController.value.text);
                                        print("----------");
                                        switch_timertcframe=initial_timertcframe+dilima+switch_rtc_set;
                                        characteristic.write(switch_timertcframe);
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
                    ],
                  ),



                  Divider(),
                  Row(
                    children: <Widget>[
                      Center(child:Text('               <-Manual->' //+display
                          ,style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30, color: Colors.black)),),

                    ],
                  ),
                  Divider(),
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
                  Divider(),
                 /* Card(
                    child:  Container(
                        width: 80,
                        child: TextField(
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Hours',
                            hintText: 'Hrs:',
                          ),
                          autofocus: false,
                        )
                        )
                      ),*/
                  Row(
                    children: <Widget>[
                      Center(child:Text("                 Switch 1"
                          ,style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30, color: Colors.green)),),

                    ],
                  ),
                  Row(
                    children: <Widget>[
                      Center(child:Text("                    Hrs.    :     Min."
                          ,style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25, color: Colors.brown)),),

                    ],
                  ),
                  Row(
                   // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      Text("On Time   ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 23, color: Colors.black)),
                       RaisedButton(
                        color: Colors.white,
                        child: Text(p_s_1_h_on, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 23, color: Colors.black)),
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
                                         p_switch_1_h_on=utf8.encode(_writeController.value.text);
                                         p_s_1_h_on=_writeController.value.text;
                                         print("p_switch_1_h_on----");
                                        print(_writeController.value.text);
                                        print("----------");
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
                      Text(" : ",style: TextStyle(fontWeight: FontWeight.bold, fontSize: 23, color: Colors.black)),
                      RaisedButton(
                        color: Colors.white,
                        child: Text(p_s_1_m_on, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 23, color: Colors.black)),
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
                                        p_switch_1_m_on=utf8.encode(_writeController.value.text);
                                        p_s_1_m_on=_writeController.value.text;
                                        print("p_switch_1_m_on----");
                                        print(_writeController.value.text);
                                        print("----------");
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
                    ],
                  ),
                  Row(
                    // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      Text("Off Time   ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 23, color: Colors.black)),
                      RaisedButton(
                        color: Colors.white,
                        child: Text(p_s_1_h_off, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 23, color: Colors.black)),
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
                                        p_switch_1_h_off=utf8.encode(_writeController.value.text);
                                        p_s_1_h_off=_writeController.value.text;
                                        print("p_switch_1_h_off----");
                                        print(_writeController.value.text);
                                        print("----------");
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
                      Text(" : ",style: TextStyle(fontWeight: FontWeight.bold, fontSize: 23, color: Colors.black)),
                      RaisedButton(
                        color: Colors.white,
                        child: Text(p_s_1_m_off, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 23, color: Colors.black)),
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
                                        p_switch_1_m_off=utf8.encode(_writeController.value.text);
                                        p_s_1_m_off=_writeController.value.text;
                                        print("p_switch_1_m_off----");
                                        print(_writeController.value.text);
                                        print("----------");
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
                    ],
                  ),
                  Divider(),
                  Row(
                    children: <Widget>[
                      Center(child:Text("                 Switch 2"
                          ,style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30, color: Colors.green)),),

                    ],
                  ),
                  Row(
                    children: <Widget>[
                      Center(child:Text("                    Hrs.    :     Min."
                          ,style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25, color: Colors.brown)),),

                    ],
                  ),
                  Row(
                    // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      Text("On Time   ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 23, color: Colors.black)),
                      RaisedButton(
                        color: Colors.white,
                        child: Text(p_s_2_h_on, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 23, color: Colors.black)),
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
                                        p_switch_2_h_on=utf8.encode(_writeController.value.text);
                                        p_s_2_h_on=_writeController.value.text;
                                        print("p_switch_2_h_on----");
                                        print(_writeController.value.text);
                                        print("----------");
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
                      Text(" : ",style: TextStyle(fontWeight: FontWeight.bold, fontSize: 23, color: Colors.black)),
                      RaisedButton(
                        color: Colors.white,
                        child: Text(p_s_2_m_on, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 23, color: Colors.black)),
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
                                        p_switch_2_m_on=utf8.encode(_writeController.value.text);
                                        p_s_2_m_on=_writeController.value.text;
                                        print("p_switch_2_m_on----");
                                        print(p_switch_2_m_on);
                                        print("----------");
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
                    ],
                  ),
                  Row(
                    // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      Text("Off Time   ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 23, color: Colors.black)),
                      RaisedButton(
                        color: Colors.white,
                        child: Text(p_s_2_h_off, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 23, color: Colors.black)),
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
                                        p_switch_2_h_off=utf8.encode(_writeController.value.text);
                                        p_s_2_h_off=_writeController.value.text;
                                        print("p_switch_2_h_off----");
                                        print(_writeController.value.text);
                                        print("----------");
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
                      Text(" : ",style: TextStyle(fontWeight: FontWeight.bold, fontSize: 23, color: Colors.black)),
                      RaisedButton(
                        color: Colors.white,
                        child: Text(p_s_2_m_off, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 23, color: Colors.black)),
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
                                        p_switch_2_m_off=utf8.encode(_writeController.value.text);
                                        p_s_2_m_off=_writeController.value.text;
                                        print("p_switch_2_m_off----");
                                        print(_writeController.value.text);
                                        print("----------");
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
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      new RaisedButton(
                        child: Text("Period Set", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white)),
                        elevation: 5.0,
                        color: Colors.brown,
                        onPressed: () {

                          switch_period=initial_period+dilima+p_switch_1_h_on+p_switch_1_m_on+p_switch_2_h_off+p_switch_1_m_off+dilima+p_switch_2_h_on+p_switch_2_m_on+p_switch_2_h_off+p_switch_2_m_off;
                          characteristic.write(switch_period);

                          print("switch Period___");
                          print(switch_period);
                          print("------------------");
                          // Do something here
                        },
                      ),

                    ],
                  ),

                  Divider(),

                  Row(
                    children: <Widget>[
                      Center(child:Text("           <-Time Frame->"
                          ,style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30, color: Colors.black)),),

                    ],
                  ),
                  Divider(),

                  Row(
                    children: <Widget>[
                      Center(child:Text("                 Switch 1"
                          ,style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30, color: Colors.green.shade900)),),

                    ],
                  ),

                  /*
                  Row(
                    children: <Widget>[
                      Center(child:Text("                    Hrs.    :     Min."
                          ,style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25, color: Colors.brown)),),

                    ],
                  ),

                  */

                  Row(

                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(

                        onPressed: () async {
                          final TimeOfDay newTime = await showTimePicker(
                            context: context,
                            initialTime: _time_s1_f,
                          );
                          if (newTime != null) {
                            setState(() {
                              _time_s1_f = newTime;
                            });
                          }
                          //String time_split=_time.format(context);
                          //_time_split(_time_s1_f.format(context));

                        },
                        child: Text('From',style: TextStyle(fontWeight: FontWeight.bold, fontSize: 23, color: Colors.white)),
                      ),
                      SizedBox(height: 8),
                      //${_time.format(context)}
                      Text('     Selected time: ${_time_s1_f.format(context)}',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black)),

                    ],
                  ),
                  Row(

                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          final TimeOfDay newTime = await showTimePicker(
                            context: context,
                            initialTime: _time_s1_t,
                          );
                          if (newTime != null) {
                            setState(() {
                              _time_s1_t = newTime;
                            });
                          }

                         // _time_split(_time_s1_t.format(context));
                        },
                        child: Text('   To  ',style: TextStyle(fontWeight: FontWeight.bold, fontSize: 23, color: Colors.white)),
                      ),
                      SizedBox(height: 8),
                      Text(
                          '    Selected time: ${_time_s1_t.format(context)}',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black)),

                    ],
                  ),


                  /*
                  Row(
                    // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      Text("From         ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 23, color: Colors.black)),
                      RaisedButton(
                        color: Colors.white,
                        child: Text(t_s_1_h_from, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 23, color: Colors.black)),
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
                                        t_switch_1_h_from=utf8.encode(_writeController.value.text);
                                        t_s_1_h_from=_writeController.value.text;
                                        print("t_switch_1_h_from----");
                                        print(_writeController.value.text);
                                        print("----------");
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
                      Text(" : ",style: TextStyle(fontWeight: FontWeight.bold, fontSize: 23, color: Colors.black)),
                      RaisedButton(
                        color: Colors.white,
                        child: Text(t_s_1_m_from, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 23, color: Colors.black)),
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
                                        t_switch_1_m_from=utf8.encode(_writeController.value.text);
                                        t_s_1_m_from=_writeController.value.text;
                                        print("t_switch_1_m_from----");
                                        print(_writeController.value.text);
                                        print("----------");
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
                    ],
                  ),
                  Row(
                    // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      Text("To              ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 23, color: Colors.black)),
                      RaisedButton(
                        color: Colors.white,
                        child: Text(t_s_1_h_to, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 23, color: Colors.black)),
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
                                        t_switch_1_h_to=utf8.encode(_writeController.value.text);
                                        t_s_1_h_to=_writeController.value.text;
                                        print("t_switch_1_h_to----");
                                        print(_writeController.value.text);
                                        print("----------");
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
                      Text(" : ",style: TextStyle(fontWeight: FontWeight.bold, fontSize: 23, color: Colors.black)),
                      RaisedButton(
                        color: Colors.white,
                        child: Text(t_s_1_m_to, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 23, color: Colors.black)),
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
                                        t_switch_1_m_to=utf8.encode(_writeController.value.text);
                                        t_s_1_m_to=_writeController.value.text;
                                        print("t_switch_1_m_to----");
                                        print(_writeController.value.text);
                                        print("----------");
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
                    ],
                  ),

                  */
                  Divider(),
                  Row(
                    children: <Widget>[
                      Center(child:Text("                 Switch 2"
                          ,style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30, color: Colors.green.shade900)),),

                    ],
                  ),

                  Row(

                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(

                        onPressed: () async {
                          final TimeOfDay newTime = await showTimePicker(
                            context: context,
                            initialTime: _time_s2_f,
                          );
                          if (newTime != null) {
                            setState(() {
                              _time_s2_f = newTime;
                            });
                          }
                          //String time_split=_time.format(context);

                          print(_time_split(_time_s1_f.format(context)));
                        },
                        child: Text('From',style: TextStyle(fontWeight: FontWeight.bold, fontSize: 23, color: Colors.white)),
                      ),
                      SizedBox(height: 8),
                      //${_time.format(context)}
                      Text('     Selected time: ${_time_s2_f.format(context)}',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black)),

                    ],
                  ),
                  Row(

                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          final TimeOfDay newTime = await showTimePicker(
                            context: context,
                            initialTime: _time_s2_t,
                          );
                          if (newTime != null) {
                            setState(() {
                              _time_s2_t = newTime;
                            });
                          }
                        },
                        child: Text('   To  ',style: TextStyle(fontWeight: FontWeight.bold, fontSize: 23, color: Colors.white)),
                      ),
                      SizedBox(height: 8),
                      Text(
                          '    Selected time: ${_time_s2_t.format(context)}',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black)),

                    ],
                  ),

                  /*
                  Row(
                    children: <Widget>[
                      Center(child:Text("                    Hrs.    :     Min."
                          ,style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25, color: Colors.brown)),),

                    ],
                  ),
                  Row(
                    // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      Text("From         ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 23, color: Colors.black)),
                      RaisedButton(
                        color: Colors.white,
                        child: Text(t_s_2_h_from, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 23, color: Colors.black)),
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
                                        t_switch_2_h_from=utf8.encode(_writeController.value.text);
                                        t_s_2_h_from=_writeController.value.text;
                                        print("t_switch_2_h_from----");
                                        print(_writeController.value.text);
                                        print("----------");
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
                      Text(" : ",style: TextStyle(fontWeight: FontWeight.bold, fontSize: 23, color: Colors.black)),
                      RaisedButton(
                        color: Colors.white,
                        child: Text(t_s_2_m_from, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 23, color: Colors.black)),
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
                                        t_switch_2_m_from=utf8.encode(_writeController.value.text);
                                        t_s_2_m_from=_writeController.value.text;
                                        print("t_switch_2_m_from----");
                                        print(t_switch_2_m_from);
                                        print("----------");
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
                    ],
                  ),
                  Row(
                    // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      Text("To              ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 23, color: Colors.black)),
                      RaisedButton(
                        color: Colors.white,
                        child: Text(t_s_2_h_to, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 23, color: Colors.black)),
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
                                        t_switch_2_h_to=utf8.encode(_writeController.value.text);
                                        t_s_2_h_to=_writeController.value.text;
                                        print("t_switch_2_h_to----");
                                        print(_writeController.value.text);
                                        print("----------");
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
                      Text(" : ",style: TextStyle(fontWeight: FontWeight.bold, fontSize: 23, color: Colors.black)),
                      RaisedButton(
                        color: Colors.white,
                        child: Text(t_s_2_m_to, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 23, color: Colors.black)),
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
                                        t_switch_2_m_to=utf8.encode(_writeController.value.text);
                                        t_s_2_m_to=_writeController.value.text;
                                        print("t_switch_2_m_to----");
                                        print(_writeController.value.text);
                                        print("----------");
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
                    ],
                  ),
                  */

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      new RaisedButton(
                        child: Text("Time Frame Set", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white)),
                        elevation: 5.0,
                        color: Colors.green.shade900,
                        onPressed: () {

                          switch_timeframe=initial_timeframe+dilima+_time_split(_time_s1_f.format(context))+_time_split(_time_s1_t.format(context))+dilima+_time_split(_time_s2_f.format(context))+_time_split(_time_s2_t.format(context));
                          characteristic.write(switch_timeframe);

                          print("time frame for switch 1 from ----");
                          print(_time_split(_time_s1_f.format(context)));
                          print(utf8.decode(_time_split(_time_s1_f.format(context))));
                          print("time frame for switch 1 to ----");
                          print(_time_split(_time_s1_t.format(context)));
                          print(utf8.decode(_time_split(_time_s1_t.format(context))));
                          print("time frame for switch 2 from ----");
                          print(_time_split(_time_s2_f.format(context)));
                          print(utf8.decode(_time_split(_time_s2_f.format(context))));
                          print("time frame for switch 2 to ----");
                          print(_time_split(_time_s2_t.format(context)));
                          print(utf8.decode(_time_split(_time_s2_t.format(context))));
                          print("----------");
                          print("switch Time Frame___");
                          print(switch_timeframe);
                          print(utf8.decode(switch_timeframe));
                          print("------------------");
                          // Do something here
                        },
                      ),

                    ],
                  ),









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
