import 'package:flutter/material.dart';
import 'package:flutter_card_game/models/card_model.dart';
import 'package:flutter_card_game/models/deck_model.dart';
import 'package:flutter_card_game/models/player_model.dart';
import 'package:flutter_card_game/models/turn_model.dart';
import 'package:flutter_card_game/services/deck_service.dart';

class GameProvider with ChangeNotifier {
  GameProvider() {
    _service = DeckService();
  }

  late DeckService _service;

  late Turn _turn;
  Turn get turn => _turn;

  // 这样写只读属性
  DeckModel? _currentDeck;
  DeckModel? get currentDeck => _currentDeck;

  List<PlayerModel> _players = [];
  List<PlayerModel> get players => _players;

  List<CardModel> _discards = [];
  List<CardModel> get discards => _discards;

  CardModel? get discardTop => _discards.isEmpty ? null : _discards.last;

  Map<String, dynamic> gameState = {};

  Future<void> newGame(List<PlayerModel> players) async {
    final deck = await _service.newDeck();
    _currentDeck = deck;
    _players = players;
    _discards = [];
    _turn = Turn(players: players, currentPlayer: players.first);
    setupBoard();

    notifyListeners();
  }

  Future<void> setupBoard() async {}

  bool get canDrawCard {
    return turn.drawCount < 1;
  }

  Future<void> drawCards(PlayerModel player, {int count = 1}) async {
    if (currentDeck == null) return;
    if (!canDrawCard) return;

    final draw = await _service.drawCards(_currentDeck!, count: count);

    player.addCards(draw.cards);
    _turn.drawCount += count;

    _currentDeck!.remaining = draw.remaining;

    notifyListeners();
  }

  bool get canEndTurn {
    return turn.drawCount > 0;
  }

  void endTurn() async {
    _turn.nextTurn();

    if (_turn.currentPlayer.isBot) {
      botTurn();
    }

    notifyListeners();
  }

  bool canPlayCard(CardModel card) {
    return _turn.actionCount < 1;
  }

  Future<void> playCard({
    required PlayerModel player,
    required CardModel card,
  }) async {
    if (!canPlayCard(card)) return;

    player.removeCard(card);

    _discards.add(card);

    await applyCardSideEffect(card);

    _turn.actionCount += 1;

    notifyListeners();
  }

  Future<void> applyCardSideEffect(CardModel card) async {}

  Future<void> botTurn() async {
    await Future.delayed(const Duration(milliseconds: 500));
    await drawCards(_turn.currentPlayer);
    await Future.delayed(const Duration(milliseconds: 500));

    if (_turn.currentPlayer.cards.isNotEmpty) {
      await Future.delayed(const Duration(milliseconds: 1000));
      
      playCard(
          player: _turn.currentPlayer, card: _turn.currentPlayer.cards.first);
    }

    if (canEndTurn) {
      endTurn();
    }
  }
}
