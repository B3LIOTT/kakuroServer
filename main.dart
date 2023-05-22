import 'Server.dart';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:convert';
import 'dart:core';

bool _run = true;
List<Server> _privateServers_List = [];
int _PORT = 2000;
int _THIS_PORT = 8080;
String _KEY = genkey();
final int _MAX_PRIVATE_SERVERS = 20;
Random random = Random();
List<int> _port_list = List<int>.generate(_MAX_PRIVATE_SERVERS, (int index) => 2000 + index, growable: true);

void handleClient(Socket client) async {
  // Fonction qui envoie au client le port et la clé du serveur privé
  print(
      "[From MAIN] => Connexion d'un client : ${client.remoteAddress.address}:${client.remotePort}");

  final input = Utf8Decoder().bind(client).take(1);
  final responseBytes = await input.first;
  final jsonData = json.decode(responseBytes);
  print(jsonData);
  final double DENSITY = jsonData["density"] as double;
  final int SIZE = jsonData["size"] as int;

  // Vérification de la disponibilité du port
  if (_port_list.length == 0) {
    try {
      // ajouter un message d'erreur au client
      print("[From MAIN] => Le serveur est complet");
    } catch (e) {
      print("[From MAIN] => Erreur lors de l'envoi du message au client : $e");
    }
  } else {
    _PORT = _port_list[random.nextInt(_port_list.length)];
    _port_list.remove(_PORT);

    Server privateServer = Server(_PORT, _KEY, DENSITY, SIZE);
    _privateServers_List.add(privateServer);

    final data = {
      "port": _PORT,
      "key": _KEY,
    };
  
    // Incrémentation du port et de la clé pour le prochain serveur
    do {
      _KEY = genkey();
    } while (have(_KEY));

    final jsonData = jsonEncode(data);
    try {
      // Envoi des données au client
      client.write(jsonData);
    } catch (e) {
      print("[From MAIN] => Erreur lors de l'envoi des données au client : $e");
    }
  }

  // Fermeture de la connexion
  client.close();
}

void connexionThread(Null) async {
  // Thread qui gère les connexions => les demandes de création de partie privée
  print("[From MAIN] => Le thread de connexion est lancé");

  await ServerSocket.bind(InternetAddress.anyIPv4, _THIS_PORT,
          shared: true) // Attends une connexion de plusieurs joueurs
      .then((ServerSocket server) {
    print(
        "[From MAIN] => Le serveur principal est lancé sur le port $_THIS_PORT");
    server.listen(handleClient);
  });
}

String genkey() {
  String caracteres = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  Random random = Random();
  String newKey = '';

  for (int i = 0; i < 4; i++) {
    int index = random.nextInt(caracteres.length);
    newKey += caracteres[index];
  }
  return newKey;
}

bool have(String key) {
  for (Server serv in _privateServers_List) {
    if (serv.Key == key) {
      return true;
    }
  }
  return false;
}

void main() async {
  Isolate.spawn(connexionThread, null);
  print("--------------Entrez 'stop' pour arrêter le serveur--------------\n");
  late String? input;
  while (true) {
    input = stdin.readLineSync();
    if (input == "stop" || input == "STOP") {
      _run = false;
      print("[From MAIN] => La demande d'arrêt a été envoyée au thread");
      break;
    } else if (input == "clear") {
      print("\x1B[2J\x1B[0;0H"); // clear entire screen, move cursor to 0;0
      print(
          "--------------Entrez 'stop' pour arrêter le serveur--------------\n");
    } else {
      print("[From MAIN] => Commande inconnue");
    }
  }

  for (Server serv in _privateServers_List) {
    serv.endParty();
  }
}
