import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import 'package:xml2json/xml2json.dart';
import 'dart:convert';

class IETT {
  Future<List<List>> getLineStops(String lineCode, String direction) async {
    var headers = {'Content-Type': 'text/xml; charset=utf-8'};
    var envelope = '''
  <soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tem="http://tempuri.org/">
      <soapenv:Header/>
    <soapenv:Body>
      <tem:DurakDetay_GYY>
        <tem:hat_kodu>$lineCode</tem:hat_kodu>
      </tem:DurakDetay_GYY>
    </soapenv:Body>
  </soapenv:Envelope>
  ''';

    var response = await http.post(
      Uri.parse('https://api.ibb.gov.tr/iett/ibb/ibb.asmx?wsdl'),
      headers: headers,
      body: envelope,
    );

    var document = xml.XmlDocument.parse(response.body);
    var transformer = Xml2Json();
    transformer.parse(document.toXmlString());

    var json = transformer.toParker();
    var map = jsonDecode(json);

    List<dynamic> tables = map['soap:Envelope']['soap:Body']
            ['DurakDetay_GYYResponse']['DurakDetay_GYYResult']['NewDataSet']
        ['Table'];

    List<dynamic> filteredTables = [];
    for (var table in tables) {
      if (table['YON'] == direction) {
        filteredTables.add(table);
      }
    }

    List<List<dynamic>> stops = [];
    for (var table in filteredTables) {
      stops.add([
        table['DURAKADI'],
        table['YKOORDINATI'],
        table['XKOORDINATI'],
      ]);
    }

    return stops;
  }

  Future<List<List<String>>> getBusLocations(
      String lineCode, String direction) async {
    var headers = {'Content-Type': 'text/xml; charset=utf-8'};
    var envelope = '''
    <soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tem="http://tempuri.org/">
      <soapenv:Header/>
      <soapenv:Body>
        <tem:GetHatOtoKonum_json>
          <tem:HatKodu>$lineCode</tem:HatKodu>
        </tem:GetHatOtoKonum_json>
      </soapenv:Body>
    </soapenv:Envelope>
  ''';

    var response = await http.post(
      Uri.parse(
          'https://api.ibb.gov.tr/iett/FiloDurum/SeferGerceklesme.asmx?wsdl'),
      headers: headers,
      body: envelope,
    );

    var transformer = Xml2Json();
    transformer.parse(response.body);
    var json = transformer.toParker();
    var data = jsonDecode(json);

    var locationsJson = data['soap:Envelope']['soap:Body']
        ['GetHatOtoKonum_jsonResponse']['GetHatOtoKonum_jsonResult'];
    var locations = jsonDecode(locationsJson);

    List<List<String>> busLocationsList = [];
    for (var location in locations) {
      var guzergahKoduParts = location['guzergahkodu'].split('_');
      if (guzergahKoduParts[1] == direction) {
        busLocationsList.add([
          location['kapino'],
          location['enlem'].toString(),
          location['boylam'].toString()
        ]);
      }
    }

    return busLocationsList;
  }
}
