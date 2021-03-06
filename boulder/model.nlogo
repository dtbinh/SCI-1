__includes ["IODA_2_3.nls"]

extensions [ioda]

breed [walls wall]
breed [heros hero]
breed [monsters monster]
breed [doors door]
breed [rocks rock]
breed [diamonds diamond]
breed [dirt]
breed [blast]
breed [magicwalls magicwall]
breed [amoebas amoeba]
breed [dynamite]

globals       [ score nb-to-collect countdown time amoebas-amout prev-amoebas-amout stagnation-count amoebas-stagnate? too-many-amoebas? ]
heros-own     [ moving? orders destructible? nb-dynamite ]
diamonds-own  [ moving? destructible? ]
monsters-own  [ moving? right-handed? destructible? ]
rocks-own     [ moving? destructible? ]
walls-own     [ destructible? ]
doors-own     [ open? destructible? ]
blast-own     [ strength diamond-maker? nbBlast destructible? ]
magicwalls-own [ destructible? ]
dirt-own      [ destructible? ]
dynamite-own  [ destructible? ]
amoebas-own   [ destructible? ]


to setup
  clear-all
  init-world
  ioda:load-interactions "interactions.txt"
  ioda:load-matrices "matrix.txt" " \t(),"
  ioda:setup
  ioda:set-metric "Moore"
  reset-ticks
  set time 0
end

to go
  ioda:go
  tick
  ifelse (not any? heros)
    [ ifelse (countdown = 0) [ user-message "GAME OVER !" stop ] [ set countdown countdown - 1 ]]
    [ if (all? heros [any? doors-here with [open?]])
        [ user-message "CONGRATULATIONS !" stop ]
    ]

end

to read-level [ filename ]
  file-open filename
  let s read-from-string file-read-line ; list with width and height
  resize-world 0 (first s - 1)  (1 - last s) 0
  let x 0 let y 0
  while [(y >= min-pycor) and (not file-at-end?)]
    [ set x 0
      set s file-read-line
      while [(x <= max-pxcor) and (x < length s)]
        [ ask patch x y [ create-agent (item x s) ]
          set x x + 1 ]
      set y y - 1 ]
  file-close
end

to create-agent [ char ]
  ifelse (char = "X")
    [ sprout-walls 1 [ init-wall false ] ]
    [ ifelse (char = "x")
        [ sprout-walls 1 [ init-wall true ] ]
        [ ifelse (char = "O")
            [ sprout-doors 1 [ init-door ]]
            [ ifelse (char = "H")
                [ sprout-heros 1 [ init-hero ]]
                [ ifelse (char = "D")
                    [ sprout-diamonds 1 [ init-diamond ]]
                    [ ifelse (char = "R")
                        [ sprout-rocks 1 [ init-rock ]]
                        [ ifelse (char = "M")
                            [ sprout-monsters 1 [ init-monster ]]
                            [ ifelse (char = ".")
                                [ sprout-dirt 1 [ init-dirt ] ]
                                [ ifelse (char = "m")
                                    [ sprout-magicwalls 1 [ init-magicwall ] ]
                                    [ ifelse (char = "A")
                                       [ sprout-amoebas 1 [ init-amoeba ] ]
                                       [
                                           ;;;;;; other agents ?
                                       ]
                                    ]
                                ]
                            ]
                        ]
                    ]
                ]
            ]
        ]
    ]
end

to init-world
  set-default-shape walls "tile brick"
  set-default-shape heros "person"
  set-default-shape monsters "ghost"
  set-default-shape doors "door-open"
  set-default-shape rocks "rock"
  set-default-shape diamonds "diamond"
  set-default-shape dirt "dirt"
  set-default-shape blast "star"
  set-default-shape magicwalls "tile brick"
  set-default-shape amoebas "tile log"
  read-level (word level ".txt")
  set countdown 0
  set nb-to-collect count diamonds
  set amoebas-amout 0
  set prev-amoebas-amout 0
  set amoebas-speed 10
  set stagnation-count 0
  set amoebas-stagnate? false
  set too-many-amoebas? false
end

to init-hero
  ioda:init-agent
  set heading 0
  set color red
  set moving? false
  set orders []
  set destructible? true
  set nb-dynamite ndynamite
end

