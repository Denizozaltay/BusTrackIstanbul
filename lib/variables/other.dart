import 'package:iett_where_is_my_bus/services/iett.dart';
import 'package:latlong2/latlong.dart';

LatLng? currentLocation;

Future<List<List<dynamic>>>? busStopsFuture;
Future<List<List<dynamic>>>? busLocationsFuture;

IETT iett = IETT();

String? selectedBusStop;
