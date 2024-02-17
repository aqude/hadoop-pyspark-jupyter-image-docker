FROM ubuntu:20.04

# Установка зависимостей с предварительной настройкой для предотвращения интерактивных запросов
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    ln -fs /usr/share/zoneinfo/Europe/London /etc/localtime && \
    apt-get install -y tzdata && \
    dpkg-reconfigure --frontend noninteractive tzdata

# Продолжение установки остальных зависимостей
RUN apt-get install -y python3-pip openjdk-8-jdk wget nano

# Установка и настройка SSH
RUN apt-get install -y openssh-server && \
    mkdir /var/run/sshd && \
    echo 'root:password' | chpasswd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd && \
    echo "export VISIBLE=now" >> /etc/profile

# Генерация и установка ключей для безпарольного доступа через SSH
RUN ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa && \
    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys && \
    chmod 0600 ~/.ssh/authorized_keys

# Отключение строгой проверки ключей хоста для localhost
RUN echo "Host localhost\n\tStrictHostKeyChecking no\n" >> ~/.ssh/config && \
    echo "Host 127.0.0.1\n\tStrictHostKeyChecking no\n" >> ~/.ssh/config && \
    echo "Host 0.0.0.0\n\tStrictHostKeyChecking no\n" >> ~/.ssh/config && \
    chmod 0600 ~/.ssh/config

# Установка pyspark и jupyter
RUN pip3 install pyspark jupyter

# Установка Hadoop
ENV HADOOP_VERSION=3.3.6
ENV HADOOP_HOME=/usr/local/hadoop
ENV PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin
RUN wget https://dlcdn.apache.org/hadoop/common/hadoop-3.3.6/hadoop-3.3.6.tar.gz && \
    tar -xzvf hadoop-$HADOOP_VERSION.tar.gz && \
    mv hadoop-$HADOOP_VERSION $HADOOP_HOME && \
    rm hadoop-$HADOOP_VERSION.tar.gz

# Настройка окружения для Hadoop и PySpark
ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
RUN echo JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64 >> /etc/environment
ENV PYSPARK_PYTHON=python3
ENV HDFS_NAMENODE_USER=root
ENV HDFS_DATANODE_USER=root
ENV HDFS_SECONDARYNAMENODE_USER=root
ENV YARN_RESOURCEMANAGER_USER=root
ENV YARN_NODEMANAGER_USER=root

# Копирование конфигурационных файлов Hadoop в контейнер
COPY config/* $HADOOP_HOME/etc/hadoop/

# Форматируем namenode (делается один раз)
RUN hdfs namenode -format

# Установка Jupyter Notebook и настройка порта
EXPOSE 8888
RUN jupyter notebook --generate-config && \
    echo "c.NotebookApp.allow_root = True" >> ~/.jupyter/jupyter_notebook_config.py && \
    echo "c.NotebookApp.ip = '0.0.0.0'" >> ~/.jupyter/jupyter_notebook_config.py

# Hadoop, YARN, SSH и Jupyter Notebook
CMD service ssh start && \
    $HADOOP_HOME/sbin/start-dfs.sh && \
    $HADOOP_HOME/sbin/start-yarn.sh && \
    jupyter notebook --allow-root --ip=0.0.0.0 --no-browser --NotebookApp.token='' --NotebookApp.password='' --notebook-dir=/workspace
