// ✨ Firebase連携のために必要なパッケージをインポート
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

// ✨ main関数を非同期にし、Firebaseの初期化処理を追加
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

// ゲームの状態を管理する列挙型
enum GameState { startScreen, countdown, playing, gameOver, goal }

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Ball Game',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const GamePage(),
    );
  }
}

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage>
    with SingleTickerProviderStateMixin {
  // p5.jsのグローバル変数に相当するゲームの状態変数
  double x = 50;
  double y = 200;
  double vx = 5;
  double vy = 0.6;
  double nowX = 0; // 実質的なX座標（カメラ位置）
  double timer = 0;
  double goalTime = 0;
  double effectPos = 0;

  GameState _gameState = GameState.startScreen;
  late Ticker _ticker; // ゲームループを管理するTicker

  // 障害物の座標
  final List<double> obstacles = [];

  // ゲームの定数
  final double gravity = 0.9;
  final double elasticity = 0.7;
  final double goalLine = 12000;
  final double screenWidth = 720;
  final double screenHeight = 400;
  final double ballRadius = 25;

  final TextEditingController _nameController = TextEditingController();
  Future<QuerySnapshot>? _rankingFuture;
  // ✨ --- ここまで ---

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_gameLoop)..start();
    _resetGame(isFirstTime: true);
  }

  void _gameLoop(Duration elapsed) {
    setState(() {
      timer += elapsed.inMilliseconds;

      if (_gameState == GameState.countdown) {
        if (timer > 4500) {
          _gameState = GameState.playing;
          timer = 0;
        }
      }

      if (_gameState == GameState.playing) {
        vx *= 0.99;
        x += vx;

        if (x > (screenWidth / 2 - 150)) {
          nowX += x - (screenWidth / 2 - 150);
          x = screenWidth / 2 - 150;
        }

        vy += gravity;
        y += vy;

        if ((y + ballRadius > screenHeight)) {
          y = screenHeight - ballRadius;
          vy *= -elasticity;
        }
        if ((screenHeight - y - ballRadius).abs() < 0.5) {
          vx *= 0.9;
        }

        if (nowX > goalLine) {
          _gameState = GameState.goal;
          goalTime = 5 * timer/10000000;
          timer = 0;
        }

        for (final obsX in obstacles) {
          final double obstacleScreenX = obsX - nowX + 230;
          final double obstacleScreenY = screenHeight - 30;
          final distanceSq = pow(x - obstacleScreenX, 2) + pow(y - obstacleScreenY, 2);
          if (distanceSq < pow(ballRadius + 30, 2)) {
            _gameState = GameState.gameOver;
            timer = 0;
            break;
          }
        }
      }

      if (_gameState == GameState.gameOver) {
        if (timer < 5000) {
          effectPos += 5;
        }
      }
    });
  }
  
  void _resetGame({bool isFirstTime = false}) {
    setState(() {
      x = 50;
      y = 200;
      vx = 5;
      vy = 0.6;
      nowX = 0;
      timer = 0;
      effectPos = 0;

      _nameController.clear();
      _rankingFuture = null; // データリセット
      
      if (isFirstTime) {
        obstacles.clear();
        final random = Random();
        for (int i = 0; i < 10; i++) {
          final base = 1000 * (i + 1);
          final rand = base + (random.nextDouble() * 400 - 200);
          obstacles.add(rand);
        }
      }
    });
  }

  void _handleTap() {
    setState(() {
      if (_gameState == GameState.startScreen) {
        _gameState = GameState.countdown;
        timer = 0;
      } else if (_gameState == GameState.playing) {
        final bool isNearFloor = (screenHeight - y - ballRadius).abs() < 100.0;
        if (isNearFloor) {
          vx = 15;
          vy = -20;
        }
      }
    });
  }
  
  void _onRestartPressed() {
    _resetGame();
    setState(() {
       _gameState = GameState.countdown;
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    //コントローラを捨てる
    _nameController.dispose();

    super.dispose();
  }

  // 入力を受ける
  Future<void> _registerAndShowRanking() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('名前を入力してください！')),
      );
      return;
    }
    // スコアを登録
    await FirebaseFirestore.instance.collection('ball_game_ranking').add({
      'name': _nameController.text,
      'score': goalTime, // 秒単位に変換
      'timestamp': FieldValue.serverTimestamp(),
    });
    // スコア登録後、ランキングデータを一度だけ取得
    setState(() {
      _rankingFuture = FirebaseFirestore.instance
          .collection('ball_game_ranking')
          .orderBy('score') // タイムが少ない順
          .limit(10)
          .get();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView( // ✨ 画面が溢れないようにスクロール可能にする
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _handleTap,
                child: CustomPaint(
                  size: Size(screenWidth, screenHeight),
                  painter: GamePainter(
                    gameState: _gameState,
                    x: x, y: y, vx: vx, vy: vy, // ✨ 元のコードに合わせて修正
                    nowX: nowX, timer: timer,
                    obstacles: obstacles,
                    goalTime: goalTime,
                    effectPos: effectPos,
                    goalLine: goalLine,
                    ballRadius: ballRadius,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // ✨ --- 元のリスタートボタンのロジックを、新しいUI構築関数に置き換え ---
              _buildStatusUI(),
            ],
          ),
        ),
      ),
    );
  }
  
  // UI
  Widget _buildStatusUI() {
    if (_gameState == GameState.gameOver) {
      return ElevatedButton(
        onPressed: _onRestartPressed,
        child: const Text('リスタート', style: TextStyle(fontSize: 20)),
      );
    }
    if (_gameState == GameState.goal) {
      // ランキングがまだ読み込まれていない場合 (名前入力画面)
      if (_rankingFuture == null) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: '名前を入力してスコア登録'),
                      autofocus: true,
                    ),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: _registerAndShowRanking,
                    child: const Text('登録'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
             // 登録前でもリスタートはできるようにしておく
            TextButton(
              onPressed: _onRestartPressed,
              child: const Text('リスタートする'),
            )
          ],
        );
      } 
      // リザルトとランキングの表示
      else {
        return Column(
          children: [
            const Text('🏆ランキング🏆', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(
              height: 250,
              child: FutureBuilder<QuerySnapshot>(
                future: _rankingFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Center(child: Text('エラーが発生しました'));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('ランキングデータがありません'));
                  }
                  final docs = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      return ListTile(
                        leading: Text('${index + 1}位', style: const TextStyle(fontWeight: FontWeight.bold)),
                        title: Text(data['name'] ?? '名無し'),
                        trailing: Text('${(data['score'] as num).toStringAsFixed(2)}秒'),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _onRestartPressed,
              child: const Text('もう一度プレイ', style: TextStyle(fontSize: 20)),
            ),
          ],
        );
      }
    }
    //プレイ中はもとに
    return const SizedBox(height: 48);
  }
}

