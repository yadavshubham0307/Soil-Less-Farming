import 'dart:async';
import 'dart:convert' show utf8;
import 'dart:developer' as developer;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';


class SwitchPage extends StatefulWidget {
  const SwitchPage({Key key, this.device}) : super(key: key);
  final BluetoothDevice device;

  @override
  _SwitchPageState createState() => _SwitchPageState();
}

class _SwitchPageState extends State<SwitchPage> {
  // final String SERVICE_UUID = "ff099a2f-4ff3-4c8c-8553-64c8ebb1a7ad";
  //final String CHARACTERISTIC_UUID = "a0396b1d-bcdd-458b-bdca-ed9f6c892afe";

  final String SERVICE_UUID = "208fc8fc-64ed-4423-ba22-2230821ae406";
  final String CHARACTERISTIC_UUID = "e462c4e9-3704-4af8-9a20-446fa2eef1d0";

  bool isReady;
  Stream<List<int>> stream;
  List<int> trans = utf8.encode('I');
  var wrt;

  String _temperature = "?";
  String _humidity = "?";
  String _intensity = "?";
  List<double> traceDust = List();

  @override
  void initState() {
    super.initState();
    isReady = false;
    connectToDevice();
  }

  connectToDevice() async {
    if (widget.device == null) {
      _Pop();
      return;
    }

    new Timer(const Duration(seconds: 15), () {
      if (!isReady) {
        disconnectFromDevice();
        _Pop();
      }
    });

    await widget.device.connect();
    discoverServices();
  }

  disconnectFromDevice() {
    if (widget.device == null) {
      _Pop();
      return;
    }

    widget.device.disconnect();
  }

  discoverServices() async {
    if (widget.device == null) {
      _Pop();
      return;
    }

    List<BluetoothService> services = await widget.device.discoverServices();
    services.forEach((service) {
      if (service.uuid.toString() == SERVICE_UUID) {
        service.characteristics.forEach((characteristic) {
          if (characteristic.uuid.toString() == CHARACTERISTIC_UUID) {
            characteristic.setNotifyValue(!characteristic.isNotifying);
            stream = characteristic.value;
            wrt=characteristic.write(trans);
            setState(() {
              isReady = true;
            });
          }
        });
      }
    });

    if (!isReady) {
      _Pop();
    }
  }

