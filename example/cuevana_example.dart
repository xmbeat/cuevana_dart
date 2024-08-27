import 'package:cuevana/cuevana.dart';

Future<void> main() async {
  var client = CuevanaClient();
  var movie = (await client.search("The Matrix")).movies.first;
  var fullMovie = await client.getMovie(movie.id);
  print(movie.title);
  print(movie.overview);
  var video = fullMovie.videos.first.sources.first;
  print(video.url);
  var direct = await client.getEmbedUrl(video.url);
  print(direct);
}
