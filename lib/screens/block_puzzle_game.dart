import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/ad_service.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

// --- SHAPES DEFINITION ---
final List<List<List<int>>> _allShapes = [
  // 1x1
  [[1]],
  // 2x2
  [[1, 1], [1, 1]],
  // 3x3 square
  [[1, 1, 1], [1, 1, 1], [1, 1, 1]],
  // Horizontal line 2
  [[1, 1]],
  // Horizontal line 3
  [[1, 1, 1]],
  // Horizontal line 4
  [[1, 1, 1, 1]],
  // Vertical line 2
  [[1], [1]],
  // Vertical line 3
  [[1], [1], [1]],
  // Vertical line 4
  [[1], [1], [1], [1]],
  // L shape
  [[1, 0], [1, 1]],
  // L shape rotated
  [[0, 1], [1, 1]],
  // L shape 3x3
  [[1, 0, 0], [1, 0, 0], [1, 1, 1]],
];

class BlockPuzzleGame extends StatefulWidget {
  final ApiService api;
  final String? token;

  const BlockPuzzleGame({super.key, required this.api, this.token});

  @override
  State<BlockPuzzleGame> createState() => _BlockPuzzleGameState();
}

class _BlockPuzzleGameState extends State<BlockPuzzleGame> {
  static const int gridSize = 10;
  List<List<int>> _grid = List.generate(gridSize, (_) => List.generate(gridSize, (_) => 0));
  List<List<List<int>>?> _hand = [null, null, null];
  
  int _score = 0;
  int _coinsEarned = 0;
  int _maxCoinsAllowed = 200;
  bool _isGameOver = false;

  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;

  @override
  void initState() {
    super.initState();
    _fillHand();
    _loadAds();
  }

  void _loadAds() {
    _bannerAd = BannerAd(
      adUnitId: AdService.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _isBannerLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    )..load();

    AdService.loadInterstitialAd((ad) {
      _interstitialAd = ad;
    });

    AdService.loadRewardedAd((ad) {
      _rewardedAd = ad;
    });
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    super.dispose();
  }

  void _fillHand() {
    final rand = Random();
    bool allNull = true;
    for (int i = 0; i < 3; i++) {
      if (_hand[i] != null) allNull = false;
    }

    if (allNull) {
      setState(() {
        for (int i = 0; i < 3; i++) {
          _hand[i] = _allShapes[rand.nextInt(_allShapes.length)];
        }
      });
      _checkGameOver();
    }
  }

  bool _canPlace(List<List<int>> shape, int row, int col) {
    for (int r = 0; r < shape.length; r++) {
      for (int c = 0; c < shape[r].length; c++) {
        if (shape[r][c] == 1) {
          if (row + r >= gridSize || col + c >= gridSize) return false;
          if (_grid[row + r][col + c] == 1) return false;
        }
      }
    }
    return true;
  }

  void _placeShape(int handIndex, List<List<int>> shape, int row, int col) {
    setState(() {
      for (int r = 0; r < shape.length; r++) {
        for (int c = 0; c < shape[r].length; c++) {
          if (shape[r][c] == 1) {
            _grid[row + r][col + c] = 1;
          }
        }
      }
      _score += _countBlocks(shape) * 10;
      _hand[handIndex] = null;
    });

    _clearLines();
    _fillHand();
    _checkGameOver();
  }

  int _countBlocks(List<List<int>> shape) {
    int count = 0;
    for (var r in shape) {
      for (var c in r) {
        if (c == 1) count++;
      }
    }
    return count;
  }

