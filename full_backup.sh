#!/bin/sh
YEAR=$(date +%Y)
MONTH=$(date +%m)
DAY=$(date +%d)
HOUR=$(date +%H)
MINUTE=$(date +%M)
SECOND=$(date +%S)
API_BASE_URL={API_BASE_URL}
FULL_BACKUP_API_URL={FULL_BACKUP_API_URL}
BACKUP_TYPE="fullBackup"
HOST_BACKUP_PATH="/home/backUp/$BACKUP_TYPE"
FILE_NAME="full_backup_$YEAR$MONTH$DAY.tar"

echo "$HOST_BACKUP_PATH/$YEAR/$MONTH/$DAY/$FILE_NAME >> Full BackUp Start...\n"

# 호스트 디렉토리 생성
if [ ! -d $HOST_BACKUP_PATH/$YEAR/$MONTH/$DAY ]; then
  # 해당일자에 디렉토리 가 없다면 생성
  mkdir -p $HOST_BACKUP_PATH/$YEAR/$MONTH/$DAY
fi

# 컨테이너 디렉토리 생성
sudo docker exec {데이터베이스 컨테이너 이름} mkdir -p /$BACKUP_TYPE/$YEAR/$MONTH/$DAY

# 풀 백업 덤프 실행
sudo docker exec {데이터베이스 컨테이너 이름} mariabackup --backup --target-dir=/$BACKUP_TYPE/$YEAR/$MONTH/$DAY --user={사용자} --password={비밀번호}

# 풀 백업 덤프 .tar 압축
sudo docker exec {데이터베이스 컨테이너 이름} tar -cvf $FILE_NAME /$BACKUP_TYPE/$YEAR/$MONTH/$DAY/

# 압축된 백업을 호스트 서버로 복사
sudo docker cp {데이터베이스 컨테이너 이름}:/$FILE_NAME /$HOST_BACKUP_PATH/$YEAR/$MONTH/$DAY

# 컨테이너에 남아있는 백업 데이터는 삭제
sudo docker exec {데이터베이스 컨테이너 이름} rm -rf $FILE_NAME

# 호스트 서버의 풀 백업 파일사이즈(바이트 단위) 체크
FILE_SIZE=$(wc -c "$HOST_BACKUP_PATH/$YEAR/$MONTH/$DAY/$FILE_NAME" | awk '{print $1}')

# 풀 백업 덤프 이력저장
curl --location --request POST "$API_BASE_URL$FULL_BACKUP_API_URL" \
  --header "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "file_name=$FILE_NAME" \
  --data-urlencode "path=$HOST_BACKUP_PATH/$YEAR/$MONTH/$DAY/" \
  --data-urlencode "backup_type=$BACKUP_TYPE" \
  --data-urlencode "file_size=$FILE_SIZE"

# 30일 이상 된 폴더 삭제(컨테이너의 압축되지 않은 데이터)
sudo docker exec {데이터베이스 컨테이너 이름} find /$BACKUP_TYPE -mindepth 1 -maxdepth 1 -mtime +30 -type d -exec rm -rf {} \;

echo "\n\n$HOST_BACKUP_PATH/$YEAR/$MONTH/$DAY/$FILE_NAME >> Full BackUp Stop..."