import 'dart:convert';

import 'package:dio/dio.dart';

class Genre {
  String id;
  String name;
  Genre(this.id, this.name);
}

class CastActor {
  String id;
  String name;
  CastActor(this.id, this.name);
}

class Episode {
  String id;
  String title;
  String image;
  int number;
  List<VideoServer> videoServers;
  Episode(
      {required this.id,
      required this.title,
      required this.image,
      required this.videoServers,
      required this.number});
}

class EpisodeBrief {
  String id;
  String title;
  String image;
  int number;
  EpisodeBrief(
      {required this.id,
      required this.title,
      required this.image,
      required this.number});
}

class VideoServer {
  String language;
  List<MediaSource> sources;
  VideoServer({required this.language, required this.sources});
}

class MediaSource {
  String quality;
  String name;
  String url;
  MediaSource({required this.quality, required this.name, required this.url});
}

class Movie {
  String id;
  String title;
  double rate;
  String poster;
  String banner;
  String overview;
  String idTMDb;
  List<Genre> genres;
  List<CastActor> cast;
  DateTime releaseDate;
  List<VideoServer> videos;
  Movie(
      {required this.id,
      required this.title,
      required this.rate,
      required this.poster,
      required this.banner,
      required this.overview,
      required this.idTMDb,
      required this.genres,
      required this.cast,
      required this.videos,
      required this.releaseDate});
}

class MovieBrief {
  String id;
  String title;
  double? rate;
  String poster;
  String? banner;
  String overview;
  String idTMDb;
  List<Genre>? genres;
  List<CastActor>? cast;
  DateTime? releaseDate;
  MovieBrief(
      {required this.id,
      required this.title,
      this.rate,
      required this.poster,
      this.banner,
      required this.overview,
      required this.idTMDb,
      this.genres,
      this.cast,
      this.releaseDate});
}

class Season {
  int number;
  List<EpisodeBrief> episodes;
  Season({required this.number, required this.episodes});
}

class Serie {
  String id;
  String title;
  double rate;
  String poster;
  String banner;
  String overview;
  String idTMDb;
  List<Genre> genres;
  List<CastActor> cast;
  DateTime releaseDate;
  List<Season> seasons;
  Serie(
      {required this.seasons,
      required this.id,
      required this.title,
      required this.rate,
      required this.poster,
      required this.banner,
      required this.overview,
      required this.idTMDb,
      required this.genres,
      required this.cast,
      required this.releaseDate});
}

class SerieBrief {
  String id;
  String title;
  double? rate;
  String poster;
  String? banner;
  String overview;
  String idTMDb;
  List<Genre>? genres;
  List<CastActor>? cast;
  DateTime? releaseDate;
  SerieBrief(
      {required this.id,
      required this.title,
      this.rate,
      required this.poster,
      this.banner,
      required this.overview,
      required this.idTMDb,
      this.genres,
      this.cast,
      this.releaseDate});
}

class SearchResult {
  List<MovieBrief> movies;
  List<SerieBrief> series;
  SearchResult({required this.movies, required this.series});
}

class CuevanaClient {
  final String _urlBase = "https://cuevana.biz";

  Future<List<MovieBrief>> getFeaturedMovies() async {
    var dio = Dio(BaseOptions(
      baseUrl: _urlBase,
      validateStatus: (status) => status! < 500,
      responseType: ResponseType.plain,
    ));
    var response = await dio.get('/peliculas/estrenos');
    var regex = RegExp(
        "<script id=\"__NEXT_DATA__\" type=\"application/json\">(.*?)</script>");
    var match = regex.firstMatch(response.data);
    if (match == null) {
      throw Exception("No se pudo obtener la información de la página");
    }
    var json = jsonDecode(match.group(1)!);
    var movies = json['props']['pageProps']['movies'];
    var result = <MovieBrief>[];
    for (var movie in movies) {
      result.add(MovieBrief(
        id: (movie['url']['slug'] as String).split('/').sublist(1).join('/'),
        title: movie['titles']['name'] ?? '',
        rate: double.parse(movie['rate']['average'].toString()),
        poster: movie['images']['poster'] ?? '',
        banner: movie['images']['backdrop'] ?? '',
        overview: movie['overview'] ?? '',
        idTMDb: movie['TMDbId'],
        genres: movie['genres']
            .map<Genre>((e) => Genre(e['id'], e['name']))
            .toList(),
        cast: movie['cast']['acting']
            .map<CastActor>((e) => CastActor(e['id'], e['name']))
            .toList(),
        releaseDate: DateTime.parse(movie['releaseDate']),
      ));
    }
    return result;
  }