to init-door
  ioda:init-agent
  set heading 0
  set color blue - 4
  set shape "tile brick"
  set open? false
  set destructible? false
end

to init-monster
  ioda:init-agent
  set heading 90 * random 4
  set color one-of (list blue yellow orange pink lime)
  set moving? true
  set right-handed? (random 2 = 0)
  if (right-handed?) [ set shape "butterfly" ]
  set destructible? true
end

to init-rock
  ioda:init-agent
  set color gray + 2
  set heading random 360
  set moving? false
  set destructible? true
end

to init-diamond
  ioda:init-agent
  set color cyan
  set heading 180
  set moving? false
  set destructible? true
end

to init-blast [ dm? str ]
  ioda:init-agent
  set color orange
  set strength str
  set diamond-maker? dm?
  set destructible? true
end

to init-dirt
  ioda:init-agent
  set color brown + 3
  set destructible? true
end

to init-wall [ d ]
  ioda:init-agent
  set destructible? d
  set heading 0
  set color blue - 4
end

to init-magicwall
  ioda:init-agent
  ; TODO: on ne peut pas marcher dessus, mais les rochers passent au travers
  set destructible? false
  set color orange
  set shape "tile brick"
end

to init-amoeba
  ioda:init-agent
  set color pink
  set shape "tile log"
  set destructible? true
  set prev-amoebas-amout amoebas-amout
  set amoebas-amout ( amoebas-amout + 1 )
  set stagnation-count 0
end

to init-dynamite
  ioda:init-agent
  set color red
  set shape "face sad"
  set destructible? true
end

; primitives that are shared by several breeds

to-report default::nothing-below?
  report not any? turtles-on patch-at 0 -1
end

to-report default::nothing-ahead? [d]
  report not any? turtles-on patch-ahead d
end

to-report default::obstacle-ahead? [d]
  report any? turtles-on patch-ahead d
end

to-report default::is-rock?
  report false
end

to-report default::moving?
  report moving?
end

to-report default::is-amoeba?
  report false
end

to default::start-moving
  set moving? true
end

to default::stop-moving
  set moving? false
end

to default::move-down
  move-to patch-at 0 -1
end

to default::move-forward
  move-to patch-ahead 1
end



; ========================
; blast-related primitives
; ========================
to blast::die
  ioda:die
end

to blast::create-diamond
  if diamond-maker?
  [ hatch-diamonds 1 [init-diamond] ]
end

to blast::filter-neighbors
  ioda:filter-neighbors-on-patches (patch-set patch-here patch-at 0 -1)
end

to-report blast::nothing-ahead?
  report default::nothing-ahead? 1
end

to-report blast::propagate?
  if strength < 1 [ blast::create-diamond ioda:die report false ]
  report true
end

to blast::create-blast
  set strength strength - 1
  let new-strength strength
  ask neighbors
    [ if not any? blast-here
      [ if any? turtles-here
        [ ask turtles-here
          [ if destructible?
            [ ioda:die
              ;if is-amoeba?
              ;[ set amoebas-amout ( amoebas-amout - 1 ) ]
            ]
          ]
        ]
      sprout-blast 1 [ init-blast false new-strength ]
      ]
     ]
end

to-report blast::is-rock?
  report default::is-rock?
end

to-report blast::is-amoeba?
  report default::is-amoeba?
end



; ========================
; doors-related primitives
; ========================

to-report doors::open?
  report open?
end

to-report doors::closed?
  report not doors::open?
end

to-report doors::objectives-fulfilled?
  report nb-to-collect = 0
end

to doors::change-state
  set open? not open?
  ifelse open?
    [ set color yellow + 2
      set shape "door-open" ]
    [ set color blue - 4
      set shape "tile brick"
    ]
end

to-report doors::is-rock?
  report default::is-rock?
end


to-report doors::is-amoeba?
  report default::is-amoeba?
end



; ==========================
; amoebas-related primitives
; ==========================

to-report amoebas::can-grown?
  let rdm random 2000
  if ( rdm < amoebas-speed )
  [
    report true
  ]
  report false
end

