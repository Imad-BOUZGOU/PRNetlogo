;; Création des différents agents qui composent l'environnement
breed[macrophages macrophage]
breed[cytokines cytokine]
breed[chemokines chemokine]
breed[RANKLs RANKL]
breed[MMPs MMP]
breed[osteoclastes osteoclaste]
breed[chondrocytes chondrocyte]
breed[fibroblastes fibroblaste]

patches-own [type-patch]             ;; Differencier les patches

to setup                             ;; Efface tout et réinitialise tout aux valeurs initiales par défaut
  ca
  ;; Definir une forme initiale par défaut pour chaque agent
  set-default-shape macrophages "circle"
  set-default-shape cytokines "cytokine"
  set-default-shape chemokines "ballpin"
  set-default-shape RANKLs "dot"
  set-default-shape MMPs "dot"
  set-default-shape osteoclastes "monster"
  set-default-shape chondrocytes "square"
  set-default-shape fibroblastes "square"

  ;; Dessiner les différentes parties de l'espace synovial grâce aux patches
  ;; OS
  ask patches with [(pxcor < 0) and (pycor > 5)][set pcolor 9.9 set type-patch "os"]
  ;; Cartilage
  ask patches with [(pxcor < 0) and (pycor > 1) and (pycor < 6)][set pcolor 84 set type-patch "cartilage"]
  ;; Membrane Synovial
  ask patches with [(pxcor > 14)][set pcolor 45 set type-patch "membraneSynovial"]
  ;; Liquide Synovial
  ask patches with [pcolor = 0][set pcolor 48 set type-patch "liquideSynovial"]

  ask n-of nb-macrophage patches with [pcolor = 48] [      ;; Création des Macrophages dans le liquide synovial
    sprout-macrophages 1 [
      set color red
      hatch-cytokines random 5[                            ;; Chaque Macrophage crée un nombre aléatoire [0..5] de Cytokines.
        set color grey
      ]
    ]
  ]
  ask n-of nb-osteoclaste patches with [type-patch = "os"] [
    sprout-osteoclastes 1 [                                ;; Création des osteoclastes sur l'os
      set color black
    ]
  ]
  ask patches with [type-patch = "cartilage"] [
    sprout-chondrocytes 1[                                 ;; Création des chondrocytes sur le cartilage
      set color white
    ]
  ]
  ask n-of nb-fibroblaste patches with [type-patch = "membraneSynovial"] [
    sprout-fibroblastes 1[                                 ;; Création des fibroblastes sur la membrane synoviale
      set color white
    ]
  ]
  reset-ticks                                             ;; Inistalisation de l'horloge
end

to go                                ;; Lancer la simulation
  go_cytokines
  go_macrophages
  go_mmps
  go_rankls
  go_osteoclastes
  go_chemokines
  tick
end

to go_mmps                           ;; Faire avancer les MMPs
  ;; faire deplacer les MMPs
  ask MMPs[
    move "liquideSynovial" "membraneSynovial" "cartilage" 1
    if any? chondrocytes-here [
      if ChondrocyteActivation < random 100[
        ask chondrocytes-here [
          ifelse (pcolor < 89 and pcolor > 83) [
            set pcolor pcolor + 0.1
            ask MMPs-here [die]
          ][
            set pcolor 48
            set type-patch "liquideSynovial"
            die
          ]
        ]
      ]
    ]
  ]
end

to go_rankls                         ;; Faire avancer les RANKLs
  ;; faire deplacer les RANKLs
  ask RANKLs [
    move "liquideSynovial" "membraneSynovial" "os" 1
    if any? osteoclastes-here [
      if OsteoclasteActivation < random 100[
        ask osteoclastes-here [
          if (pcolor > 5) [set pcolor pcolor - 0.1]
        ]
        die
      ]
    ]
  ]
end

to go_osteoclastes                   ;; Faire avancer les Osteoclastes
  ;; faire deplacer les osteoclastes
  ask osteoclastes [
    move "os" "" "" .1
  ]
