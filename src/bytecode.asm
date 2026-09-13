# ============================================================
#  Nusa — Milestone 1: program uji bytecode (ditulis tangan)
#  ------------------------------------------------------------
#  Program sementara yang mengeksekusi langsung sekumpulan
#  instruksi, dipakai untuk menguji mesin virtual sebelum
#  lexer dan parser selesai (M2/M3).
#
#  Program ini akan mencetak:
#      10
#      33
#      -8
# ============================================================

.intel_syntax noprefix

.section .data
.globl program
program:
    .byte OP_DORONG_K, 10, 0, 0, 0    # dorong konstanta 10
    .byte OP_BAKAWAN, 0, 1            # tulis(10)
    .byte OP_POP                       # buang hasil kosong
    .byte OP_DORONG_K, 33, 0, 0, 0    # dorong konstanta 33
    .byte OP_BAKAWAN, 0, 1            # tulis(33)
    .byte OP_POP
    .byte OP_DORONG_K, 248, 255, 255, 255   # dorong konstanta -8
    .byte OP_BAKAWAN, 0, 1            # tulis(-8)
    .byte OP_POP
    .byte OP_HENTI                    # selesai
