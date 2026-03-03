# Anime Battle Card UNO
------------------------
Nome: Tavani Samuele
------------------------
#  Anime Battle UNO 

**Anime Battle UNO** è un'esperienza cross-universe definitiva per gli amanti degli anime. Basato sulle regole classiche di UNO, il gioco introduce meccaniche competitive avanzate, mosse speciali tratte dalle serie più famose e un'infrastruttura multiplayer solida basata su Firebase.

---

##  Novità e Ottimizzazioni Recenti

* **Hand Management Dinamico:** La UI è stata progettata per gestire battaglie epiche. Se la tua mano cresce a dismisura (a causa di troppi +4!), le carte si dispongono in una **schermata a scorrimento fluido (Horizontal Scroll)**, permettendoti di navigare nel tuo deck senza sacrificare la visibilità del tavolo.
* **Ultimate Safety System:** Implementata una logica di "memoria dell'urlo". Premendo la Ultimate prima di giocare la penultima carta, il sistema imposta un flag di sicurezza sul server, impedendo matematicamente agli avversari di usare il tasto "Contesta".
* **Gradle Kotlin DSL:** Il progetto è stato migrato interamente a **Kotlin Script (.kts)** per una gestione delle dipendenze più moderna, sicura e performante.

---

##  Caratteristiche Dettagliate

###  Eroi e Universi
Ogni universo non è solo estetico, ma porta con sé l'atmosfera della serie:
* **Dragon Ball:** Goku & Vegeta (Orange/Blue theme)
* **Naruto:** Naruto & Sasuke (Shinobi style)
* **Jujutsu Kaisen:** Gojo & Sukuna (Special grade visuals)
* **...e molti altri** (One Piece, Bleach, Tokyo Ghoul).

###  Meccaniche di Gioco Avanzate
* **Solo Mode (Smart Bot):** Un'IA dedicata che analizza la tua mossa e risponde in meno di 2 secondi, gestendo correttamente anche i cambi colore e le carte speciali.
* **Multiplayer con Ruoli Rigidi:** Sistema di assegnazione automatica `Player1 (Host)` e `Player2 (Guest)` basato sulla posizione in Lobby, eliminando conflitti di sincronizzazione.
* **Timer Reattivo:** Ogni turno ha un limite di **15 secondi**. Se non giochi in tempo, il sistema pesca automaticamente per te e passa il turno, mantenendo il ritmo serrato.

---

##  Architettura Tecnica

### Gestione della UI
L'interfaccia utilizza un approccio a **Layer sovrapposti**:
1.  **Area Avversario:** Visualizzazione compatta del numero di carte nemiche.
2.  **Tavolo Centrale:** Focus sulla `Last Played Card` e sul mazzo di pesca (Draw Pile).
3.  **Player Hand:** Un `ListView.builder` ottimizzato che gestisce lo scroll orizzontale infinito delle tue carte.
4.  **Overlay di Turno:** AppBar dinamica che cambia colore (Verde/Rosso) e testo per indicare istantaneamente di chi è il momento di agire.

### Backend & Sincronizzazione
* **Firebase Realtime Database:** Utilizzato per la sincronizzazione "sub-second" delle mosse.
* **Transaction Handling:** Le operazioni critiche (come la pesca dal mazzo) sono gestite tramite transazioni per evitare che due giocatori peschino la stessa carta contemporaneamente.

---

##  Guida al Setup Professionale

1.  **Requisiti:** Flutter SDK (versione 3.24.0 o superiore).
2.  **Configurazione Android:**
    * Il progetto richiede **minSdkVersion 23** (Android 6.0) a causa delle librerie Firebase.
    * Versione Kotlin: **2.1.0**.
    * Gradle: **8.10.2**.
3.  **Firebase:**
    * Assicurarsi che l'`applicationId` nel file `build.gradle.kts` corrisponda a quello registrato nella Console Firebase (`com.example.tictactoe`).
    * Inserire il file `google-services.json` aggiornato nel percorso `android/app/`.

---

##  Regole Speciali del Gioco

* **La Contestazione:** Se un giocatore resta con 1 carta senza aver attivato la sua **Ultimate**, l'avversario ha una finestra temporale per premere "CONTESTA", obbligando il giocatore a pescare **2 carte extra**.
* **Poteri Wild:** Le carte nere (+4 e Cambio Colore) aprono un selettore interattivo per scegliere il nuovo colore dominante sul tavolo.

---


## Note sullo Sviluppo

Il progetto utilizza le versioni più recenti di:
* **Gradle:** 8.10.2
* **Kotlin:** 2.1.0
* **Android Gradle Plugin:** 8.7.0

---
# Galleria

Si avvisa che gli screenshot sono presi dalla versione desktop

## Homescreen

<img width="682" height="1055" alt="image" src="https://github.com/user-attachments/assets/1379ef9e-ea1e-47fa-b713-98cde5946bda" />

## Hero Selection

<img width="680" height="782" alt="image" src="https://github.com/user-attachments/assets/1529d99d-cbd7-4488-a77b-e7a5b5fa319a" />

## Lobby

<img width="682" height="783" alt="image" src="https://github.com/user-attachments/assets/27953797-76cb-4a26-94bf-6233c2fb7a7c" />

## Turno Player

<img width="685" height="874" alt="image" src="https://github.com/user-attachments/assets/8a141d2e-ad47-4be7-9318-fd848dd95d4a" />

## Turno avversario

<img width="687" height="786" alt="image" src="https://github.com/user-attachments/assets/deca982d-5ef1-4a8a-a624-92ded634929b" />

## Schermata di sconfitta

<img width="822" height="786" alt="image" src="https://github.com/user-attachments/assets/1b65886f-de28-4684-bdfa-4e82cd602c7f" />

##Schermata di vittoria

<img width="334" height="331" alt="image" src="https://github.com/user-attachments/assets/de16f482-bec3-461f-a44e-e364e53f5dfc" />