  Future<String> getEmbedUrl(String url) async {
    var dio = Dio(BaseOptions(
      validateStatus: (status) => status! < 500,
      responseType: ResponseType.plain,
    ));
    var response = await dio.get(url);
    var regex = RegExp("var url = '(.*?)';");
    var match = regex.firstMatch(response.data);
    if (match == null) {
      throw Exception("No se pudo obtener la información de la página");
    }
    return match.group(1)!;
  }

  Future<Movie> getMovie(String id) async {
    var dio = Dio(BaseOptions(
      baseUrl: _urlBase,
      validateStatus: (status) => status! < 500,
      responseType: ResponseType.plain,
    ));
    var response = await dio.get('/pelicula/$id');
    var regex = RegExp(
        "<script id=\"__NEXT_DATA__\" type=\"application/json\">(.*?)</script>");
    var match = regex.firstMatch(response.data);
    if (match == null) {
      throw Exception("No se pudo obtener la información de la página");
    }
    var json = jsonDecode(match.group(1)!);
    var movie = json['props']['pageProps']['thisMovie'];
    return Movie(
      id: id,
      title: movie['titles']['name'],
      rate: double.parse(movie['rate']['average'].toString()),
      poster: movie['images']['poster'],
      banner: movie['images']['backdrop'],
      overview: movie['overview'],
      idTMDb: movie['TMDbId'],
      genres:
          movie['genres'].map<Genre>((e) => Genre(e['id'], e['name'])).toList(),
      cast: movie['cast']['acting']
          .map<CastActor>((e) => CastActor(e['id'], e['name']))
          .toList(),
      videos: movie['videos'].entries.map<VideoServer>((e) {
        var language = e.key;
        var value = e.value;
        return VideoServer(
          language: language,
          sources: value
              .map<MediaSource>((e) => MediaSource(
                    quality: e['quality'],
                    name: e['cyberlocker'],
                    url: e['result'],
                  ))
              .toList(),
        );
      }).toList(),
      releaseDate: DateTime.parse(movie['releaseDate']),
    );
  }

  Future<List<SerieBrief>> getTopSeries() async {
    var dio = Dio(BaseOptions(
      baseUrl: _urlBase,
      validateStatus: (status) => status! < 500,
      responseType: ResponseType.plain,
    ));
    var response = await dio.get('/series');
    var regex = RegExp(
        "<script id=\"__NEXT_DATA__\" type=\"application/json\">(.*?)</script>");
    var match = regex.firstMatch(response.data);
    if (match == null) {
      throw Exception("No se pudo obtener la información de la página");
    }
    var json = jsonDecode(match.group(1)!);
    var result = <SerieBrief>[];
    for (var serie in json['props']['pageProps']['movies']) {
      result.add(SerieBrief(
        id: (serie['url']['slug'] as String).split('/').sublist(1).join('/'),
        title: serie['titles']['name'],
        rate: double.parse(serie['rate']['average'].toString()),
        poster: serie['images']['poster'],
        banner: serie['images']['backdrop'],
        overview: serie['overview'],
        idTMDb: serie['TMDbId'],
        genres: serie['genres']
            .map<Genre>((e) => Genre(e['id'], e['name']))
            .toList(),
        cast: serie['cast']['acting']
            .map<CastActor>((e) => CastActor(e['id'], e['name']))
            .toList(),
        releaseDate: DateTime.parse(serie['releaseDate']),
      ));
    }
    return result;
  }

