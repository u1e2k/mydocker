# mydocker

run
```bash
docker build . --file Dockerfile --tag my-image-name:$(date +%s)
```
or
```
./run.sh
```

使わないイメージをまとめて消すコマンド
`docker image prune`

本当にすべてを削除して、Docker環境を初期状態に近い状態にしたい場合: 
`docker system prune -a --volumes` （すべての未使用イメージとボリュームを削除）