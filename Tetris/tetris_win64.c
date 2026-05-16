#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#define BOARD_W 10
#define BOARD_H 20
#define SCREEN_W 80
#define SCREEN_H 30
#define CELL_W 2

typedef struct {
    int x;
    int y;
} Point;

typedef struct {
    int type;
    int rotation;
    int x;
    int y;
} Piece;

typedef struct {
    int board[BOARD_H][BOARD_W];
    Piece current;
    Piece next;
    int score;
    int lines;
    int level;
    int drop_ms;
    bool game_over;
    bool paused;
} Game;

static const Point SHAPES[7][4][4] = {
    {{{0,1},{1,1},{2,1},{3,1}}, {{2,0},{2,1},{2,2},{2,3}}, {{0,2},{1,2},{2,2},{3,2}}, {{1,0},{1,1},{1,2},{1,3}}},
    {{{1,0},{2,0},{1,1},{2,1}}, {{1,0},{2,0},{1,1},{2,1}}, {{1,0},{2,0},{1,1},{2,1}}, {{1,0},{2,0},{1,1},{2,1}}},
    {{{1,0},{0,1},{1,1},{2,1}}, {{1,0},{1,1},{2,1},{1,2}}, {{0,1},{1,1},{2,1},{1,2}}, {{1,0},{0,1},{1,1},{1,2}}},
    {{{1,0},{2,0},{0,1},{1,1}}, {{1,0},{1,1},{2,1},{2,2}}, {{1,1},{2,1},{0,2},{1,2}}, {{0,0},{0,1},{1,1},{1,2}}},
    {{{0,0},{1,0},{1,1},{2,1}}, {{2,0},{1,1},{2,1},{1,2}}, {{0,1},{1,1},{1,2},{2,2}}, {{1,0},{0,1},{1,1},{0,2}}},
    {{{0,0},{0,1},{1,1},{2,1}}, {{1,0},{2,0},{1,1},{1,2}}, {{0,1},{1,1},{2,1},{2,2}}, {{1,0},{1,1},{0,2},{1,2}}},
    {{{2,0},{0,1},{1,1},{2,1}}, {{1,0},{1,1},{1,2},{2,2}}, {{0,1},{1,1},{2,1},{0,2}}, {{0,0},{1,0},{1,1},{1,2}}},
};

static HANDLE output_handle;
static char screen[SCREEN_H][SCREEN_W + 1];
static SHORT key_prev[256];

static int random_piece(void) {
    return rand() % 7;
}

static Piece make_piece(int type) {
    Piece p;
    p.type = type;
    p.rotation = 0;
    p.x = 3;
    p.y = -1;
    return p;
}

static bool key_pressed(int vk) {
    SHORT state = GetAsyncKeyState(vk);
    bool down = (state & 0x8000) != 0;
    bool was_down = (key_prev[vk] & 0x8000) != 0;
    key_prev[vk] = state;
    return down && !was_down;
}

static void clear_screen_buffer(void) {
    for (int y = 0; y < SCREEN_H; ++y) {
        memset(screen[y], ' ', SCREEN_W);
        screen[y][SCREEN_W] = '\0';
    }
}

static void put_text(int x, int y, const char *text) {
    if (y < 0 || y >= SCREEN_H || x >= SCREEN_W) {
        return;
    }
    int len = (int)strlen(text);
    for (int i = 0; i < len && x + i < SCREEN_W; ++i) {
        if (x + i >= 0) {
            screen[y][x + i] = text[i];
        }
    }
}

static void put_cell(int board_x, int board_y, int value) {
    int sx = 4 + board_x * CELL_W;
    int sy = 3 + board_y;
    if (sy < 0 || sy >= SCREEN_H || sx < 0 || sx + 1 >= SCREEN_W) {
        return;
    }
    if (value) {
        screen[sy][sx] = '[';
        screen[sy][sx + 1] = ']';
    } else {
        screen[sy][sx] = '.';
        screen[sy][sx + 1] = ' ';
    }
}

