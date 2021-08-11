# gsnet-scripts

GSNet で使えるスクリプト置き場

## ディレクトリ構成

```
.
├── LICENSE                      - ライセンス
├── README.md                    - このファイル
├── gateway-setup                - GSNet Gateway のセットアップ
│   ├── nat                      - ラズパイとかに使う
│   │   ├── setup_gsngw01.sh
│   │   ├── setup_hotate.sh
│   │   └── setup_suzukautako.sh
│   └── nonat                    - VPS とかに使う
│       ├── setup_gsngw01.sh
│       ├── setup_hotate.sh
│       └── setup_suzukautako.sh
└── scangsn.sh                   - GSNet 内の全ホストに ping を打つ
```

## ルール

- 全てのスクリプトはトップレベルに置く
- master に対する push 禁止
  - できちゃうかも