  Future<bool> _onWillPop() {
    return showDialog(
        context: context,
        builder: (context) =>
        new AlertDialog(
          title: Text('Are you sure?'),
          content: Text('Do you want to disconnect device and go back?'),
          actions: <Widget>[
            new FlatButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: new Text('No')),
            new FlatButton(
                onPressed: () {
                  disconnectFromDevice();
                  Navigator.of(context).pop(true);
                },
                child: new Text('Yes')),
          ],
        ) ??
            false);
  }

  _Pop() {
    Navigator.of(context).pop(true);
  }

  String _dataParser(List<int> dataFromDevice) {
    //  print("Data:   String :  "+dataFromDevice);

    List<int> strArr = dataFromDevice;
    print(strArr);

    _DataParser(utf8.decode(dataFromDevice));
    return utf8.decode(dataFromDevice);

  }


  _DataParser(String data) {
    print("Data:  "+data);
    if (data.isNotEmpty) {
      var tempValue = data.split(" ")[0];
      // var humidityValue = data.split(" ")[1];
      //  var intensityValue = data.split(" ")[2];

      print("tempValue: ${tempValue}");
      //  print("humidityValue: ${humidityValue}");
      // print("intensityValue: ${intensityValue}");

      _temperature = tempValue + " lx";
      //  _humidity = humidityValue + "%";
      // _intensity = intensityValue + "lx";

    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
          appBar: AppBar(
            title: Text('Switch'),
            backgroundColor: Colors.green.shade900,
          ),
          body:new Stack(
            fit: StackFit.expand,
            children: <Widget>[Container(
              //child: Image.asset('images/bg.jpg'),
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("images/inhomegarden.jpg"),
                  fit: BoxFit.cover,
                ),
              ),
            ),
              Positioned.fill(
                child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: 2.0,
                      sigmaY: 2.0,
                    ),
                    child: Scaffold(  // Your usual Scaffold for content
                      backgroundColor: Colors.lightGreen.shade100.withOpacity(0.4),
                      body: Container(),
                    )
                ),
              ),
              !isReady
                  ? Center(
                  child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Colors.green.shade900),
                    strokeWidth: 10,))

                  :Container(

                child: StreamBuilder<List<int>>(
                  stream: stream,
                  builder: (BuildContext context,
                      AsyncSnapshot<List<int>> snapshot) {
                    if (snapshot.hasError)
                      return Text('Error: ${snapshot.error}');

                    if (snapshot.connectionState ==
                        ConnectionState.active) {

                      var currentValue = _dataParser(snapshot.data);
                      print("Data: "+currentValue);
                      traceDust.add(double.tryParse(currentValue) ?? 0);
                      return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Expanded(


                                flex: 1,
                                child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: <Widget>[

                                      Card(
                                        elevation: 0,
                                        color: Colors.transparent,
                                        child: Container(
                                          width: 150,
                                          height: 200,
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: <Widget>[
                                              SizedBox(
                                                height: 10,
                                              ),
                                              Container(
                                                width: 300,
                                                height: 100,
                                                child:   GestureDetector(
                                                  onTap: (){
                                                    wrt;
                                                    print(wrt);
                                                    print("Tapped a Container");
                                                  },
                                                  child: Image.asset('images/switch_img.png'),
                                                ),// ,
                                              ),
                                              SizedBox(
                                                height: 10,
                                              ),
                                              Text(
                                                "Switch 1",
                                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 23,  color: Colors.black),
                                              ),
                                              Expanded(
                                                child: Container(),
                                              ),


                                              Text(_temperature,
                                                //"${currentValue} 'C"
                                                style:
                                                TextStyle(fontWeight:FontWeight.bold,fontSize: 30,  color: Colors.black),),

                                              SizedBox(
                                                height: 10,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),








                                    ]),




                              ),
                            ],
                          ));
                    } else {
                      return Text('Check the stream');
                    }
                  },
                ),


              )

            ],
          )


      ),
    );
  }

  _bulldMyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Card(
            elevation: 0,
            color: Colors.transparent,
            child: Container(
              width: 150,
              height: 200,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  SizedBox(
                    height: 10,
                  ),
                  Container(
                    width: 100,
                    height: 100,
                    child:   GestureDetector(
                      onTap: (){
                        print("Tapped a Container");
                      },
                      child: Image.asset('images/lighticon.png'),
                    ),// ,
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Text(
                    "Light Intensity",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20,  color: Colors.black),
                  ),
                  Expanded(
                    child: Container(),
                  ),



                  SizedBox(
                    height: 10,
                  ),
                ],
              ),
            ),
          ),
          Card(
            elevation: 0,
            color: Colors.transparent,
            child: Container(
              width: 150,
              height: 200,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  SizedBox(
                    height: 10,
                  ),
                  Container(
                    width: 100,
                    height: 100,
                    child: GestureDetector(
                      onTap: (){
                        print("Tapped a Container");
                      },
                      child: Image.asset('images/temprature2.png'),
                    ),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Text(
                    "Temperature",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20,color: Colors.black),
                  ),
                  Expanded(
                    child: Container(),
                  ),


                  SizedBox(
                    height: 10,
                  ),
                ],
              ),
            ),
          ),
          Card(
            elevation: 0,
            color: Colors.transparent,
            child: Container(
              width: 150,
              height: 200,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  SizedBox(
                    height: 10,
                  ),
                  Container(
                    width: 100,
                    height: 100,
                    child: GestureDetector(
                      onTap: (){
                        print("Tapped a Container");
                      },
                      child: Image.asset('images/humidity2.png'),
                    ),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Text(
                    "Humidity",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20,  color: Colors.black),
                  ),
                  Expanded(
                    child: Container(
                    ),
                  ),



                  SizedBox(
                    height: 10,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