  void _clearLines() {
    List<int> rowsToClear = [];
    List<int> colsToClear = [];

    // Check rows
    for (int r = 0; r < gridSize; r++) {
      bool full = true;
      for (int c = 0; c < gridSize; c++) {
        if (_grid[r][c] == 0) {
          full = false;
          break;
        }
      }
      if (full) rowsToClear.add(r);
    }

    // Check cols
    for (int c = 0; c < gridSize; c++) {
      bool full = true;
      for (int r = 0; r < gridSize; r++) {
        if (_grid[r][c] == 0) {
          full = false;
          break;
        }
      }
      if (full) colsToClear.add(c);
    }

    if (rowsToClear.isEmpty && colsToClear.isEmpty) return;

    setState(() {
      for (int r in rowsToClear) {
        for (int c = 0; c < gridSize; c++) {
          _grid[r][c] = 0;
        }
      }
      for (int c in colsToClear) {
        for (int r = 0; r < gridSize; r++) {
          _grid[r][c] = 0;
        }
      }

      int linesCleared = rowsToClear.length + colsToClear.length;
      _score += linesCleared * 100;
      
      int coinsToAdd = linesCleared * 5;
      if (linesCleared > 1) {
        coinsToAdd += (linesCleared * 10); // Combo bonus
      }

      if (_coinsEarned + coinsToAdd <= _maxCoinsAllowed) {
        _coinsEarned += coinsToAdd;
      } else {
        _coinsEarned = _maxCoinsAllowed;
      }
    });
  }

  void _checkGameOver() {
    bool canPlay = false;
    for (var shape in _hand) {
      if (shape != null) {
        for (int r = 0; r < gridSize; r++) {
          for (int c = 0; c < gridSize; c++) {
            if (_canPlace(shape, r, c)) {
              canPlay = true;
              break;
            }
          }
          if (canPlay) break;
        }
      }
      if (canPlay) break;
    }

    if (!canPlay && !_isGameOver) {
      setState(() {
        _isGameOver = true;
      });
      _onGameOver();
    }
  }

