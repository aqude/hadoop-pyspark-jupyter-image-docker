```
docker build -t hadoop-pyspark-jupyter-image .
```

```
docker run -it --restart=on-failure -p 8888:8888 -p 50070:50070 -p 8088:8088 -v {PATH_TO_YOUR_REPO_FOR_CLONING_IN_DOCKERIMAGE}:/workspace hadoop-pyspark-jupyter-image
```
Не забывай создать 
```
hadoop fs -mkdir -p /partners
```
Проверить
```
hadoop fs -ls /
```
