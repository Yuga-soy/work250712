import 'dart:async'; // 非同期処理(時間ごとでの移動等)に必要
import 'dart:math'; //数学的な関数や機能が使える。今回はRandomに必要
import 'package:flutter/material.dart'; // FlutterのWightを使うために必要
import 'package:flutter/services.dart'; // キーボード入力に必要なパッケージ


//メインでMyAppを1回呼び出す
void main() {
  runApp(const MyApp());
}

// 静的な状態のクラス(今回の大本)
class MyApp extends StatelessWidget {
  const MyApp({super.key});//今後インスタント(オブジェクト等)を生成するためのコンストラクト(生成子)の定義

  // これから構築するWidgetの基本構造の定義
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: TetrisGame(),
    );
  }
}

//マス目数
const int ROW_COUNT = 20;
const int COL_COUNT = 10;

//ミノの形状から列挙型で定義
enum Tetromino { I, L, J, O, S, Z, T }

//各種形状と色の設定
const Map<Tetromino, List<List<int>>> tetrominoShapes = {
  Tetromino.I: [ [1, 1, 1, 1] ],
  Tetromino.L: [ [0, 0, 1], [1, 1, 1] ],
  Tetromino.J: [ [1, 0, 0], [1, 1, 1] ],
  Tetromino.O: [ [1, 1], [1, 1] ],
  Tetromino.S: [ [0, 1, 1], [1, 1, 0] ],
  Tetromino.Z: [ [1, 1, 0], [0, 1, 1] ],
  Tetromino.T: [ [0, 1, 0], [1, 1, 1] ],
};

const Map<Tetromino, Color> tetrominoColors = {
  Tetromino.I: Colors.cyan,
  Tetromino.L: Colors.orange,
  Tetromino.J: Colors.blue,
  Tetromino.O: Colors.yellow,
  Tetromino.S: Colors.green,
  Tetromino.T: Colors.purple,
  Tetromino.Z: Colors.red,
};

// Tetrisゲームのメインウィジェット
class TetrisGame extends StatefulWidget {
  const TetrisGame({super.key});

// このウィジェットの状態を管理するStateクラスを作成、次のexetends State~もセットで必要
  @override
  State<TetrisGame> createState() => _TetrisGameState();
}

class _TetrisGameState extends State<TetrisGame> {
  final FocusNode _focusNode = FocusNode(); // キーボード入力を受け取るためのFocusNode
  late List<List<Tetromino?>> gameBoard; // テトロミノのゲームボードを表す2次元リスト
  late Tetromino currentTetromino;
  late Tetromino nextTetromino;
  late List<List<int>> currentShape;
  late List<int> currentPosition;

