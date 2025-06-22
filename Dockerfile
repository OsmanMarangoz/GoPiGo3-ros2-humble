# Teil 1: Basis-Image und Argumente
# Verwendung des offiziellen ROS2 Humble Desktop-Images. Es enthält ROS, alle Build-Tools und GUI-Tools wie RViz2.
FROM osrf/ros:humble-desktop

# Argumente für Benutzer-ID und Gruppen-ID, die von docker-compose übergeben werden, um Berechtigungsprobleme zu vermeiden.
ARG USER_ID=1000
ARG GROUP_ID=1000

# Teil 2: System-Abhängigkeiten und Werkzeuge
# Setzt den Frontend-Modus auf nicht-interaktiv, um Pausen während des apt-Builds zu vermeiden.
ENV DEBIAN_FRONTEND=noninteractive

# Installiert grundlegende Entwicklungswerkzeuge, Python-Pakete und die GoPiGo3-Bibliothek in einem einzigen RUN-Befehl, um die Anzahl der Layer zu minimieren.
RUN apt-get update && apt-get install -y \
    git \
    nano \
    python3-pip \
    python3-vcstool \
    i2c-tools \
    && pip install gopigo3 \
    && rm -rf /var/lib/apt/lists/*

# Teil 3: ROS-Abhängigkeiten
# Initialisiert rosdep, um ROS-Paketabhängigkeiten zu verwalten.

# Teil 4: Benutzer-Setup
# Erstellt einen unprivilegierten Benutzer 'rosdev' und fügt ihn zu wichtigen Gruppen hinzu (sudo für Bequemlichkeit, dialout/i2c für Hardware-Zugriff).
RUN addgroup --gid ${GROUP_ID} rosdev && \
    adduser --disabled-password --gecos '' --uid ${USER_ID} --gid ${GROUP_ID} rosdev && \
    usermod -aG sudo rosdev && \
    usermod -aG dialout rosdev && \
    usermod -aG i2c rosdev && \
    echo "rosdev ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

WORKDIR /home/rosdev
# Teil 5: Workspace-Setup und Entrypoint
# Erstellt die grundlegende Workspace-Struktur. Der 'src'-Ordner wird über ein Volume gemountet.
RUN mkdir -p /home/rosdev/ros2_ws/src
RUN chown -R rosdev:rosdev /home/rosdev/ros2_ws

#RUN rosdep init || true && rosdep update
RUN echo "source /opt/ros/humble/setup.bash" >> /home/rosdev/.bashrc && \
    echo "if [ -f /home/rosdev/ros2_ws/install/setup.bash ]; then source /home/rosdev/ros2_ws/install/setup.bash; fi" >> /home/rosdev/.bashrc

# Wechselt zum neuen Benutzer 'rosdev'.
USER rosdev

# Setzt das Arbeitsverzeichnis auf den Workspace für die nachfolgenden Befehle.
WORKDIR /home/rosdev/ros2_ws

RUN bash -c "source /opt/ros/humble/setup.bash && colcon build"

WORKDIR /home/rosdev
# Kopiert das Entrypoint-Skript in den Container und macht es ausführbar.
COPY entrypoint.sh /home/rosdev/entrypoint.sh
RUN sudo chmod +x /home/rosdev/entrypoint.sh

# Setzt das Entrypoint-Skript als Einstiegspunkt für den Container.
ENTRYPOINT ["/home/rosdev/entrypoint.sh"]

# Standardbefehl, der vom Entrypoint ausgeführt wird. Hält den Container am Laufen.
CMD ["tail", "-f", "/dev/null"]