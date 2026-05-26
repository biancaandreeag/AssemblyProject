> _Academic project developed as part of a university course._
# Encrypt & Encode — 8086 Assembly (DOS)

Program scris în assembly 8086 (TASM / MASM, `.MODEL SMALL`) care:
1. citește un mesaj din `in/in.txt`,
2. îl criptează printr-un **stream cipher** bazat pe un PRNG congruențial liniar inițializat din ora sistemului,
3. encodează rezultatul cu un **alfabet de tip Base64 personalizat**,
4. scrie totul (parametri PRNG + mesaj criptat + text encodat) în `out/out.txt`.

## Fluxul programului

```
in/in.txt ──► FILE_INPUT ──► CREATEAB ──► SEED ──► ENCRYPT ──► ENCODE ──► WRITE ──► out/out.txt
```

## Date (`.DATA`)

| Variabilă       | Rol                                                                 |
| --------------- | ------------------------------------------------------------------- |
| `encoded`       | Buffer 80 B pentru rezultatul encodat                               |
| `temp`          | Buffer pentru afișarea în hex                                       |
| `filename`      | Calea fișierului de intrare (`in/in.txt`)                           |
| `outfile`       | Calea fișierului de ieșire (`out/out.txt`)                          |
| `message`       | Bufferul cu mesajul citit                                           |
| `msglen`        | Numărul de octeți citiți                                            |
| `x`, `x0`       | Starea curentă / inițială a PRNG                                    |
| `a`, `b`        | Coeficienții LCG (calculați din nume și prenume)                    |
| `surname`       | Numele studentului (pentru `b`)                                     |
| `firstname`     | Prenumele studentului (pentru `a`)                                  |
| `seconds`, `hseconds` | Componentele de timp folosite la seed                         |
| `alfabet`       | Alfabetul Base64 personalizat (64 caractere)                        |
| `paddingCh`     | Caracterul de padding (`+`)                                         |
| `padding`       | Numărul de paddinguri necesare la final                             |
| `iterations`    | Cursor în `encoded`                                                 |

## Proceduri

### `FILE_INPUT`
Deschide `in/in.txt` (`INT 21H`, `AH=3Dh`, `AL=0`), citește maxim 80 de octeți în `message` (`AH=3Fh`), apoi închide handler-ul (`AH=3Eh`).

### `CREATEAB`
Calculează coeficienții LCG:
- `a = (sumă octeți din firstname) mod 255`
- `b = (sumă octeți din surname) mod 255`

Sumele se opresc la `0` (firstname) respectiv `' '` / `20h` (surname).

### `SEED`
Citește ora sistemului (`INT 21H`, `AH=2Ch`):
- `CH` = ore, `CL` = minute, `DH` = secunde, `DL` = sutimi de secundă

și calculează seed-ul:
```
x0 = ((60 * (60 * ore + minute) + secunde) * 100 + sutimi) mod 255
```
Valoarea este salvată în `x0` și în `x`.

### `ENCRYPT`
Pentru fiecare octet din `message`:
```
message[i] = message[i] XOR x_low
x = (x * a + b) mod 255    ; via RAND
```

### `RAND`
Generatorul congruențial liniar: `x = (x * a + b) mod 255`.

### `ENCODE`
Encodare de tip Base64 (3 octeți → 4 caractere) folosind `alfabet`:

| Caz       | Octeți rămași | Padding aplicat |
| --------- | :-----------: | :-------------: |
| Normal    |       3       |        0        |
| `CASE2`   |       2       |        1 × `+`  |
| `CASE1`   |       1       |        2 × `+`  |

`ADDCH` adaugă alfabet[BX] în `encoded` la poziția `iterations`, iar `ADDPADDING` umple coada cu `paddingCh`.

### `WRITE_HEX`
Convertește `CX` octeți de la `[SI]` în reprezentare hex ASCII în bufferul `temp` (prefixat cu `0x`), încheiat cu newline (`0Ah`).

### `WRITE`
Scrie în `out/out.txt`, în această ordine:
1. `x0` în hex (4 cifre)
2. `a` în hex (4 cifre)
3. `b` în hex (4 cifre)
4. `x` în hex (4 cifre, starea finală)
5. `message` (criptat) în hex
6. `encoded` (raw text)

Apoi închide fișierul (`INT 21H`, `AH=3Eh`).

## Prerechizite

- DOS (sau **DOSBox**)
- Asamblor & linker: **TASM + TLINK** sau **MASM + LINK**
- Trebuie să existe:
  - fișierul de intrare `in/in.txt`
  - directorul de ieșire `out/`

## Build & rulare

```bash
tasm prog.asm
tlink prog.obj
prog.exe
```

sau cu MASM:

```bash
masm prog.asm;
link prog.obj;
prog.exe
```

## Output

Fișierul `out/out.txt` conține:
```
0xXXXX     ; x0
0xXXXX     ; a
0xXXXX     ; b
0xXXXX     ; x (starea finală)
0xXX 0xXX 0xXX ...  ; mesajul criptat în hex
<text encodat în alfabetul personalizat, cu padding '+'>
```
