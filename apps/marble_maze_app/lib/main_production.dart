import 'package:marble_maze_app/app/app.dart';
import 'package:marble_maze_app/bootstrap.dart';

Future<void> main() async {
  await bootstrap(() => const App());
}