to amoebas::grow
  ask neighbors [
    let turtles-neighbors ([breed] of turtles-here)
    if (not any? turtles-here) or ((first turtles-neighbors = dirt) and (length turtles-neighbors = 1)) [
      if not empty? turtles-neighbors and first turtles-neighbors = dirt [
        ask dirt-here [
          ioda:die
        ]
      ]
      sprout-amoebas 1 [ init-amoeba ]
    ]
  ]

  if ( amoebas-amout > 50 )
  [
    set too-many-amoebas? true
  ]

  if ( amoebas-amout = ( prev-amoebas-amout + 1 ) )
  [
    set stagnation-count ( stagnation-count + 1 )
  ]

  if ( stagnation-count > 50 )
  [
    set amoebas-stagnate? true
  ]
end

to amoebas::die
  set amoebas-amout ( amoebas-amout - 1 )
  ioda:die
end

to-report amoebas::is-rock?
  report default::is-rock?
end

to-report amoebas::is-amoeba?
  report default::is-amoeba?
end


to-report amoebas::amoebas-stagnate?
  report amoebas-stagnate?
end

to-report amoebas::too-many-amoebas?
  report too-many-amoebas?
end

to amoebas::diamondization
  set amoebas-amout 0
  set prev-amoebas-amout 0
  set stagnation-count 0

  ioda:die
  ask patch-here [
    sprout-diamonds 1 [init-diamond]
    ask diamonds-here [
      set moving? true
    ]
  ]
end

to amoebas::transform-to-rock
  set amoebas-amout 0
  set prev-amoebas-amout 0
  set stagnation-count 0

  ioda:die
  ask patch-here [
    sprout-rocks 1 [init-rock]
    ask rocks-here [
      set moving? true
    ]
  ]
end



; ===========================
; diamonds-related primitives
; ===========================

to diamonds::filter-neighbors
  ioda:filter-neighbors-on-patches (patch-set patch-here patch-at 0 -1)
end

to-report diamonds::nothing-below?
  report default::nothing-below?
end

to-report diamonds::moving?
  report default::moving?
end

to diamonds::start-moving
  default::start-moving
end

to diamonds::stop-moving
  default::stop-moving
end

to diamonds::move-down
  default::move-down
end

to diamonds::create-blast
  let dm? ifelse-value ([breed] of ioda:my-target = monsters) [ [right-handed?] of ioda:my-target ] [ true ]
  hatch-blast 1 [ init-blast dm? 3 ]
end

to diamonds::die
  ioda:die
end

to-report diamonds::is-rock?
  report default::is-rock?
end


to-report diamonds::is-amoeba?
  report default::is-amoeba?
end



; ========================
; rocks-related primitives
; ========================

to rocks::filter-neighbors
  ioda:filter-neighbors-on-patches (patch-set patch-here patch-at 0 -1)
end

to-report rocks::nothing-below?
  report default::nothing-below?
end

to-report rocks::moving?
  report default::moving?
end

to rocks::start-moving
  default::start-moving
end

to rocks::stop-moving
  default::stop-moving
end

to rocks::move-down
  default::move-down
end

to rocks::create-blast
  let dm? ifelse-value ([breed] of ioda:my-target = monsters) [ [right-handed?] of ioda:my-target ] [ true ]
  hatch-blast 1 [ init-blast dm? 3 ]
end

to rocks::die
  ioda:die
end

to rocks::move-forward
  default::move-forward
end

to rocks::flip-head
  right 180
end

to-report rocks::nothing-ahead?
  face ioda:my-target
  rocks::flip-head
  report default::nothing-ahead? 1
end

to-report rocks::can-roll?
  if (not any? turtles-on patch-at -1 0 and not any? turtles-on patch-at -1 -1)
  [set heading 270 report true]
  if (not any? turtles-on patch-at 1 0 and not any? turtles-on patch-at 1 -1)
  [set heading 90 report true]
  report false
end

to-report rocks::inside-magicwall?
  report any? magicwalls-here
end

to rocks::diamondization
  ioda:die
  ask patch-here [
    sprout-diamonds 1 [init-diamond]
    ask diamonds-here [
      set moving? true
      diamonds::move-down
    ]
  ]
end

to-report rocks::is-rock?
  report true
end

to-report rocks::magicwall-below?
  report any? magicwalls-on patch-at 0 -1
end


; ===========================
; monsters-related primitives
; ===========================

to monsters::filter-neighbors
  ioda:filter-neighbors-on-patches (patch-set patch-here patch-ahead 1)
end

