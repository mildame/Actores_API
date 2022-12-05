import 'dart:ffi';

import 'package:http/http.dart' as http;

import 'dart:convert';
import 'dart:async';

import 'package:scooby_app/src/models/actores_model.dart';
import 'package:scooby_app/src/models/pelicula_model.dart';

class ActoresProvider {
  String _apikey = 'ad7d26135dc62bf6546c1946542ba99d';
  String _url = 'api.themoviedb.org';
  String _language = 'es-ES';

  int _popularesPage = 0;
  bool _cargando = false;

  List<Actor> _populares = [];

  final _popularesStreamController = StreamController<List<Actor>>.broadcast();

  Function(List<Actor>) get popularesSink =>
      _popularesStreamController.sink.add;

  Stream<List<Actor>> get popularesStream => _popularesStreamController.stream;

  void disposeStreams() {
    _popularesStreamController?.close();
  }

  Future<List<Actor>> _procesarRespuesta(Uri url) async {
    final resp = await http.get(url);
    final decodedData = json.decode(resp.body);

    final actores = new Actor.fromJsonList(decodedData['results']);

    return actores.items;
  }

  Future<List<Actor>> getEnCines() async {
    final url = Uri.https(_url, '3/movie/now_playing',
        {'api_key': _apikey, 'language': _language}); // Pelicula
    return await _procesarRespuesta(url);
  }

  Future<List<Actor>> getPopulares() async {
    if (_cargando) return [];

    _cargando = true;
    _popularesPage++;

    final url = Uri.https(_url, '3/person/popular', {
      'api_key': _apikey,
      'language': _language,
      'page': _popularesPage.toString()
    }); // Pelicula
    final resp = await _procesarRespuesta(url);

    _populares.addAll(resp);
    popularesSink(_populares);

    _cargando = false;
    return resp;
  }

  Future<List<Actor>> getCast(String peliId) async {
    final url = Uri.https(_url, '3/movie/$peliId/credits',
        {'api_key': _apikey, 'language': _language}); // pelicula

    final resp = await http.get(url);
    final decodedData = json.decode(resp.body);

    final cast = new Cast.fromJsonList(decodedData['cast']);

    return cast.actores;
  }

  Future<List<Actor>> buscarActor(String query) async {
    final url = Uri.https(_url, '3/people/search', {
      'api_key': _apikey,
      'language': _language,
      'query': query
    }); // Pelicula

    return await _procesarRespuesta(url);
  }

  Future<String> getActorBio(int id) async {
    final url = Uri.https(
        _url, '3/person/$id', {'api_key': _apikey, 'language': _language});
    final resp = await http.get(url);
    final decodedData = json.decode(resp.body);
    var arrError = [
      "No hi ha informació per a aquesta actriu :(",
      "No hi ha informació per a aquest actor :("
    ];

    if (decodedData['biography'] == "") {
      if (decodedData['gender'] == 1)
        return arrError[0];
      else if (decodedData['gender'] == 2) return arrError[1];
    }

    return decodedData['biography'];
  }
}
