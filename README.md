![alt text](assets/obob.png)

## O-Bob

**Bytes on Bites 🍚**

O-Bob은 오늘의 밥상이 궁금한 SeSAC 교육생들을 위한 점심 메뉴 알림 봇입니다. 매주 수-금요일 점심 시간, 디스코드 채널을 통해 실시간으로 구내식당 메뉴를 공유합니다. 교육생들이 구내식당 블로그 피드를 반복적으로 확인해야 하는 불편함을 해소하고자 개발하였습니다.


## Features

- **실시간 알림** -  SeSAC 구내식당 블로그의 RSS 피드를 주기적으로 확인하여 실시간 메뉴 정보를 공유합니다.
- **디스코드 메세지 전송** - 블로그 게시물에서 메뉴 이미지를 추출하여 디스코드 채널에 자동으로 전송합니다.


## Stacks

**Language**

![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)

**IDE**

![Visual Studio Code](https://img.shields.io/badge/Visual%20Studio%20Code-0078d7.svg?style=for-the-badge&logo=visual-studio-code&logoColor=white)

 **Hosting**

 ![Google Cloud](https://img.shields.io/badge/GoogleCloud-%234285F4.svg?style=for-the-badge&logo=google-cloud&logoColor=white)

**Others**

![Discord](https://img.shields.io/badge/Discord-%235865F2.svg?style=for-the-badge&logo=discord&logoColor=white)
![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=for-the-badge&logo=docker&logoColor=white)
![Rss](https://img.shields.io/badge/rss-F88900?style=for-the-badge&logo=rss&logoColor=white)


## How It Works

1. Google Cloud Scheduler가 주중 수-금요일 11:00-12:00 사이 1분 간격으로 봇을 트리거합니다.
2. 활성화된 봇이 SeSAC 구내식당 블로그의 RSS 피드를 확인합니다.
3. 최신 포스트의 날짜가 현재 날짜와 일치하면 이미지를 파싱합니다.
4. 파싱된 이미지는 디스코드 채널에 전송됩니다.
5. 전송 상태는 Google Datastore에 `messageSentTracker`로 저장되어 중복 전송을 방지합니다.


## Changelog

>**게시물 날짜 확인 방식 변경**

| 항목 | 기존 방식 | 개선된 방식 |
|------|-----------|-------------|
| **구현 방식** | 블로그 HTML 문서 파싱 | RSS 피드 XML 문서 파싱|
| **파싱 대상** | 1. title 태그(선택한 방식)<br>2. publishDate 태그 | pubDate 태그 |
| **형식** | • title: "M월d일(ddd) 오늘의밥상 점심"<br>• publishDate:<br> ㅤㅤ- 1시간 이내: "n분 전"<br> ㅤㅤ- 24시간 이내: "n시간 전"<br> ㅤㅤ- 그 외: "yyyy. M. d" | 표준화된 날짜 형식 (RFC 822) |
| **변경 이유** | • title: 작성자 실수 가능성<br>• publishDate: 복잡한 파싱 로직 | • 정확한 날짜 정보 제공<br>• 실시간 알림봇의 목적에 적합 |
| **결과** | 날짜 작성 실수로 메뉴 알림 누락 발생 | 날짜 정보의 정확성과 신뢰성 향상 |
| **스크린샷** | <img src="assets/html.png" alt="기존 방식" width="220"> | <img src="assets/xml.png" alt="개선된 방식" width="220"> |

>**호스팅 및 외부 스케줄러와 DB 도입**

| 항목 | 기존 방식 | 변경된 방식 |
|------|-----------|-------------|
| **호스팅** | • 로컬 개발 환경<br>• 배포를 염두에 두지 않고 개발 | • GCP(Google Cloud Platform) 선택<br>• Cloud Run 사용<br>• 비용 효율적인 서버리스 환경 구축 |
| **데이터 관리** | • Obob 클래스 내부에서 메시지 전송 여부 추적 속성 관리 | • Google Datastore에 데이터 저장<br>• 상태 비저장 문제 해결 |
| **스케줄링** | • Cron 라이브러리 사용<br>• 소스코드 내부에 구현 | • Google Cloud Scheduler 사용<br>• 스케줄러가 독립적으로 작동하여 서비스 트리거 |
