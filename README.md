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

