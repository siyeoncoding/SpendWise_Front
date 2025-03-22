import mysql.connector

try:
    # MySQL 데이터베이스에 연결
    conn = mysql.connector.connect(
        host="localhost",  # MySQL 서버의 호스트 주소 (예: localhost)
        user="root",  # MySQL 사용자 이름
        password="0113",  # MySQL 비밀번호
        database="spendwise_user"  # 사용할 데이터베이스 이름
    )

    # 연결 성공 시 확인 메시지 출력
    if conn.is_connected():
        print("MySQL Database connection is successful!!")

    # 커서 객체를 만들어 SQL 쿼리를 실행
    cursor = conn.cursor()

    # 예시: usertable 테이블에서 모든 사용자 정보 조회
    cursor.execute("SELECT * FROM usertable")

    # 결과 출력
    for row in cursor.fetchall():
        print(row)

except mysql.connector.Error as err:
    # MySQL 연결 또는 쿼리 실행 중 오류 발생 시 에러 메시지 출력
    print(f"Error: {err}")

finally:
    # 연결이 되어 있으면 종료
    if conn.is_connected():
        cursor.close()
        conn.close()
        print("MySQL connection is closed.")
