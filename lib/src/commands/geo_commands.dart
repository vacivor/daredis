part of '../../daredis.dart';

class GeoMember {
  final double longitude;
  final double latitude;
  final String member;

  GeoMember(this.longitude, this.latitude, this.member);
}

class GeoRadiusResult {
  final String member;
  final double? distance;
  final List<double>? coordinates;
  final int? hash;

  GeoRadiusResult(this.member, {this.distance, this.coordinates, this.hash});
}

mixin RedisGeoCommands on RedisCommandExecutor {
  Future<int> geoAdd(
    String key,
    List<GeoMember> members, {
    bool? nx,
    bool? xx,
    bool? ch,
  }) async {
    final args = ['GEOADD', key];
    if (nx == true) args.add('NX');
    if (xx == true) args.add('XX');
    if (ch == true) args.add('CH');
    for (var m in members) {
      args.addAll([m.longitude.toString(), m.latitude.toString(), m.member]);
    }
    final res = await sendCommand(args);
    return Decoders.toInt(res);
  }

  Future<double?> geoDist(
    String key,
    String member1,
    String member2, {
    String? unit,
  }) async {
    final args = ['GEODIST', key, member1, member2];
    if (unit != null) args.add(unit);
    final res = await sendCommand(args);
    return Decoders.toDoubleOrNull(res);
  }

  Future<List<String?>> geoHash(String key, List<String> members) async {
    final res = await sendCommand(['GEOHASH', key, ...members]);
    if (res is List) return res.map((e) => e?.toString()).toList();
    return [];
  }

  Future<List<List<double>?>> geoPos(String key, List<String> members) async {
    final res = await sendCommand(['GEOPOS', key, ...members]);
    if (res is List) {
      return res.map((e) {
        if (e is List && e.length == 2) {
          return [double.parse(e[0].toString()), double.parse(e[1].toString())];
        }
        return null;
      }).toList();
    }
    return [];
  }

  Future<List<GeoRadiusResult>> geoRadiusGeneric(
    List<dynamic> args, {
    bool withDist = false,
    bool withCoord = false,
    bool withHash = false,
  }) async {
    final res = await sendCommand(args);
    if (res is List) {
      return res.map((item) {
        if (item is List) {
          var member = item[0].toString();
          double? dist;
          List<double>? coords;
          int? hash;
          int idx = 1;
          if (withDist) dist = double.parse(item[idx++].toString());
          if (withHash) hash = int.parse(item[idx++].toString());
          if (withCoord) {
            final coordList = item[idx++] as List;
            coords = coordList.map((e) => double.parse(e.toString())).toList();
          }
          return GeoRadiusResult(
            member,
            distance: dist,
            coordinates: coords,
            hash: hash,
          );
        } else {
          return GeoRadiusResult(item.toString());
        }
      }).toList();
    }
    return [];
  }

  Future<List<GeoRadiusResult>> geoRadius(
    String key,
    double longitude,
    double latitude,
    double radius,
    String unit, {
    bool withDist = false,
    bool withCoord = false,
    bool withHash = false,
    int? count,
    bool asc = false,
  }) async {
    final args = ['GEORADIUS', key, longitude, latitude, radius, unit];
    if (withDist) args.add('WITHDIST');
    if (withCoord) args.add('WITHCOORD');
    if (withHash) args.add('WITHHASH');
    if (count != null) args.addAll(['COUNT', count]);
    args.add(asc ? 'ASC' : 'DESC');
    return geoRadiusGeneric(
      args,
      withDist: withDist,
      withCoord: withCoord,
      withHash: withHash,
    );
  }

  Future<List<GeoRadiusResult>> geoRadiusRo(
    String key,
    double longitude,
    double latitude,
    double radius,
    String unit, {
    bool withDist = false,
    bool withCoord = false,
    bool withHash = false,
    int? count,
    bool asc = false,
  }) async {
    final args = ['GEORADIUS_RO', key, longitude, latitude, radius, unit];
    if (withDist) args.add('WITHDIST');
    if (withCoord) args.add('WITHCOORD');
    if (withHash) args.add('WITHHASH');
    if (count != null) args.addAll(['COUNT', count]);
    args.add(asc ? 'ASC' : 'DESC');
    return geoRadiusGeneric(
      args,
      withDist: withDist,
      withCoord: withCoord,
      withHash: withHash,
    );
  }

  Future<List<GeoRadiusResult>> geoRadiusByMember(
    String key,
    String member,
    double radius,
    String unit, {
    bool withDist = false,
    bool withCoord = false,
    bool withHash = false,
    int? count,
    bool asc = false,
  }) async {
    final args = ['GEORADIUSBYMEMBER', key, member, radius, unit];
    if (withDist) args.add('WITHDIST');
    if (withCoord) args.add('WITHCOORD');
    if (withHash) args.add('WITHHASH');
    if (count != null) args.addAll(['COUNT', count]);
    args.add(asc ? 'ASC' : 'DESC');
    return geoRadiusGeneric(
      args,
      withDist: withDist,
      withCoord: withCoord,
      withHash: withHash,
    );
  }

  Future<List<GeoRadiusResult>> geoRadiusByMemberRo(
    String key,
    String member,
    double radius,
    String unit, {
    bool withDist = false,
    bool withCoord = false,
    bool withHash = false,
    int? count,
    bool asc = false,
  }) async {
    final args = ['GEORADIUSBYMEMBER_RO', key, member, radius, unit];
    if (withDist) args.add('WITHDIST');
    if (withCoord) args.add('WITHCOORD');
    if (withHash) args.add('WITHHASH');
    if (count != null) args.addAll(['COUNT', count]);
    args.add(asc ? 'ASC' : 'DESC');
    return geoRadiusGeneric(
      args,
      withDist: withDist,
      withCoord: withCoord,
      withHash: withHash,
    );
  }

  Future<List<String>> geoSearch(List<dynamic> args) async {
    final res = await sendCommand(['GEOSEARCH', ...args]);
    if (res is List) return res.map((e) => e.toString()).toList();
    return [];
  }

  Future<int> geoSearchStore(List<dynamic> args) async {
    final res = await sendCommand(['GEOSEARCHSTORE', ...args]);
    return Decoders.toInt(res);
  }
}