  Future<void> _onGameOver() async {
    // Show Interstitial Ad occasionally
    if (_interstitialAd != null && Random().nextBool()) {
      _interstitialAd!.show();
    }

    // Sync score to backend
    if (widget.token != null && _score > 0) {
      try {
        await widget.api.postJson(
          '/game/reward',
          {
            'game': 'block_puzzle',
            'score': _score.toString(),
            'coins': _coinsEarned.toString(),
          },
          token: widget.token,
        );
      } catch (e) {
        debugPrint('Failed to sync game score: $e');
      }
    }

    _showGameOverDialog();
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Game Over', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Score: $_score', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Coins Earned: $_coinsEarned', style: const TextStyle(fontSize: 16, color: AppColors.brandOrange)),
            const SizedBox(height: 24),
            if (_rewardedAd != null)
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _rewardedAd!.show(onUserEarnedReward: (ad, reward) async {
                    setState(() {
                      _coinsEarned *= 2;
                    });
                    if (widget.token != null) {
                      await widget.api.postJson(
                        '/game/reward',
                        {
                          'game': 'block_puzzle_double',
                          'score': '0',
                          'coins': (_coinsEarned / 2).toString(), // Add the doubled half
                        },
                        token: widget.token,
                      );
                    }
                    _showGameOverDialog(); // Re-show to allow reset
                  });
                },
                icon: const Icon(Icons.ondemand_video),
                label: const Text('Watch Ad to Double Coins'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandOrange, foregroundColor: Colors.white),
              ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _resetGame();
              },
              child: const Text('Play Again'),
            ),
          ],
        ),
      ),
    );
  }

  void _resetGame() {
    setState(() {
      _grid = List.generate(gridSize, (_) => List.generate(gridSize, (_) => 0));
      _hand = [null, null, null];
      _score = 0;
      _coinsEarned = 0;
      _isGameOver = false;
      _fillHand();
    });
    _loadAds(); // Reload ads for next game over
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Slate 900
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Block Puzzle', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.brandOrange.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.brandOrange.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.monetization_on, color: AppColors.brandOrange, size: 18),
                const SizedBox(width: 6),
                Text(
                  '$_coinsEarned',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              children: [
                const Text('SCORE', style: TextStyle(fontSize: 12, letterSpacing: 2, color: Colors.white54)),
                const SizedBox(height: 4),
                Text(
                  '$_score',
                  style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: Colors.white),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B), // Slate 800
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      )
                    ],
                  ),
                  padding: const EdgeInsets.all(8),
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: gridSize * gridSize,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: gridSize,
                    ),
                    itemBuilder: (context, index) {
                      int row = index ~/ gridSize;
                      int col = index % gridSize;
                      return DragTarget<Map<String, dynamic>>(
                        builder: (context, candidateData, rejectedData) {
                          bool isHovering = candidateData.isNotEmpty;
                          bool canDrop = false;
                          if (isHovering) {
                            canDrop = _canPlace(candidateData.first?['shape'], row, col);
                          }

                          Color cellColor = _grid[row][col] == 1 
                              ? AppColors.brandOrange 
                              : (isHovering && canDrop ? AppColors.brandOrange.withValues(alpha: 0.3) : const Color(0xFF334155));

                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                            margin: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              gradient: _grid[row][col] == 1 
                                  ? const LinearGradient(
                                      colors: [AppColors.brandOrange, Colors.deepOrange],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ) 
                                  : null,
                              color: _grid[row][col] == 1 ? null : cellColor,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: _grid[row][col] == 1 
                                    ? Colors.deepOrangeAccent 
                                    : (isHovering && canDrop ? AppColors.brandOrange : Colors.transparent),
                                width: 1,
                              ),
                              boxShadow: _grid[row][col] == 1
                                  ? [
                                      BoxShadow(
                                        color: AppColors.brandOrange.withValues(alpha: 0.5),
                                        blurRadius: 6,
                                        offset: const Offset(2, 2),
                                      )
                                    ]
                                  : null,
                            ),
                          );
                        },
                        onWillAcceptWithDetails: (details) {
                          return _canPlace(details.data['shape'], row, col);
                        },
                        onAcceptWithDetails: (details) {
                          _placeShape(details.data['index'], details.data['shape'], row, col);
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          Container(
            height: 140,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B).withValues(alpha: 0.9), // Dark transparent tray
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
              border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(3, (index) {
                final shape = _hand[index];
                if (shape == null) return const SizedBox(width: 80, height: 80);

                return Draggable<Map<String, dynamic>>(
                  data: {'index': index, 'shape': shape},
                  feedback: Material(
                    color: Colors.transparent,
                    child: Transform.scale(
                      scale: 1.2,
                      child: _buildShapeWidget(shape, cellSize: 26.0, opacity: 0.9),
                    ),
                  ),
                  childWhenDragging: Opacity(
                    opacity: 0.2,
                    child: _buildShapeWidget(shape, cellSize: 22.0),
                  ),
                  child: _buildShapeWidget(shape, cellSize: 22.0),
                );
              }),
            ),
          ),
          if (_isBannerLoaded && _bannerAd != null)
            Container(
              alignment: Alignment.center,
              width: _bannerAd!.size.width.toDouble(),
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            )
          else
            const SizedBox(height: 50), // Banner placeholder
        ],
      ),
    );
  }

  Widget _buildShapeWidget(List<List<int>> shape, {double opacity = 1.0, double cellSize = 20.0}) {
    int rows = shape.length;
    int cols = shape[0].length;

    return Opacity(
      opacity: opacity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(rows, (r) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(cols, (c) {
              bool isFilled = shape[r][c] == 1;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: cellSize,
                height: cellSize,
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  gradient: isFilled 
                      ? const LinearGradient(
                          colors: [AppColors.brandOrange, Colors.deepOrange],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  borderRadius: BorderRadius.circular(5),
                  border: isFilled ? Border.all(color: Colors.deepOrangeAccent, width: 1) : null,
                  boxShadow: isFilled
                      ? [
                          BoxShadow(
                            color: AppColors.brandOrange.withValues(alpha: 0.5),
                            blurRadius: 4,
                            offset: const Offset(1, 1),
                          )
                        ]
                      : null,
                ),
              );
            }),
          );
        }),
      ),
    );
  }
}