static bool collides(const Game *game, Piece piece) {
    for (int i = 0; i < 4; ++i) {
        int x = piece.x + SHAPES[piece.type][piece.rotation][i].x;
        int y = piece.y + SHAPES[piece.type][piece.rotation][i].y;

        if (x < 0 || x >= BOARD_W || y >= BOARD_H) {
            return true;
        }
        if (y >= 0 && game->board[y][x]) {
            return true;
        }
    }
    return false;
}

static void spawn_piece(Game *game) {
    game->current = game->next;
    game->current.x = 3;
    game->current.y = -1;
    game->current.rotation = 0;
    game->next = make_piece(random_piece());
    if (collides(game, game->current)) {
        game->game_over = true;
    }
}

static void update_speed(Game *game) {
    game->level = game->lines / 10 + 1;
    game->drop_ms = 520 - (game->level - 1) * 38;
    if (game->drop_ms < 80) {
        game->drop_ms = 80;
    }
}

static void lock_piece(Game *game) {
    for (int i = 0; i < 4; ++i) {
        int x = game->current.x + SHAPES[game->current.type][game->current.rotation][i].x;
        int y = game->current.y + SHAPES[game->current.type][game->current.rotation][i].y;
        if (x >= 0 && x < BOARD_W && y >= 0 && y < BOARD_H) {
            game->board[y][x] = game->current.type + 1;
        }
    }

    int cleared = 0;
    for (int y = BOARD_H - 1; y >= 0; --y) {
        bool full = true;
        for (int x = 0; x < BOARD_W; ++x) {
            if (!game->board[y][x]) {
                full = false;
                break;
            }
        }

        if (full) {
            ++cleared;
            for (int row = y; row > 0; --row) {
                memcpy(game->board[row], game->board[row - 1], sizeof(game->board[row]));
            }
            memset(game->board[0], 0, sizeof(game->board[0]));
            ++y;
        }
    }

    if (cleared) {
        static const int line_scores[] = {0, 100, 300, 500, 800};
        game->score += line_scores[cleared] * game->level;
        game->lines += cleared;
        update_speed(game);
    }

    spawn_piece(game);
}

static bool move_piece(Game *game, int dx, int dy) {
    Piece moved = game->current;
    moved.x += dx;
    moved.y += dy;
    if (!collides(game, moved)) {
        game->current = moved;
        return true;
    }
    return false;
}

static void rotate_piece(Game *game) {
    Piece rotated = game->current;
    rotated.rotation = (rotated.rotation + 1) % 4;

    if (!collides(game, rotated)) {
        game->current = rotated;
        return;
    }

    rotated.x = game->current.x - 1;
    if (!collides(game, rotated)) {
        game->current = rotated;
        return;
    }

    rotated.x = game->current.x + 1;
    if (!collides(game, rotated)) {
        game->current = rotated;
    }
}

static void hard_drop(Game *game) {
    int distance = 0;
    while (move_piece(game, 0, 1)) {
        ++distance;
    }
    game->score += distance * 2;
    lock_piece(game);
}

static void init_game(Game *game) {
    memset(game, 0, sizeof(*game));
    game->next = make_piece(random_piece());
    game->score = 0;
    game->lines = 0;
    update_speed(game);
    spawn_piece(game);
}

static void draw_borders(void) {
    put_text(4, 2, "+--------------------+");
    for (int y = 0; y < BOARD_H; ++y) {
        put_text(4, 3 + y, "|");
        put_text(25, 3 + y, "|");
    }
    put_text(4, 23, "+--------------------+");
}

static void draw_piece_preview(const Piece *piece, int ox, int oy) {
    for (int i = 0; i < 4; ++i) {
        int x = ox + SHAPES[piece->type][0][i].x * CELL_W;
        int y = oy + SHAPES[piece->type][0][i].y;
        if (x >= 0 && x + 1 < SCREEN_W && y >= 0 && y < SCREEN_H) {
            screen[y][x] = '[';
            screen[y][x + 1] = ']';
        }
    }
}

