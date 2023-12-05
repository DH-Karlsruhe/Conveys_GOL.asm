# Conveys_GOL.asm
Assembly Implementierung des Conveys Spiel des Lebens in der Vorlesung: "systemnahe Programmierung".


## Schematischer Programmablauf

```

1. start

2.calc next gen:
    2.1 initialize row and column counter as 0x7h
    2.2 check neighbour and write control value

3. write next gen:
    3.1 iterate over lines
    3.2 iterate over columns
    3.3 neighbors = 3 -> set cell to 1
    3.4 neighbors < 2 -> set cell to 0
    3.5 2<=neighbors<=3 && cell alive -> set cell to 1
    3.6 neighbors >= 4 -> set cell to 0

goto 2

```

## Cheat-Sheet

https://www.win.tue.nl/~aeb/comp/8051/set8051.html#51pop
mit Beispielen..  
https://www.engineersgarage.com/8051-instruction-set/