// 描画を担当するクラス
class GamePainter extends CustomPainter {
  final GameState gameState;
  final double x, y, vx, vy, nowX, timer, goalTime, effectPos, goalLine, ballRadius;
  final List<double> obstacles;
  
  GamePainter({
    required this.gameState,
    required this.x, required this.y, required this.vx, required this.vy,
    required this.nowX, required this.timer,
    required this.obstacles,
    required this.goalTime, required this.effectPos,
    required this.goalLine, required this.ballRadius,
  });

  void _drawText(Canvas canvas, String text, Offset position, {double fontSize = 40, Color color = Colors.black, TextAlign textAlign = TextAlign.center}) {
    final textSpan = TextSpan(
      text: text,
      style: TextStyle(color: color, fontSize: fontSize, fontWeight: FontWeight.bold),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textAlign: textAlign,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(minWidth: 0, maxWidth: 720);
    final offset = Offset(position.dx - textPainter.width / 2, position.dy - textPainter.height / 2);
    textPainter.paint(canvas, offset);
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(Colors.white, BlendMode.src);

    final goalPaint = Paint()..color = Colors.red..strokeWidth = 4;
    canvas.drawLine(Offset(goalLine - nowX + 200, size.height), Offset(goalLine - nowX + 200, size.height - 200), goalPaint);

    switch (gameState) {
      case GameState.startScreen:
        _drawText(canvas, "左クリックでスタート", Offset(size.width / 2, size.height / 2));
        break;

      case GameState.countdown:
        if (timer > 4000) {
          _drawText(canvas, "GO!!!", Offset(size.width / 2, size.height / 2), fontSize: 60);
        } else {
          _drawText(canvas, "障害物をよけてボールを運ぼう！", Offset(size.width / 2, 100));
          _drawText(canvas, (5 - timer / 1000).floor().toString(), Offset(size.width / 2, size.height / 2), fontSize: 60);
          _drawText(canvas, "左クリックでボールを打ち付けるよ", Offset(size.width / 2, 250), fontSize: 30);
        }
        break;

      case GameState.playing:
        final bool isNearFloor = (size.height - y - ballRadius).abs() < 100.0;
        final ballPaint = Paint()..color = (isNearFloor) ? const Color.fromARGB(255, 255, 255, 0) : const Color.fromARGB(255, 0, 255, 0);
        canvas.drawCircle(Offset(x, y), ballRadius, ballPaint);
        
        _drawText(canvas, (5 * timer / 10000000).toStringAsFixed(1), const Offset(40, 20), fontSize: 24, textAlign: TextAlign.left);

        final obstaclePaint = Paint()..color = const Color.fromARGB(255, 200, 100, 0);
        for (final obsX in obstacles) {
          canvas.drawRect(Rect.fromLTWH(obsX - nowX + 200, size.height - 60, 60, 60), obstaclePaint);
        }
        break;

      case GameState.gameOver:
        final effectPaint = Paint()..color = Colors.red;
        canvas.drawRect(Rect.fromCenter(center: Offset(x + effectPos, y + effectPos), width: 20, height: 20), effectPaint);
        canvas.drawRect(Rect.fromCenter(center: Offset(x - effectPos, y + effectPos), width: 20, height: 20), effectPaint);
        canvas.drawRect(Rect.fromCenter(center: Offset(x + effectPos, y - effectPos), width: 20, height: 20), effectPaint);
        canvas.drawRect(Rect.fromCenter(center: Offset(x - effectPos, y - effectPos), width: 20, height: 20), effectPaint);
        
        _drawText(canvas, "ゲームオーバー", Offset(size.width / 2, size.height / 2), fontSize: 60);
        break;
      
      case GameState.goal:
        if (timer < 2000) {
           _drawText(canvas, "ゴール！", Offset(size.width / 2, size.height / 2), fontSize: 60);
        } else {
           final results = ["Perfect!!!!", "Excellent!!!", "Great!!", "Nice!", "Good"];
           int rank = 4;
           if (goalTime < 15) rank = 0;
           else if (goalTime < 20) rank = 1;
           else if (goalTime < 25) rank = 2;
           else if (goalTime < 35) rank = 3;
           
           _drawText(canvas, "タイム: ${goalTime.toStringAsFixed(1)} s", Offset(size.width / 2, 180));
           _drawText(canvas, results[rank], Offset(size.width / 2, 250));
        }
        break;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}