static void render_game(const Game *game) {
    char line[64];

    clear_screen_buffer();
    put_text(4, 0, "TETRIS - Windows x64");
    draw_borders();

    for (int y = 0; y < BOARD_H; ++y) {
        for (int x = 0; x < BOARD_W; ++x) {
            put_cell(x, y, game->board[y][x]);
        }
    }

    for (int i = 0; i < 4; ++i) {
        int x = game->current.x + SHAPES[game->current.type][game->current.rotation][i].x;
        int y = game->current.y + SHAPES[game->current.type][game->current.rotation][i].y;
        if (y >= 0) {
            put_cell(x, y, game->current.type + 1);
        }
    }

    snprintf(line, sizeof(line), "Score: %d", game->score);
    put_text(32, 4, line);
    snprintf(line, sizeof(line), "Lines: %d", game->lines);
    put_text(32, 6, line);
    snprintf(line, sizeof(line), "Level: %d", game->level);
    put_text(32, 8, line);
    put_text(32, 11, "Next:");
    draw_piece_preview(&game->next, 32, 13);

    put_text(32, 19, "Arrows: move/rotate");
    put_text(32, 20, "Space: hard drop");
    put_text(32, 21, "P: pause");
    put_text(32, 22, "R: restart");
    put_text(32, 23, "Q/Esc: quit");

    if (game->paused) {
        put_text(10, 13, "PAUSED");
    }
    if (game->game_over) {
        put_text(9, 12, "GAME OVER");
        put_text(7, 14, "Press R to restart");
    }

    COORD pos = {0, 0};
    SetConsoleCursorPosition(output_handle, pos);
    for (int y = 0; y < SCREEN_H; ++y) {
        DWORD written;
        WriteConsoleA(output_handle, screen[y], SCREEN_W, &written, NULL);
        WriteConsoleA(output_handle, "\n", 1, &written, NULL);
    }
}

static void configure_console(void) {
    output_handle = GetStdHandle(STD_OUTPUT_HANDLE);

    CONSOLE_CURSOR_INFO cursor_info;
    cursor_info.dwSize = 1;
    cursor_info.bVisible = FALSE;
    SetConsoleCursorInfo(output_handle, &cursor_info);

    COORD size = {SCREEN_W, SCREEN_H + 1};
    SMALL_RECT rect = {0, 0, SCREEN_W - 1, SCREEN_H};
    SetConsoleScreenBufferSize(output_handle, size);
    SetConsoleWindowInfo(output_handle, TRUE, &rect);

    SetConsoleTitleA("Tetris - Windows x64");
}

int main(void) {
    srand((unsigned int)time(NULL));
    configure_console();

    Game game;
    init_game(&game);

    DWORD last_drop = GetTickCount();
    bool running = true;

    while (running) {
        DWORD now = GetTickCount();

        if (key_pressed(VK_ESCAPE) || key_pressed('Q')) {
            running = false;
        }
        if (key_pressed('R')) {
            init_game(&game);
            last_drop = now;
        }
        if (key_pressed('P')) {
            game.paused = !game.paused;
        }

        if (!game.paused && !game.game_over) {
            if (key_pressed(VK_LEFT)) {
                move_piece(&game, -1, 0);
            }
            if (key_pressed(VK_RIGHT)) {
                move_piece(&game, 1, 0);
            }
            if (key_pressed(VK_UP)) {
                rotate_piece(&game);
            }
            if (key_pressed(VK_DOWN)) {
                if (move_piece(&game, 0, 1)) {
                    game.score += 1;
                }
                last_drop = now;
            }
            if (key_pressed(VK_SPACE)) {
                hard_drop(&game);
                last_drop = now;
            }

            if ((int)(now - last_drop) >= game.drop_ms) {
                if (!move_piece(&game, 0, 1)) {
                    lock_piece(&game);
                }
                last_drop = now;
            }
        }

        render_game(&game);
        Sleep(16);
    }

    return 0;
}
