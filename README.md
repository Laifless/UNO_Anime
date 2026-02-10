# Anime Battle Card UNO
------------------------
Nome: Tavani Samuele
------------------------
Anime Battle Card UNO è un videogioco per mobile che rielabora le classiche meccaniche di UNO integrandole con l'universo degli Anime. Ogni partita non è solo una sfida di carte, ma una battaglia strategica dove i personaggi leggendari possono attivare poteri "Ultimate" per ribaltare le sorti del match.

 - Caratteristiche Principali
Sistema di Classi Dinamico: Utilizzo di enums per gestire tipologie di carte (normal, special, wild) e poteri speciali (skip, drawTwo, wildDrawFour, changeColor).

Ultimate Abilities: Sistema di animazioni personalizzate tramite showDialog che riproducono i gridi di battaglia e le GIF iconiche dei personaggi (es. Gojo's Domain Expansion o Ichigo's Bankai).

Intelligenza Artificiale: Bot integrato con logica decisionale per la selezione delle carte e l'uso dei poteri speciali.

Interfaccia Fluida: Realizzata con widget avanzati di Flutter come AnimatedScale per il feedback visivo e LinearGradient adattivi basati sul tema dell'eroe selezionato.

Selezione Multiverso: Database espanso che include personaggi da Bleach, Jujutsu Kaisen, One Piece, Dragon Ball, JoJo e altri.

 - Architettura Tecnica
Il progetto segue una struttura modulare per garantire manutenibilità:

main.dart: Punto di ingresso dell'applicazione e configurazione del tema scuro (Dark Mode).

home_screen.dart: Gestione del flusso di navigazione e logica di selezione dell'universo e dell'eroe.

game_table_screen.dart: Il cuore del gioco. Gestisce il loop della partita, il mazzo, il turno del giocatore e l'intelligenza artificiale del bot.

models.dart: Definizioni delle strutture dati per le carte e le stanze di gioco.

-  Come Giocare
Scegli il tuo Eroe: Seleziona un universo e un personaggio. Ogni scelta cambierà il colore tematico della tua interfaccia.

Preparati alla Battaglia: Crea una stanza e sfida il bot.

Usa l'Ultimate: Durante il tuo turno, puoi gridare la tua mossa finale per caricare la vittoria (assicurati di farlo prima di finire le carte!).

Vinci il Match: Regole classiche, ma con lo stile dei tuoi anime preferiti.


## Prossime informazioni verranno aggiunte a breve
