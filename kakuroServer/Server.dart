import "dart:io";
import 'Player.dart';
import 'Carre.dart';

class Server {
  bool run = true;
  late int _PORT;
  late String _KEY;
  List<Player> _players = [];
  late double _density;
  late int _size;
  late List<List<Carre>> _gameMatrix;
  int _usrID = 0;
  late ServerSocket _serverSocket;

  Server(this._PORT, this._KEY, this._density, this._size) {
    playerConnexions();
  }

  void playerConnexions() async {
    // await permet d'attendre indéfiniment
    _serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, _PORT,
        shared: true); // Attends une connexion d'un joueur
    print(
        "[From $_KEY] => Le serveur $_KEY est lancé sur le port $_PORT avec une taille de $_size et une difficulté de $_density");

    _serverSocket.listen(handleClient);
  }

  void handleClient(Socket client) {
    Player currentPlayer = Player(this, client, _usrID);
    _usrID++; // sémaphore ?
    _players.add(currentPlayer);
    print('[From $_KEY] => Connection from '
        '${client.remoteAddress.address}:${client.remotePort}');
  }

  void updateGame(List<List<Carre>> data) {
    _gameMatrix = data;
  }

  void removeClient(Player player) {
    _players.remove(player);
  }

  void endParty() {
    for (Player player in _players) {
      player.Sock.close();
    }
    print("Le serveur $_KEY a été arrêté");
    run = false;
  }

  void sendToAllForEnd(String message, Socket winner) {
    for (Player player in _players) {
      if (player.Sock != winner) {
        player.Sock.write(message);
      }
    }
    endParty();
    _serverSocket.close();
    print("[From $_KEY] => Le serveur $_KEY est fermé");
  }

  String get Key => _KEY;

  List<List<Carre>> get GameMatrix => _gameMatrix;

  List<Player> get Players => _players;

  int get Size => _size;

  double get Density => _density;
}