to-report monsters::nothing-ahead?
  report default::nothing-ahead? 1
end

to-report monsters::moving?
  report moving?
end

to monsters::move-forward
  default::move-forward
end

to monsters::turn-right-or-left
  ifelse right-handed?
    [ right 90 ]
    [ left 90 ]
end

to monsters::die
  ioda:die
end

to monsters::create-blast
  let dm? ifelse-value ([breed] of ioda:my-target = heros) [ true ] [ right-handed? ]
  hatch-blast 1 [ init-blast dm? 3 ]
end

to-report monsters::is-rock?
  report default::is-rock?
end

to-report monsters::is-amoeba?
  report default::is-amoeba?
end



; =======================
; dirt-related primitives
; =======================

to dirt::die
  ioda:die
end

to-report dirt::is-rock?
  report default::is-rock?
end

to-report dirt::is-amoeba?
  report default::is-amoeba?
end



; ===========================
; dynamite-related primitives
; ===========================

to-report dynamite::explode?
  report time < 1
end

to dynamite::create-blast
  hatch-blast 1 [ init-blast true 2 ]
end

to dynamite::filter-neighbors
  ioda:filter-neighbors-in-radius halo-of-hero
end

to dynamite::die
  ioda:die
end

to-report dynamite::is-rock?
  report default::is-rock?
end

to-report dynamite::is-amoeba?
  report default::is-amoeba?
end



; =======================
; hero-related primitives
; =======================

to send-message [ value ]
  set orders lput value orders
  set time time - 1
end

to heros::send-message-auto
  let values [0 90 180 -90]
  let pos random 4
  let value item pos values
  set orders lput value orders
  set time time - 1
end

to-report heros::automatise?
  report IA
end

to heros::put-dynamite
  if default::nothing-ahead? 1 and nb-dynamite > 0
  [ set time 5 hatch-dynamite 1 [init-dynamite fd 1] set nb-dynamite nb-dynamite - 1]
end

to heros::filter-neighbors
  ioda:filter-neighbors-in-radius halo-of-hero
end

to-report heros::nothing-ahead?
  report (default::nothing-ahead? 1) or (any? (doors-on patch-ahead 1) with [ doors::open? ])
end

to-report heros::target-ahead?
  report ([patch-here] of ioda:my-target) = (patch-ahead 1)
end

to-report heros::moving?
  report moving?
end

to-report heros::needs-to-stop?
  report step-by-step?
end

to-report heros::message-received?
  report not empty? orders
end

to heros::handle-messages
  foreach orders
    [ let m ?
      ifelse (m = "STOP")
        [ set moving? false]
        [ set heading m set moving? true ]
    ]
  set orders []
end

to heros::stop-moving
  set moving? false
end

to heros::die
  set countdown 10
  ioda:die
end

to heros::move-forward
  default::move-forward
end

to heros::create-blast
  hatch-blast 1 [ init-blast true 3 ]
end

to heros::increase-score
  set score score + 1
  set nb-to-collect nb-to-collect - 1
end

to-report heros::is-rock?
  report default::is-rock?
end

to-report heros::is-amoeba?
  report default::is-amoeba?
end
@#$#@#$#@
GRAPHICS-WINDOW
482
10
1092
491
-1
-1
30.0
1
10
1
1
1
0
0
0
1
0
19
-14
0
1
1
1
ticks
30.0

BUTTON
22
19
88
52
NIL
setup\n
NIL
1
T
OBSERVER
NIL
&
NIL
NIL
1

BUTTON
113
21
176
54
NIL
go
T
1
T
OBSERVER
NIL
É
NIL
NIL
1

MONITOR
25
284
97
365
NIL
score
0
1
20

SLIDER
276
18
448
51
halo-of-hero
halo-of-hero
1
10
5
1
1
NIL
HORIZONTAL

BUTTON
187
425
250
458
up
ask heros [ send-message 0 ]
NIL
1
T
OBSERVER
NIL
Z
NIL
NIL
1

BUTTON
186
502
251
535
down
ask heros [ send-message 180 ]
NIL
1
T
OBSERVER
NIL
S
NIL
NIL
1

