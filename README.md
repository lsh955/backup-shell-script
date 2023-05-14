## 1. 복원준비
### 1-1. 설명(호스트 기준)
- 준비(복원)를 통해 백업 중에 발생했던 데이터의 업데이트 사항들을 반영하여 데이터의 일관성을 유지.
- 만약 백업 중에 업데이트가 발생했으나 복원 준비를 하지 않은 상태에서 복원을 시도하면, InnoDB 엔진이 이를 발견하고 복원을 거부.

### 1-2. 전체(기본) 백업 복원 준비(호스트 기준)
```shell
$ mariabackup --prepare --target-dir={풀 백업경로}
```

### 1-3. 증분백업 복원 준비(호스트 기준)
```shell
$ mariabackup --prepare --target-dir={풀 백업경로} --incremental-dir={증분 백업경로}
```
```shell
예시...
전체 백업 데이터 복원 준비:
$ mariabackup --prepare --target-dir={풀 백업경로}
전체 백업 데이터 <- 증분1:
$ mariabackup --prepare --target-dir={풀 백업경로} --incremental-dir={증분 백업경로 1번}
전체 백업 데이터 <- 증분2:
$ mariabackup --prepare --target-dir={풀 백업경로} --incremental-dir={증분 백업경로 2번}
전체 백업 데이터 <- 증분3:
$ mariabackup --prepare --target-dir={풀 백업경로} --incremental-dir={증분 백업경로 3번}
...
```

## 2. 복원실행
### 2-1. 복원 조건
- 복원을 위해 MariaDB의 서비스를 잠시 중단.
- DB data 디렉토리(일반적으로 '/var/lib/mysql/')가 비워져 있어야 한다.
- 앞서 준비된 전체 백업 데이터로 복원을 진행.

### 2-2. 컨테이너 형태의 MariaDB 복원
- 복원조건 1번 을 충족시키려면 컨테이너를 정지. ($ docker stop)
- 정지한 컨테이너에서는 Mariabackup 명령어를 내릴 수 없으므로, 원본 컨테이너의 DB 데이터 및 백업 데이터 디렉토리에 접근할 수 있는 또 하나의 DB 컨테이너(이하 Mirror )를 띄운다.
- Mirror에서 Mariabackup 명령어로 복원을 진행.
- 원본 컨테이너를 재시작하면, Mirror와 볼륨을 공유하므로 복원한 데이터가 원본 컨테이너에도 그대로 적용.

### 2-3. 호스트를 이용한 복원명령
```shell
$ mariabackup --copy-back --target-dir={증분백업까지 결합한 최종 풀 백업경로}
```

### 2-4. Docker를 이용한 복원명령
```shell
$ sudo docker exec {데이터베이스 컨테이너 이름} /usr/bin/mariabackup --copy-back --target-dir={증분백업까지 결합한 최종 풀 백업경로}
```