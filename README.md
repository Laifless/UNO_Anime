# Anime Battle Card UNO
------------------------
Nome: Tavani Samuele
------------------------
Anime Battle UNO è un gioco di carte strategico cross-platform sviluppato in Flutter. Combina le classiche meccaniche di gioco di UNO con l'universo degli Anime, permettendo ai giocatori di sfidarsi utilizzando i loro eroi preferiti e abilità speciali (Ultimate).

Il gioco supporta il Multiplayer Online in tempo reale tramite Firebase.

 Funzionalità Principali
 
 Multiplayer in Tempo Reale: Sistema di Lobby e sincronizzazione della partita gestito tramite Firebase Realtime Database.

Universi Multipli: Scegli tra diversi universi anime:

Dragon Ball

Naruto

One Piece

Bleach

Jujutsu Kaisen

Tokyo Ghoul

 Sistema Eroi e Ultimate: Ogni eroe ha un colore tematico e una "Ultimate" (grido di battaglia) che può essere attivata durante la partita.

 Meccaniche UNO Complete: Include carte numeriche, cambio colore, +2, +4 (Wild) e Salta Turno.

 Timer di Turno: Ogni giocatore ha 15 secondi per fare la sua mossa, rendendo il gioco frenetico.

 Tecnologie Utilizzate
Frontend: Flutter (Dart)

Backend / Database: Firebase Realtime Database

Gestione Stato: setState e Stream (per l'ascolto in tempo reale di Firebase).

## Struttura del progetto

<img width="691" height="152" alt="image" src="https://github.com/user-attachments/assets/9f7d545a-5e96-4e54-9d14-963091ef5cf9" />



## Come si gioca?

Scegli il tuo Guerriero: Nella schermata iniziale, seleziona l'universo (es. Jujutsu Kaisen) e il tuo personaggio (es. Gojo).


Entra nella Lobby: Inserisci un ID stanza condiviso per giocare contro un amico.


La Partita:

Lancia carte che corrispondono per Colore o Numero all'ultima carta giocata.

Usa le carte speciali (+2, Stop, Cambio Colore) per ostacolare l'avversario.

Se non hai carte da giocare, pescane una dal mazzo.

Vince chi finisce le carte per primo!

 Note Importanti sulla Sicurezza
Nel file main.dart, l'inizializzazione di Firebase è fatta manualmente:

### Nota importante: Si sta sviluppando un gioco più serio e completamente autonomo da questo!!!


# GALLERIA IMMAGINI

## Schermata Home

<img width="546" height="482" alt="image" src="https://github.com/user-attachments/assets/3258fc17-0d80-4abb-87c5-4749beba89a3" />

## Selezione del personaggio

<img width="549" height="770" alt="image" src="https://github.com/user-attachments/assets/8579b7c9-149f-49da-a756-11e346c3cdf7" />

## Attesa avversario

<img width="550" height="774" alt="image" src="https://github.com/user-attachments/assets/33cda33b-6926-4405-a014-a36d937360c2" />


## Visualizzazione della propria mano (turno avversario e turno proprio)

<img width="815" height="853" alt="image" src="https://github.com/user-attachments/assets/2ca610b5-26cd-4879-8052-d33f89329445" />
<img width="1075" height="982" alt="image" src="https://github.com/user-attachments/assets/5a01ed13-d4b6-41d5-b234-162282bcca5b" />

## Vittoria/Sconfitta

<img width="1405" height="848" alt="image" src="https://github.com/user-attachments/assets/32b79a73-e88e-4429-b62a-ce1d2fb17850" />
<img width="1075" height="977" alt="image" src="https://github.com/user-attachments/assets/afd4a31a-99b8-42ab-87e8-3db8a91801af" />