  Future<Episode> getEpisode(String id) async {
    var dio = Dio(BaseOptions(
      baseUrl: _urlBase,
      validateStatus: (status) => status! < 500,
      responseType: ResponseType.plain,
    ));
    var response = await dio.get('/serie/$id');
    var regex = RegExp(
        "<script id=\"__NEXT_DATA__\" type=\"application/json\">(.*?)</script>");
    var match = regex.firstMatch(response.data);
    if (match == null) {
      throw Exception("No se pudo obtener la información de la página");
    }
    var json = jsonDecode(match.group(1)!);
    var episode = json['props']['pageProps']['episode'];
    return Episode(
      id: id,
      title: episode['title'],
      image: episode['image'],
      number: episode['number'],
      videoServers: (episode['videos'] as Map).entries.map<VideoServer>((e) {
        var language = e.key;
        var value = e.value;
        return VideoServer(
          language: language,
          sources: value
              .map<MediaSource>((e) => MediaSource(
                    quality: e['quality'],
                    name: e['cyberlocker'],
                    url: e['result'],
                  ))
              .toList(),
        );
      }).toList(),
    );
  }

  Future<Serie> getSerie(String id) async {
    var dio = Dio(BaseOptions(
      baseUrl: _urlBase,
      validateStatus: (status) => status! < 500,
      responseType: ResponseType.plain,
    ));
    var response = await dio.get('/serie/$id');
    var regex = RegExp(
        "<script id=\"__NEXT_DATA__\" type=\"application/json\">(.*?)</script>");
    var match = regex.firstMatch(response.data);
    if (match == null) {
      throw Exception("No se pudo obtener la información de la página");
    }
    var json = jsonDecode(match.group(1)!);
    var serie = json['props']['pageProps']['thisSerie'];
    return Serie(
      id: id,
      title: serie['titles']['name'],
      rate: double.parse(serie['rate']['average'].toString()) / 2,
      poster: serie['images']['poster'],
      banner: serie['images']['backdrop'],
      overview: serie['overview'],
      idTMDb: serie['TMDbId'],
      genres:
          serie['genres'].map<Genre>((e) => Genre(e['id'], e['name'])).toList(),
      cast: serie['cast']['acting']
          .map<CastActor>((e) => CastActor(e['id'], e['name']))
          .toList(),
      releaseDate: DateTime.parse(serie['releaseDate']),
      seasons: (serie['seasons'] as List)
          .where((e) => e['episodes'].length > 0)
          .map<Season>((e) => Season(
              number: e['number'],
              episodes: e['episodes'].map<EpisodeBrief>((e) {
                var parts = e['url']['slug'].split('/');
                var id = [
                  parts[1],
                  parts[2],
                  "temporada",
                  parts[4],
                  "episodio",
                  parts[6]
                ].join('/');
                return EpisodeBrief(
                  id: id,
                  title: e['title'],
                  image: e['image'],
                  number: e['number'],
                );
              }).toList()))
          .toList(),
    );
  }

  Future<SearchResult> search(String query) async {
    var dio = Dio(BaseOptions(
      baseUrl: _urlBase,
      validateStatus: (status) => status! < 500,
      responseType: ResponseType.plain,
    ));
    var response = await dio.get('/search?q=${Uri.encodeComponent(query)}');
    var regex = RegExp(
        "<script id=\"__NEXT_DATA__\" type=\"application/json\">(.*?)</script>");
    var match = regex.firstMatch(response.data);
    if (match == null) {
      throw Exception("No se pudo obtener la información de la página");
    }
    var json = jsonDecode(match.group(1)!);
    var results = json['props']['pageProps']['movies'];
    var movies = <MovieBrief>[];
    var series = <SerieBrief>[];
    for (var result in results) {
      var parts = result['url']['slug'].split('/');
      if (parts[0] == 'movies') {
        var id = [parts[1], parts[2]].join('/');
        movies.add(MovieBrief(
          id: id,
          title: result['titles']['name'],
          poster: result['images']['poster'],
          overview: result['overview'],
          idTMDb: result['TMDbId'],
        ));
      } else if (parts[0] == 'series') {
        var id = [parts[1], parts[2]].join('/');
        series.add(SerieBrief(
          id: id,
          title: result['titles']['name'],
          poster: result['images']['poster'],
          overview: result['overview'],
          idTMDb: result['TMDbId'],
        ));
      }
    }
    return SearchResult(movies: movies, series: series);
  }
}