BUTTON
186
463
250
496
STOP
ask heros [ send-message \"STOP\" ]
NIL
1
T
OBSERVER
NIL
P
NIL
NIL
1

BUTTON
256
463
319
496
right
ask heros [ send-message 90 ]
NIL
1
T
OBSERVER
NIL
D
NIL
NIL
1

BUTTON
118
463
181
496
left
ask heros [ send-message -90 ]
NIL
1
T
OBSERVER
NIL
Q
NIL
NIL
1

MONITOR
112
284
278
365
diamonds left
nb-to-collect
0
1
20

CHOOSER
278
63
432
108
level
level
"level0" "level1" "level2" "level3" "amoeba-level" "amoeba-level2"
4

MONITOR
287
285
445
366
monsters left
count monsters
0
1
20

SWITCH
278
122
422
155
step-by-step?
step-by-step?
0
1
-1000

BUTTON
284
417
381
450
dynamite
ask heros [ heros::put-dynamite ]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
276
170
448
203
ndynamite
ndynamite
0
10
5
1
1
NIL
HORIZONTAL

SWITCH
295
234
398
267
IA
IA
0
1
-1000

SLIDER
85
170
267
203
amoebas-speed
amoebas-speed
0
500
10
5
1
NIL
HORIZONTAL

@#$#@#$#@
Elliot Vanegue et Gaëtan Deflandre
==================================

# Boulder dash

## Introduction

Le projet reprend les concepts du jeu boulder dash qui a été créé en 1984 tout en utilisant la plateforme IODA développée par l'équipe SMAC de l'université de Lille.

## But du jeu

Le but du jeu est de faire rammasser à un héros un nombre défini de diamants dans le but d'ouvrir une porte menant au niveau suivant. Mais bien entendu de nombreux défis attendent notre héros. Il va falloir que celui-ci évite des roches qui tombent, fuit les monstres qui le pourchassent tout en creusant la terre dans un labyrinthe.

Dans ce jeu les agents ne peuvent se déplacer que sur un voisinage de 4 cases (haut, bas, droite et gauche).

## Règle du jeu

Plusieurs types d'agent sont présents dans le jeu :

* le héros : il peut être manipulé par le joueur ou être autonome. Il creuse la terre et peut poser de la dynamite pour faire exploser certains murs, les monstres et la terre.
* les murs : ils bloquent le héros. Certains peuvent être détruits.
* la terre : elle retient certains objets de tomber.
* les explosions : elles sont créées lors de l'impact d'une pierre avec un monstre ou le héros. Elles se propagent sur une zone définie, détruisant tout ce qui est destructible (tout sauf certains murs).
* les monstres : lors de la collision avec le héros ou une pierre ils explosent.
* les murs magiques : lorsqu'une pierre les traverse, la pierre se transforme en diamant.
* les diamants : lorsqu'ils tombent sur un monstre ou sur le héros, ils explosent comme les pierres.

## Utilisation

Il est possible de déplacer le héros avec les touches :

* Z : pour aller vers le haut
* S : pour aller vers le bas
* Q : pour aller à gauche
* D : pour aller à droite
* espace : déposer de la dynamite

## Réprésentation des niveaux

Vous pouvez créer des niveaux dans un fichier texte avec les caractères ASCII suivants :

* . : sable
* D : diamant
* H : héros du jeu
* M : monstre
* m : mur "magique"
* O : porte de sortie
* R : pierre
* X : mur non-destructible
* x : mur destructible
* A : amibe

La première ligne du fichier contient la taille du niveau [longueur largeur]
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

bee 2
true
0
Polygon -1184463 true false 195 150 105 150 90 165 90 225 105 270 135 300 165 300 195 270 210 225 210 165 195 150
Rectangle -16777216 true false 90 165 212 185
Polygon -16777216 true false 90 207 90 226 210 226 210 207
Polygon -16777216 true false 103 266 198 266 203 246 96 246
Polygon -6459832 true false 120 150 105 135 105 75 120 60 180 60 195 75 195 135 180 150
Polygon -6459832 true false 150 15 120 30 120 60 180 60 180 30
Circle -16777216 true false 105 30 30
Circle -16777216 true false 165 30 30
Polygon -7500403 true true 120 90 75 105 15 90 30 75 120 75
Polygon -16777216 false false 120 75 30 75 15 90 75 105 120 90
Polygon -7500403 true true 180 75 180 90 225 105 285 90 270 75
Polygon -16777216 false false 180 75 270 75 285 90 225 105 180 90
Polygon -7500403 true true 180 75 180 90 195 105 240 195 270 210 285 210 285 150 255 105
Polygon -16777216 false false 180 75 255 105 285 150 285 210 270 210 240 195 195 105 180 90
Polygon -7500403 true true 120 75 45 105 15 150 15 210 30 210 60 195 105 105 120 90
Polygon -16777216 false false 120 75 45 105 15 150 15 210 30 210 60 195 105 105 120 90
Polygon -16777216 true false 135 300 165 300 180 285 120 285

bird
false
0
Polygon -7500403 true true 135 165 90 270 120 300 180 300 210 270 165 165
Rectangle -7500403 true true 120 105 180 237
Polygon -7500403 true true 135 105 120 75 105 45 121 6 167 8 207 25 257 46 180 75 165 105
Circle -16777216 true false 128 21 42
Polygon -7500403 true true 163 116 194 92 212 86 230 86 250 90 265 98 279 111 290 126 296 143 298 158 298 166 296 183 286 204 272 219 259 227 235 240 241 223 250 207 251 192 245 180 232 168 216 162 200 162 186 166 175 173 171 180
Polygon -7500403 true true 137 116 106 92 88 86 70 86 50 90 35 98 21 111 10 126 4 143 2 158 2 166 4 183 14 204 28 219 41 227 65 240 59 223 50 207 49 192 55 180 68 168 84 162 100 162 114 166 125 173 129 180

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

box 2
false
0
Polygon -7500403 true true 150 285 270 225 270 90 150 150
Polygon -13791810 true false 150 150 30 90 150 30 270 90
Polygon -13345367 true false 30 90 30 225 150 285 150 150

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cloud
false
0
Circle -7500403 true true 13 118 94
Circle -7500403 true true 86 101 127
Circle -7500403 true true 51 51 108
Circle -7500403 true true 118 43 95
Circle -7500403 true true 158 68 134

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

diamond
false
0
Polygon -13345367 true false 15 90 60 30 240 30 285 90 285 150 150 300 15 150
Polygon -11221820 false false 60 30 240 30 285 90 285 150 150 300 15 150 15 90
Line -11221820 false 15 150 285 150
Line -11221820 false 15 90 285 90
Line -11221820 false 120 30 90 90
Line -11221820 false 180 30 210 90
Line -11221820 false 150 30 150 90
Line -11221820 false 90 90 90 150
Line -11221820 false 150 90 150 150
Line -11221820 false 210 90 210 150
Line -11221820 false 90 150 150 300
Line -11221820 false 150 150 150 300
Line -11221820 false 210 150 150 300
Line -11221820 false 90 30 45 90
Line -11221820 false 210 30 255 90
Line -11221820 false 45 90 45 150
Line -11221820 false 255 90 255 150
Line -11221820 false 45 150 150 300
Line -11221820 false 255 150 150 300

dirt
false
0
Rectangle -7500403 true true -1 0 299 300
Polygon -1 true false 105 259 180 290 212 299 168 271 103 255 32 221 1 216 35 234
Polygon -1 true false 300 161 248 127 195 107 245 141 300 167
Polygon -1 true false 0 157 45 181 79 194 45 166 0 151
Polygon -1 true false 179 42 105 12 60 0 120 30 180 45 254 77 299 93 254 63
Polygon -1 true false 114 91 65 71 15 57 66 81 180 135
Polygon -1 true false 179 209 243 239 280 246 196 206 129 184

door-open
false
15
Polygon -7500403 true false 0 60 60 15 150 0 240 15 300 60 300 300 0 300
Rectangle -7500403 true false 0 60 15 300
Polygon -6459832 true false 15 60 120 15 120 255 15 300
Rectangle -1 true true 15 60 30 105
Rectangle -1 true true 15 150 30 210
Circle -1 true true 75 120 30
Rectangle -16777216 false false 0 60 15 300
Rectangle -16777216 false false 15 60 30 105
Rectangle -16777216 false false 15 150 30 210
Circle -16777216 false false 75 120 30
Polygon -16777216 false false 15 60 120 15 120 255 15 300
Rectangle -1 true true 15 255 30 300
Rectangle -16777216 false false 15 255 30 300
Rectangle -16777216 false false 285 60 300 300

dot
false
0
Circle -7500403 true true 90 90 120

eyes
false
0
Circle -1 true false 62 75 57
Circle -1 true false 182 75 57
Circle -16777216 true false 79 93 20
Circle -16777216 true false 196 93 21

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

ghost
false
0
Circle -7500403 true true 61 30 179
Rectangle -7500403 true true 60 120 240 232
Polygon -7500403 true true 60 229 60 284 105 239 149 284 195 240 239 285 239 228 60 229
Circle -1 true false 81 78 56
Circle -16777216 true false 99 98 19
Circle -1 true false 155 80 56
Circle -16777216 true false 171 98 17

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pacman
true
0
Circle -7500403 true true 0 0 300
Polygon -16777216 true false 105 -15 150 150 195 -15
Circle -16777216 true false 191 101 67

pacman open
true
0
Circle -7500403 true true 0 0 300
Polygon -16777216 true false 270 -15 149 152 30 -15
Circle -16777216 true false 206 101 67

pellet
true
0
Circle -7500403 true true 105 105 92

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

person farmer
false
0
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Polygon -1 true false 60 195 90 210 114 154 120 195 180 195 187 157 210 210 240 195 195 90 165 90 150 105 150 150 135 90 105 90
Circle -7500403 true true 110 5 80
Rectangle -7500403 true true 127 79 172 94
Polygon -13345367 true false 120 90 120 180 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 180 90 172 89 165 135 135 135 127 90
Polygon -6459832 true false 116 4 113 21 71 33 71 40 109 48 117 34 144 27 180 26 188 36 224 23 222 14 178 16 167 0
Line -16777216 false 225 90 270 90
Line -16777216 false 225 15 225 90
Line -16777216 false 270 15 270 90
Line -16777216 false 247 15 247 90
Rectangle -6459832 true false 240 90 255 300

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

rock
true
1
Polygon -7500403 true false 45 75 15 135 15 165 30 195 30 225 60 240 75 240 120 270 165 285 210 270 240 240 255 195 270 165 285 150 285 120 270 75 240 45 210 45 165 30 165 15 120 0 90 30 75 60
Polygon -2674135 true true 90 45 120 15 165 30 195 15 240 60 270 75 285 120 270 165 270 210 225 255 180 270 120 285 75 225 15 195 30 135 30 90 45 60

rock 1
false
0
Circle -7500403 true true -2 118 94
Circle -7500403 true true 176 176 127
Circle -7500403 true true 171 21 108
Circle -7500403 true true 28 43 95
Circle -7500403 true true 173 68 134
Circle -7500403 true true 53 173 134
Circle -7500403 true true 78 48 175

scared
false
0
Circle -13345367 true false 61 30 179
Rectangle -13345367 true false 60 120 240 232
Polygon -13345367 true false 60 229 60 284 105 239 149 284 195 240 239 285 239 228 60 229
Circle -16777216 true false 81 78 56
Circle -16777216 true false 155 80 56
Line -16777216 false 137 193 102 166
Line -16777216 false 103 166 75 194
Line -16777216 false 138 193 171 165
Line -16777216 false 172 166 198 192

sheep
false
0
Rectangle -7500403 true true 151 225 180 285
Rectangle -7500403 true true 47 225 75 285
Rectangle -7500403 true true 15 75 210 225
Circle -7500403 true true 135 75 150
Circle -16777216 true false 165 76 116

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

sun
false
0
Circle -7500403 true true 75 75 150
Polygon -7500403 true true 300 150 240 120 240 180
Polygon -7500403 true true 150 0 120 60 180 60
Polygon -7500403 true true 150 300 120 240 180 240
Polygon -7500403 true true 0 150 60 120 60 180
Polygon -7500403 true true 60 195 105 240 45 255
Polygon -7500403 true true 60 105 105 60 45 45
Polygon -7500403 true true 195 60 240 105 255 45
Polygon -7500403 true true 240 195 195 240 255 255

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tile brick
false
0
Rectangle -1 true false 0 0 300 300
Rectangle -7500403 true true 15 225 150 285
Rectangle -7500403 true true 165 225 300 285
Rectangle -7500403 true true 75 150 210 210
Rectangle -7500403 true true 0 150 60 210
Rectangle -7500403 true true 225 150 300 210
Rectangle -7500403 true true 165 75 300 135
Rectangle -7500403 true true 15 75 150 135
Rectangle -7500403 true true 0 0 60 60
Rectangle -7500403 true true 225 0 300 60
Rectangle -7500403 true true 75 0 210 60

tile log
false
0
Rectangle -7500403 true true 0 0 300 300
Line -16777216 false 0 30 45 15
Line -16777216 false 45 15 120 30
Line -16777216 false 120 30 180 45
Line -16777216 false 180 45 225 45
Line -16777216 false 225 45 165 60
Line -16777216 false 165 60 120 75
Line -16777216 false 120 75 30 60
Line -16777216 false 30 60 0 60
Line -16777216 false 300 30 270 45
Line -16777216 false 270 45 255 60
Line -16777216 false 255 60 300 60
Polygon -16777216 false false 15 120 90 90 136 95 210 75 270 90 300 120 270 150 195 165 150 150 60 150 30 135
Polygon -16777216 false false 63 134 166 135 230 142 270 120 210 105 116 120 88 122
Polygon -16777216 false false 22 45 84 53 144 49 50 31
Line -16777216 false 0 180 15 180
Line -16777216 false 15 180 105 195
Line -16777216 false 105 195 180 195
Line -16777216 false 225 210 165 225
Line -16777216 false 165 225 60 225
Line -16777216 false 60 225 0 210
Line -16777216 false 300 180 264 191
Line -16777216 false 255 225 300 210
Line -16777216 false 16 196 116 211
Line -16777216 false 180 300 105 285
Line -16777216 false 135 255 240 240
Line -16777216 false 240 240 300 255
Line -16777216 false 135 255 105 285
Line -16777216 false 180 0 240 15
Line -16777216 false 240 15 300 0
Line -16777216 false 0 300 45 285
Line -16777216 false 45 285 45 270
Line -16777216 false 45 270 0 255
Polygon -16777216 false false 150 270 225 300 300 285 228 264
Line -16777216 false 223 209 255 225
Line -16777216 false 179 196 227 183
Line -16777216 false 228 183 266 192

tile stones
false
0
Polygon -7500403 true true 0 240 45 195 75 180 90 165 90 135 45 120 0 135
Polygon -7500403 true true 300 240 285 210 270 180 270 150 300 135 300 225
Polygon -7500403 true true 225 300 240 270 270 255 285 255 300 285 300 300
Polygon -7500403 true true 0 285 30 300 0 300
Polygon -7500403 true true 225 0 210 15 210 30 255 60 285 45 300 30 300 0
Polygon -7500403 true true 0 30 30 0 0 0
Polygon -7500403 true true 15 30 75 0 180 0 195 30 225 60 210 90 135 60 45 60
Polygon -7500403 true true 0 105 30 105 75 120 105 105 90 75 45 75 0 60
Polygon -7500403 true true 300 60 240 75 255 105 285 120 300 105
Polygon -7500403 true true 120 75 120 105 105 135 105 165 165 150 240 150 255 135 240 105 210 105 180 90 150 75
Polygon -7500403 true true 75 300 135 285 195 300
Polygon -7500403 true true 30 285 75 285 120 270 150 270 150 210 90 195 60 210 15 255
Polygon -7500403 true true 180 285 240 255 255 225 255 195 240 165 195 165 150 165 135 195 165 210 165 255

tile water
false
0
Rectangle -7500403 true true -1 0 299 300
Polygon -1 true false 105 259 180 290 212 299 168 271 103 255 32 221 1 216 35 234
Polygon -1 true false 300 161 248 127 195 107 245 141 300 167
Polygon -1 true false 0 157 45 181 79 194 45 166 0 151
Polygon -1 true false 179 42 105 12 60 0 120 30 180 45 254 77 299 93 254 63
Polygon -1 true false 99 91 50 71 0 57 51 81 165 135
Polygon -1 true false 194 224 258 254 295 261 211 221 144 199

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.2.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment" repetitions="20" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="5000"/>
    <metric>score</metric>
    <metric>remaining-bees</metric>
    <enumeratedValueSet variable="nb-walls">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nb-bees">
      <value value="0"/>
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
      <value value="4"/>
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pengi-halo">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nb-ice">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nb-fish">
      <value value="20"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
