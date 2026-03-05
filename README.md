# docker_scripts (ROS2 Humble universal build/run helpers)

Questo repository contiene una raccolta di script e un `Dockerfile` pensati per costruire e usare workspaces ROS2 (Humble) in modo "universale": l'immagine copia il contenuto della cartella `src/` dal contesto di build, risolve le dipendenze esclusivamente dai manifest (package.xml / setup.py / requirements.txt) e compila con `colcon` dentro l'immagine.

Principali caratteristiche
- Usa `osrf/ros:humble-desktop` come base.
- Copia `src/` in `/root/ros2_ws/src` al build-time e costruisce la workspace in immagine.
- Risolve le dipendenze con `rosdep` (non ci sono liste hardcoded): il build fallisce se le dipendenze non sono riportate nei manifest (uso di `rosdep check` e `rosdep install`).
- Installa eventuali `requirements.txt` trovati nei pacchetti (pip).
- Aggiunge il repository OSRF (Gazebo/ros_gz) per permettere a `rosdep` di risolvere i pacchetti `ros_gz_*` senza installazioni manuali.
- Prepara `.bashrc` per sourcare automaticamente ROS e la workspace installata, e abilita helper `colcon_cd` e completamento.

Cosa aspettarsi dal `Dockerfile`
- Build fail-fast: se un pacchetto richiama una dipendenza a livello CMake ma non la dichiara in `package.xml` (o se manca il pacchetto apt), `rosdep check` o `rosdep install` falliranno e l'immagine non verrà costruita. Questo aiuta a mantenere i manifest corretti e l'immagine riutilizzabile tra progetti.
- Nessuna dipendenza ROS3rd-party "hardcoded" nel Dockerfile: qualsiasi dipendenza deve essere dichiarata nei manifest dei pacchetti nel `src/`.

Script principali (comportamento atteso)
- `docker_build_image.sh <image-name>`: costruisce l'immagine usando la directory padre come contesto di build; passa `USER_ID`/`GROUP_ID` come build-arg per compatibilità.
- `docker_run_container.sh <image-name> <host-src-path> [container-name]`: esegue il container, monta `host-src-path` su `/root/ros2_ws/src` solo se la cartella host non è vuota (per non sovrascrivere la workspace già buildata in immagine), e apre una shell con `--workdir /root/ros2_ws`.
- `docker_connect.sh <container-name>`: entra in una shell del container in esecuzione.

Linee guida per l'uso
1. Metti i tuoi pacchetti ROS2 (cartelle contenenti `package.xml` o `setup.py`) in `src/` del contesto di build.
2. Assicurati che tutte le dipendenze CMake/Python siano dichiarate:
   - dipendenze di build che sono richieste durante la fase CMake devono essere in `<build_depend>` / `<build_export_depend>`;
   - dipendenze runtime in `<exec_depend>`;
   - dipendenze Python aggiuntive possono essere elencate in `requirements.txt` dentro il pacchetto.
3. Costruisci l'immagine:

```bash
./docker_build_image.sh my_project_image
```

4. Avvia il container (se vuoi montare il codice locale):

```bash
./docker_run_container.sh my_project_image /path/to/my/local/src my_container
```

Note operative e best-practices
- Se il build fallisce per dipendenze mancanti, correggi i `package.xml`/`CMakeLists.txt` del pacchetto che ha dato errore e ricostruisci. Questo è voluto: il sistema mira ad essere riutilizzabile tra progetti senza dover aggiornare il Dockerfile.
- Se usi pacchetti che risiedono in repository non ufficiali, aggiungi le sorgenti necessarie ai manifest o documenta nel pacchetto come installare i loro prerequisiti di sistema. Il `Dockerfile` include il repository OSRF per `ros_gz_*`.
- Per debug rapido: avvia il container senza montare la cartella host (usa l'immagine già buildata) e ispeziona `/root/ros2_ws/log` o ricostruisci con i sorgenti modificati.

Possibili estensioni consigliate
- Aggiungere uno script di validazione locale che verifica la presenza di `package.xml`/`setup.py` in `src/` prima di chiamare `docker build`.
- Se desideri supportare workflow non-root, si può aggiungere il cambio di user al runtime e alla build passando `USER_ID`/`GROUP_ID` (arg presenti ma non obbligatori).

Contatti
Per problemi o suggerimenti sull'approccio "manifest-first", incolla i log di `docker build`/`colcon` e posso aiutare a identificare quali manifest correggere.

---
File correlati: `Dockerfile`, `docker_build_image.sh`, `docker_run_container.sh`, `docker_connect.sh` (nella stessa cartella).
