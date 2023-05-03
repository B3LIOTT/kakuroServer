import 'dart:io';
import 'Server.dart';
import 'dart:convert';
import 'Carre.dart';

class Player {
  late Server _server;
  late Socket _socket;
  late String _ip;
  late int _port;
  late String _key;
  late final int _ID;
  int _requestNb = 0;
  String buffer = "";
  int _count = 0;

  Player(this._server, this._socket, this._ID) {
    _ip = _socket.remoteAddress.address;
    _port = _socket.remotePort;

    initHandler();
  }

  void initHandler() async {
    final input = Utf8Decoder().bind(_socket);

    input.listen(dataHandler, onError: errorHandler, onDone: doneHandler);
  }

  void dataHandler(String data) async {
    // Fonction qui gère les données reçues du client (la matrice de jeu)

    if (_requestNb == 0) {
      print(
          "[From Player: $_ID of Server: ${_server.Key}] => Attente de la clé du client");
      final jsonData = json.decode(data);
      print(
          "[From Player: $_ID of Server: ${_server.Key}] => Clé du client reçue : $jsonData");

      if (jsonData == _server.Key) {
        print(
            "[From Player: $_ID of Server: ${_server.Key}] => Clé du client correcte");

        if (_server.Players.length > 1) {
          // Envoi de la difficulté et de la taille du jeu au client
          final settings = {
            "density": _server.Density,
            "size": _server.Size,
          };
          _socket.write(jsonEncode(settings));
          await Future.delayed(Duration(milliseconds: 100));

          // Envoi de la matrice du jeu au client
          await sendMatrix(_socket, _server.GameMatrix);
        }
      } else {
        print(
            "[From Player: $_ID of Server: ${_server.Key}] => Clé du client incorrecte");
        _server.removeClient(this);
        _socket.close();
      }
      _requestNb++;
    } else if (_requestNb <= _server.Size && _ID == 0) {
      // Seul le créateur de la partie envoie la matrice initiale du jeu
      if (data.isNotEmpty /*&& data != message d'arret à définir*/) {
        // Actualisation de la matrice du jeu
        buffer += data;
        _count++;
        print(
            "[From Player: $_ID of Server: ${_server.Key}] => indice de ligne de matrice du jeu reçue : ${_count - 1}");
        if (_count == _server.Size) {
          final jsonList = const LineSplitter().convert(buffer);
          List<List<Carre>> matrix = [];

          for (final json in jsonList) {
            final List<Carre> row = [];

            for (final carreJson in jsonDecode(json)) {
              final carre = Carre.fromJson(carreJson);
              row.add(carre);
            }
            matrix.add(row);
          }
          _count = 0;
          buffer = "";
          print(matrix);
          _server.updateGame(matrix);
        }
      }
      _requestNb++;
    } else {
      final jsonData = jsonDecode(data);
      print(
          "[From Player: $_ID of Server: ${_server.Key}] => Message de fin de partie reçu : $jsonData");

      // Envoi du message de fin de partie à tous les joueurs
      _server.sendToAllForEnd(data, _socket);
    }
  }

  void errorHandler(error, StackTrace trace) {
    stdout.write(
        '[From Player: $_ID of Server: ${_server.Key}] => Error From Player: $_ip:$_port: $error');
    _server.removeClient(this);
    _socket.close();
  }

  void doneHandler() {
    stdout.write(
        '[From Player: $_ID of Server: ${_server.Key}] => $_ip:$_port disconnected');
    _server.removeClient(this);
    _socket.close();
  }

  Socket get Sock {
    return _socket;
  }

  Future<void> sendMatrix(Socket socket, List<List<Carre>> board) async {
    for (final row in board) {
      final jsonRow = jsonEncode(row.map((c) => c.toJson()).toList());
      socket.write('$jsonRow\n');
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }
}