end

to go_chemokines                     ;; Faire avancer les Chemokines
  ask chemokines [
    move "liquideSynovial" "membraneSynovial" "" 1
    if any? macrophages-here [
      if MacrophageActivation < random 100[
        ask macrophages-here [
          hatch-cytokines 1 [
            set color gray
          ]
        ]
        ask chemokines-here [die]
      ]
    ]
  ]
end

to go_macrophages                    ;; Faire avancer les Macrophages
  ask macrophages[
    move "liquideSynovial" "" "" .1
  ]
end

to go_cytokines                      ;; faire avancer les Cytokines
  ask cytokines[
    move "liquideSynovial" "membraneSynovial" "cartilage" 1
    if (any? fibroblastes-here)[                  ;; Chaque fois qu’une cytokine croise une cellule Fibroblaste : {
      ask fibroblastes-here [
        if FibroblasteActivation < random 100 [
          set pcolor red
          if ((count chondrocytes) - (count MMPs) >= 0 )[
            hatch-MMPs 1[                         ;; Crée une MMP
              set color green
            ]
          ]
          if ((count patches with [(pcolor > 5) and (type-patch = "os")]) - (count RANKLs) >= 0 )[
            hatch-RANKLs random 3[                ;; Crée une RANKL
              set color 126
            ]
          ]
          hatch-chemokines 1[              ;; Crée une Chémokine
            set color 35
          ]                                       ;; En tue les cellule fibroblastes pour les remplacer par des inflammations
          set color red
          ask cytokines-here [die]
        ]                               ;; Pour ne pas encombrer le modèle avec l'énorme quantité de Cytokines produite durant
      ]                                 ;; la PR, on préfère les tuer apres chaque rencontre avec les Fibroblastes.
    ]
  ]
end

to move [a b c v]                         ;; fonction de Deplacement(Espace1,Espace2,Espace3,vitesse)
  lt random 90 rt random 90              ;; choix d'un angle de rotation aleatoir
    let x [type-patch] of patch-ahead 1
    ifelse (x = a or x = b or x = c)[
      fd v
    ]
    [
      lt 180
    ]
end
@#$#@#$#@
GRAPHICS-WINDOW
198
10
708
521
-1
-1
15.212121212121213
1
10
1
1
1
0
1
1
1
-16
16
-16
16
0
0
1
ticks
30.0

BUTTON
18
175
132
208
Créer Univers
setup
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
17
21
189
54
nb-fibroblaste
nb-fibroblaste
0
count patches with [type-patch = "membraneSynovial"]
66.0
1
1
NIL
HORIZONTAL

BUTTON
19
220
106
253
Simulation
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
17
73
189
106
nb-macrophage
nb-macrophage
0
20
10.0
1
1
NIL
HORIZONTAL

SLIDER
17
125
189
158
nb-osteoclaste
nb-osteoclaste
0
30
15.0
1
1
NIL
HORIZONTAL

MONITOR
1003
10
1115
55
% Inflammation
int((count patches with [type-patch = \"membraneSynovial\" and pcolor = red] / count patches with [type-patch = \"membraneSynovial\"]) * 100)
17
1
11

MONITOR
717
120
782
165
cytokines
count cytokines
17
1
11

PLOT
718
169
1325
520
Graphique
time
NbAgents
0.0
101.0
0.0
50.0
false
true
"" "if (ticks mod 100 = 0)[\n  set-plot-x-range (ticks) (ticks + 100)\n]"
PENS
"Chemokines" 1.0 0 -6459832 true "" "plot count chemokines"
"Cytokines" 1.0 0 -7500403 true "" "plot count cytokines"
"MMPs" 1.0 0 -10899396 true "" "plot count MMPs"
"RANKLs" 1.0 0 -5825686 true "" "plot count RANKLs"

MONITOR
717
65
858
110
% Degradation de l'Os 
int((1 - ((count patches with [pcolor = white])/(count patches with [type-patch = \"os\"]))) * 100)
17
1
11

MONITOR
791
120
869
165
chemokines
count chemokines
17
1
11

MONITOR
878
120
957
165
MMPs
count MMPs
17
1
11

MONITOR
966
120
1023
165
RANKLs
Count RANKLs
17
1
11

MONITOR
911
10
993
55
osteoclastes
Count osteoclastes
17
1
11

MONITOR
1032
120
1122
165
Chondrocytes
count chondrocytes
17
1
11

SLIDER
15
359
187
392
FibroblasteActivation
FibroblasteActivation
0
100
50.0
1
1
NIL
HORIZONTAL

SLIDER
15
401
192
434
ChondrocyteActivation
ChondrocyteActivation
0
100
85.0
1
1
NIL
HORIZONTAL

SLIDER
15
318
187
351
OsteoclasteActivation
OsteoclasteActivation
0
100
50.0
1
1
NIL
HORIZONTAL

SLIDER
15
276
188
309
MacrophageActivation
MacrophageActivation
0
100
50.0
1
1
NIL
HORIZONTAL

MONITOR
818
10
898
55
Fibroblastes
count fibroblastes
17
1
11

MONITOR
717
10
804
55
Macrophages
count macrophages
17
1
11

MONITOR
866
65
1033
110
% Degradation du Cartilage
int((1 - ( (count patches with [type-patch = \"cartilage\"]) / 64)) * 100)
17
1
11

PLOT
1125
10
1325
165
Historique
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"Chemokines" 1.0 0 -8431303 true "" "plot count chemokines"
"Cytokines" 1.0 0 -7500403 true "" "plot count cytokines"
"MMPs" 1.0 0 -10899396 true "" "plot count mmps"
"RANKLs" 1.0 0 -7858858 true "" "plot count rankls"

@#$#@#$#@
# Agents sociaux impliquee dans la **Polyarthrite Rhumatoïde**

## Introduction :

La [Polyarthrite Rhumatoïde][1] ou "PR" est une maladie ou l'immunité se retourne contre le corps de la personne atteinte, elle est dite auto-immune. C’est la maladie la plus fréquente des diverses formes de rhumatismes inflammatoires chroniques, n'atteignant pas toujours uniquement les articulations, mais aussi parfois d'autre zone du corps.

<center>
<img src="./img/doc/articulation-touchees.png">
</center>
<center>
<a href="https://www.lilly.fr/fr/maladie/polyarthrite-rhumatoide/articulations-touchees.aspx">Articulations les plus touchées</a>
</center>

Le système immunitaire produit des anticorps qui vont attaquer la membrane synoviale des articulations, qui est responsable de la production du liquide synoviale permettant la lubrification des mouvements. Quand cette dernière est agressée par l’auto-immunité, elle s'épaissit et fabriquera trop de liquide contenant des enzymes inflammatoire, susceptible de nuire toute l’articulation, les cartilages, les os …

<center>
<img src="./img/doc/11065899.png">
</center>
<center>
<a href="https://sante.journaldesfemmes.fr/maladies/2486114-polyarthrite-rhumatoide-definition-symptomes-traitement/">Espace synovial d'une main seine et une main malade</a>
</center>

Par notre modèle, nous voulons modéliser grace à un système multi-agents, les différents processus qui se produisent dans l’espace synovial d’une articulation atteinte de la polyarthrite rhumatoïde.


## Les différents agents qui composent l'espace synovial :

* **Membrane Synoviale** : Constituée de cellules type-B (**`Fibroblastes`**) et type-A (**`Macrophage`**), après inflammation ces cellules produisent le **`RANKL`** et le **`MMP`**.

* **Liquide Synovial** : Peut contenir plusieurs éléments dont les **`Macrophages`**.

* **Os** : Le tissu osseux contient plusieurs types de cellules dont les **`Ostéoclastes`**, Ostéoblastes responsable de la destruction resp. formation osseuse.

* **Cartilage** : Couche qui recouvre les articulations, formé de **`Chondrocytes`**.

* **Macrophage** : Production de **`Cytokines`** pro-inflammatoires.

* **Cytokine** : **`TNF-α`**, **`IL6`**, **`IL1`** (Tumor Necrosis Factor α, L'interleukine 6, L'interleukine 1).

* **Chémokines** : Stimule la production des **`Cytokine`** par les **`Macrophage`**.

* **RANKL** : Avec les **`Cytokines`**, elles suractivent les **`Ostéoclastes`**.

* **MMP** : Avec les **`Cytokines`**, elles détruisent le **`Cartilage`**.

* **Ostéoclastes** : Responsable de la destruction osseuse.

* **Chondrocytes** : Constituent l’unique type cellulaire du **`Cartilage`**.

* **Pannus** : Inflammation de la **`Membrane Synoviale`**.

* **Fibroblaste** : Cellule constituant la **`Membrane Synoviale`**.

## Representation des différents agents sous Netlogo

<center>
<img src="./img/doc/ModelisationNetLogo.png">
</center>

## Schéma résumant les différentes interactions entre les agents de la PR

<center>
<img src="./img/doc/netlogo-diagram.png">
</center>


## Composants de l’interface utilisateur

### Les Bouttons  :

#### Créer Univers : 
> Bouton pour charger l'environement (patches et tortues).

#### Simulation : 
> Bouton qui permet d'executer la simulation.

### Les sliders :

#### nb-fibroblast
> Permet de contrôler le nombre de Fibroblastes à générer pour la simulation (à régler avant le chargement de l’environnement) . 

#### nb-macrophage
> Permet de contrôler le nombre de Macrophages à générer pour la simulation (à régler avant le chargement de l’environnement) .

#### nb-osteoclaste
> Permet de contrôler le nombre d'Osteoclastes à générer pour la simulation (à régler avant le chargement de l’environnement) .

#### MacrophageActivation
> Permet de contrôler l’efficacité des Macrophages, plus la valeur est très grande (> 50) cela permettra aux macrophages d’avoir une meilleure résistance face aux Chémokines.


#### OstéoclasteActivation
> Permet de contrôler l’efficacité des Ostéoclastes, plus la valeur est très grande (> 50) cela permettra aux Ostéoclastes d’avoir une meilleure résistance face aux RANKLs.



#### FibroblasteActivation
> Permet de contrôler l’efficacité des Fibroblastes, plus la valeur est très grande (> 50) cela permettra aux Fibroblastes d’avoir une meilleure résistance face aux Cytokines.


#### ChondrocyteActivation
> Permet de contrôler l’efficacité des Chondrocytes, plus la valeur est très grande (> 50) cela permettra aux Chondrocytes d’avoir une meilleure résistance face aux MMPs.


### Les champs d'informations :

#### Inflammation :

>permet d'afficher le pourcentage de cellules Fibroblast Infectées.
```
count patches with [pcolor = red]
```

#### Cytokines :

>permet d'afficher le nombre de cytokines.
```
count cytokines
```

#### MMPs :

>permet d'afficher le nombre de MMPs.
```
count MMPs
```

#### Chemokines :

>permet d'afficher le nombre de chemokines.
```
count chemokines
```

#### RANKLs :

>permet d'afficher le nombre de RANKLs.
```
count RANKLs
```

#### Osteoclastes :

>permet d'afficher le nombre de Osteoclastes.
```
Count osteoclastes
```

#### %Degradation de l'os :

>permet d'afficher le nombre de cytokines.
```
(1 - (count patches with [pcolor = white]/count patches with [type-patch = "os"])) * 100
```

## Comment utiliser l’application !

**1**. Régler le nombre de chacune d'agents à créer (**Fibroblastes**, **Macrophages**, **Ostéoclastes**).
<center>
<img src="./img/info/nb-fibroblaste.png">
<img src="./img/info/nb-macrophage.png">
<img src="./img/info/nb-osteoclaste.png">
</center>

**2**. Définir le niveau d'efficacité de chaque agent par rapport aux autres agents (**Macrophage-Chémokine**, **Fibroblaste-Cytokine**, **Ostéoclaste-RANKL**, **Chondrocyte-MMP**).

<center>
<img src="./img/info/controleActivation1.png">
<img src="./img/info/controleActivation2.png">
</center>

**3**. Créer le monde de la simulation grâce au bouton **Créer Univers**.
<img src="./img/info/creerUnivers.png">

**4**. Lancer la simulation avec le bouton **Simulation**.
<img src="./img/info/simulation.png">


**5**. Observer les résultats de l’exécution sur le diagramme et les champs d’informations qui renseignent le nombre d’**instance restantes**, **niveau de dégradation de l’os**, **niveau d’inflammation** …
<center>
<img src="./img/info/infoAgents.png">
</center>
<center>
<img src="./img/info/inflammation.png">
<img src="./img/info/degOS.png">
</center>
<center>
<img src="./img/info/graphique.png">
</center>

**6**. Durant toute la période de la simulation, il est possible de régler la vitesse du modèle.
Plus à **gauche** « `vitesse faible` », au **centre** « `vitesse normale` », plus à **droite** « `vitesse élevée` »
<center>
<img src="./img/info/vitesse.png">
</center>

## Auteurs:
Dans le cadre de la réalisation d'une simulation de la **Polyarthrite Rhumatoïde** pour le TER ...

### Ce travail a été réalisé par :
<center>
	<b>Yacine HADJAR</b>
	<br>
   	<b>Imad BOUZGOU</b>
</center>

### Encadré par :
<center>
	<b>Sergui Ivanov</b>
</center>


...

[1]: https://disease-maps.org/rheumatoidarthritis        "disease-maps.org"
[2]: http://www.rhumatologie.asso.fr/04-Rhumatismes/stop-rhumatismes/pdf-upload/Pro_polyarthrite_rhumatoide_7.pdf					 "rhumatologie.asso.fr"
[3]: https://www.axaprevention.fr/sante-bien-etre/sante-question/polyarthrite-rhumatoide
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

ballpin
true
0
Rectangle -7500403 true true 135 59 167 242
Rectangle -7500403 true true 61 136 240 166
Circle -7500403 true true 87 89 124
Rectangle -7500403 true true 92 158 93 158

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

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

cytokine
true
0
Circle -1 true false 183 63 84
Circle -16777216 false false 183 63 84
Circle -7500403 true true 75 75 150
Circle -16777216 false false 75 75 150
Circle -1 true false 33 63 84
Circle -16777216 false false 33 63 84

dot
false
0
Circle -7500403 true true 90 90 120

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

monster
false
0
Polygon -7500403 true true 75 150 90 195 210 195 225 150 255 120 255 45 180 0 120 0 45 45 45 120
Circle -16777216 true false 165 60 60
Circle -16777216 true false 75 60 60
Polygon -7500403 true true 225 150 285 195 285 285 255 300 255 210 180 165
Polygon -7500403 true true 75 150 15 195 15 285 45 300 45 210 120 165
Polygon -7500403 true true 210 210 225 285 195 285 165 165
Polygon -7500403 true true 90 210 75 285 105 285 135 165
Rectangle -7500403 true true 135 165 165 270

orbit 1
true
0
Circle -7500403 true true 116 11 67
Circle -7500403 false true 41 41 218

orbit 3
true
0
Circle -7500403 true true 116 11 67
Circle -7500403 true true 26 176 67
Circle -7500403 true true 206 176 67
Circle -7500403 false true 45 45 210

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

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

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

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

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

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.1.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
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