  int score = 0;
  bool isGameOver = false;
  Timer? gameLoop;

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
    startGame();
  }

  @override
  void dispose() {
    gameLoop?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  void startGame() {
    gameBoard = List.generate(
      ROW_COUNT,
      (r) => List.generate(COL_COUNT, (c) => null),
    );//ボードの初期化

    isGameOver = false;
    score = 0;

    currentTetromino = _getRandomPiece();
    nextTetromino = _getRandomPiece();
    
    currentShape = tetrominoShapes[currentTetromino]!;
    currentPosition = [0, (COL_COUNT / 2).floor() - (currentShape[0].length / 2).floor()];

    gameLoop?.cancel();
    gameLoop = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!isGameOver) {
        moveDown();
      }
    });
  }
  
  Tetromino _getRandomPiece() {
    final random = Random();
    return Tetromino.values[random.nextInt(Tetromino.values.length)];
  }

  void createNewPiece() {
    currentTetromino = nextTetromino;
    nextTetromino = _getRandomPiece();

    currentShape = tetrominoShapes[currentTetromino]!;
    currentPosition = [0, (COL_COUNT / 2).floor() - (currentShape[0].length / 2).floor()];

    if (checkCollision(currentPosition, currentShape)) {
      setState(() {
        isGameOver = true;
        gameLoop?.cancel();
      });
    }
  }

  bool checkCollision(List<int> position, List<List<int>> shape) {
    for (int r = 0; r < shape.length; r++) {
      for (int c = 0; c < shape[r].length; c++) {
        if (shape[r][c] == 1) {
          int boardRow = position[0] + r;
          int boardCol = position[1] + c;

          if (boardCol < 0 || boardCol >= COL_COUNT || boardRow >= ROW_COUNT) {
            return true;
          }

          if (boardRow >= 0 && gameBoard[boardRow][boardCol] != null) {
            return true;
          }
        }
      }
    }
    return false;
  }

  //moveDownは落下, moveLeft, moveRightは左右移動, rotateは回転とその判断(別の関数も使う)
  void moveDown() {
    if (isGameOver) return;
    final newPosition = [currentPosition[0] + 1, currentPosition[1]];
    if (!checkCollision(newPosition, currentShape)) {
      setState(() {
        currentPosition = newPosition;
      });
    } else {
      landPiece();
    }
  }

  void moveLeft() {
    if (isGameOver) return;
    final newPosition = [currentPosition[0], currentPosition[1] - 1];
    if (!checkCollision(newPosition, currentShape)) {
      setState(() {
        currentPosition = newPosition;
      });
    }
  }

  void moveRight() {
    if (isGameOver) return;
    final newPosition = [currentPosition[0], currentPosition[1] + 1];
    if (!checkCollision(newPosition, currentShape)) {
      setState(() {
        currentPosition = newPosition;
      });
    }
  }

  void rotate() {
    if (isGameOver) return;
    final List<List<int>> newShape = List.generate(
      currentShape[0].length,
      (r) => List.generate(currentShape.length, (c) => 0),
    );

    for (int r = 0; r < currentShape.length; r++) {
      for (int c = 0; c < currentShape[r].length; c++) {
        newShape[c][currentShape.length - 1 - r] = currentShape[r][c];
      }
    }

    if (!checkCollision(currentPosition, newShape)) {
      setState(() {
        currentShape = newShape;
      });
    }
  }

  void landPiece() {
    for (int r = 0; r < currentShape.length; r++) {
      for (int c = 0; c < currentShape[r].length; c++) {
        if (currentShape[r][c] == 1) {
          int boardRow = currentPosition[0] + r;
          int boardCol = currentPosition[1] + c;
          if (boardRow >= 0) {
            gameBoard[boardRow][boardCol] = currentTetromino;
          }
        }
      }
    }
    clearLines();
    createNewPiece();
  }

  void clearLines() {
    int linesCleared = 0;
    for (int r = ROW_COUNT - 1; r >= 0; r--) {
      // ある行の要素の中にnullとなっているcellがないかチェック
      if (!gameBoard[r].any((cell) => cell == null)) {
        for (int rowToShift = r; rowToShift > 0; rowToShift--) {
          gameBoard[rowToShift] = List.from(gameBoard[rowToShift - 1]);
        }
        gameBoard[0] = List.generate(COL_COUNT, (c) => null);
        r++;
      }
    }

    if (linesCleared > 0) {
      setState(() {
        score += linesCleared * 100;
      });
    }
  }

  // ゲーム中のWighet
  @override
  Widget build(BuildContext context) {
    //　キーボード入力->更新のため全体をこれで囲む
    return RawKeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKey: (RawKeyEvent event) {
        if (event is RawKeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft || event.logicalKey == LogicalKeyboardKey.keyA) {
            moveLeft();
          } else if (event.logicalKey == LogicalKeyboardKey.arrowRight || event.logicalKey == LogicalKeyboardKey.keyD) {
            moveRight();
          } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            moveDown();
          } else if (event.logicalKey == LogicalKeyboardKey.keyR) {
            rotate();
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: COL_COUNT / ROW_COUNT,
                    child: GestureDetector(
                      onTap: rotate,
                      onSecondaryTap: moveDown,
                      onHorizontalDragEnd: (details) {
                        if (details.primaryVelocity! > 0) {
                          moveRight();
                        } else if (details.primaryVelocity! < 0) {
                          moveLeft();
                        }
                      },
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: ROW_COUNT * COL_COUNT,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: COL_COUNT,
                        ),
                        itemBuilder: (context, index) {
                          int row = index ~/ COL_COUNT;
                          int col = index % COL_COUNT;

                          Color? cellColor = gameBoard[row][col] != null
                              ? tetrominoColors[gameBoard[row][col]]
                              : Colors.grey[900];

                          for (int r = 0; r < currentShape.length; r++) {
                            for (int c = 0; c < currentShape[r].length; c++) {
                              if (currentShape[r][c] == 1 &&
                                  currentPosition[0] + r == row &&
                                  currentPosition[1] + c == col) {
                                cellColor = tetrominoColors[currentTetromino];
                              }
                            }
                          }

                          return Container(
                            margin: const EdgeInsets.all(1),
                            decoration: BoxDecoration(
                              color: cellColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 20),
                    Text(
                      'Score: $score',
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 30),
                    const Text('Next', style: TextStyle(color: Colors.white, fontSize: 18)),
                    const SizedBox(height: 10),
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: 16,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                        ),
                        itemBuilder: (context, index) {
                          int row = index ~/ 4;
                          int col = index % 4;
                          final shape = tetrominoShapes[nextTetromino]!;

                          double offsetX = (4 - shape[0].length) / 2;
                          double offsetY = (4 - shape.length) / 2;

                          if (row >= offsetY && row < shape.length + offsetY &&
                              col >= offsetX && col < shape[0].length + offsetX) {
                            if (shape[(row - offsetY).floor()][(col - offsetX).floor()] == 1) {
                              return Container(
                                margin: const EdgeInsets.all(1),
                                decoration: BoxDecoration(
                                  color: tetrominoColors[nextTetromino],
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              );
                            }
                          }
                          return Container();
                        },
                      ),
                    ),
                    if (isGameOver)
                      Padding(
                        padding: const EdgeInsets.only(top: 40.0),
                        child: Center(
                          child: Column(
                            children: [
                              const Text('Game Over', style: TextStyle(color: Colors.red, fontSize: 24, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 10),
                              ElevatedButton(
                                onPressed: startGame,
                                child: const Text('Restart'),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}