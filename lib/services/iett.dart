import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import 'package:xml2json/xml2json.dart';
import 'dart:convert';

class IETT {
  static const Map<String, String> _headers = {
    'Content-Type': 'text/xml; charset=utf-8'
  };

  Future<List<List<dynamic>>> getLineStops(
      String lineCode, String direction) async {
    final envelope = '''
      <soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tem="http://tempuri.org/">
        <soapenv:Header/>
        <soapenv:Body>
          <tem:DurakDetay_GYY>
            <tem:hat_kodu>$lineCode</tem:hat_kodu>
          </tem:DurakDetay_GYY>
        </soapenv:Body>
      </soapenv:Envelope>
    ''';

    final response = await http.post(
      Uri.parse('https://api.ibb.gov.tr/iett/ibb/ibb.asmx?wsdl'),
      headers: _headers,
      body: envelope,
    );

    final document = xml.XmlDocument.parse(response.body);
    final transformer = Xml2Json();
    transformer.parse(document.toXmlString());

    final jsonMap = jsonDecode(transformer.toParker());

    final tables = jsonMap['soap:Envelope']?['soap:Body']
            ?['DurakDetay_GYYResponse']?['DurakDetay_GYYResult']?['NewDataSet']
        ?['Table'];

    if (tables == null) {
      return [];
    }

    final tableList = tables is List<dynamic> ? tables : [tables];

    final stops = tableList
        .where((table) => table['YON'] == direction)
        .map<List<dynamic>>((table) => [
              table['DURAKADI'],
              table['YKOORDINATI'],
              table['XKOORDINATI'],
            ])
        .toList();

    return stops;
  }

  Future<List<List<String>>> getBusLocations(
      String lineCode, String direction) async {
    final envelope = '''
      <soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tem="http://tempuri.org/">
        <soapenv:Header/>
        <soapenv:Body>
          <tem:GetHatOtoKonum_json>
            <tem:HatKodu>$lineCode</tem:HatKodu>
          </tem:GetHatOtoKonum_json>
        </soapenv:Body>
      </soapenv:Envelope>
    ''';

    final response = await http.post(
      Uri.parse(
          'https://api.ibb.gov.tr/iett/FiloDurum/SeferGerceklesme.asmx?wsdl'),
      headers: _headers,
      body: envelope,
    );

    final transformer = Xml2Json();
    transformer.parse(response.body);
    final jsonMap = jsonDecode(transformer.toParker());

    final locationsJson = jsonMap['soap:Envelope']?['soap:Body']
        ?['GetHatOtoKonum_jsonResponse']?['GetHatOtoKonum_jsonResult'];

    if (locationsJson == null) {
      return [];
    }

    final locations = jsonDecode(locationsJson);
    final locationList = locations is List<dynamic> ? locations : [locations];

    final busLocations = locationList
        .where((location) {
          final parts = location['guzergahkodu']?.split('_') ?? [];
          return parts.length > 1 && parts[1] == direction;
        })
        .map<List<String>>((location) => [
              location['kapino']?.toString() ?? '',
              location['enlem']?.toString() ?? '',
              location['boylam']?.toString() ?? '',
            ])
        .toList();

    return busLocations;
  }
}
